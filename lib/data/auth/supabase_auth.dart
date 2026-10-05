import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../account_scope.dart';
import 'auth_service.dart';

/// October sign-in through Supabase Auth at `auth.october.dev`, like
/// October Mobile (`october-desktop/mobile/src/october/supabase.ts`).
///
/// Email links and Google return through the app's own scheme
/// ([redirectUrl], e.g. `octo://auth-callback`), which must be on the Supabase
/// redirect allow list. Apple on iOS is native (an ID token and a nonce).
class SupabaseAuth implements AuthService {
  SupabaseAuth({required this.redirectUrl}) {
    _sub = _auth.onAuthStateChange.listen((state) {
      final next = _account(state.session?.user);
      if (next?.userId != _current?.userId) {
        _current = next;
        _changes.add(next);
      }
    });
    _current = _account(_auth.currentUser);
  }

  /// Call once before building the app.
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) => sb.Supabase.initialize(
    url: url,
    publishableKey: anonKey,
    authOptions: const sb.FlutterAuthClientOptions(
      authFlowType: sb.AuthFlowType.pkce,
    ),
  );

  final String redirectUrl;
  sb.GoTrueClient get _auth => sb.Supabase.instance.client.auth;
  Account? _current;
  final _changes = StreamController<Account?>.broadcast();
  late final StreamSubscription<sb.AuthState> _sub;

  @override
  Account? get current => _current;

  @override
  Stream<Account?> get changes => _changes.stream;

  @override
  Future<String?> accessToken() async {
    final session = _auth.currentSession;
    if (session == null) return null;
    if (!session.isExpired) return session.accessToken;
    try {
      return (await _auth.refreshSession()).session?.accessToken;
    } on sb.AuthException {
      return null;
    }
  }

  @override
  Future<void> sendEmailLink(String email) => _guard(
    () => _auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: redirectUrl,
      shouldCreateUser: true,
    ),
  );

  @override
  Future<void> verifyEmailCode(String email, String code) => _guard(
    () => _auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: sb.OtpType.email,
    ),
  );

  @override
  Future<void> signInWithPassword(String email, String password) => _guard(
    () => _auth.signInWithPassword(email: email.trim(), password: password),
  );

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    final started = await _auth.signInWithOAuth(
      sb.OAuthProvider.google,
      redirectTo: redirectUrl,
      authScreenLaunchMode: sb.LaunchMode.externalApplication,
    );
    if (!started) throw const AuthException('', cancelled: true);
  });

  @override
  Future<void> signInWithApple() => _guard(() async {
    if (!Platform.isIOS) {
      // Android: Apple's web flow, back through the app's scheme.
      await _auth.signInWithOAuth(
        sb.OAuthProvider.apple,
        redirectTo: redirectUrl,
        authScreenLaunchMode: sb.LaunchMode.externalApplication,
      );
      return;
    }
    final rawNonce = _nonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.fullName,
        AppleIDAuthorizationScopes.email,
      ],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException("Apple didn't sign you in. Try again.");
    }
    await _auth.signInWithIdToken(
      provider: sb.OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  });

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  @override
  void dispose() {
    unawaited(_sub.cancel());
    unawaited(_changes.close());
  }

  /// Supabase's and Apple's errors become one plain sentence; a closed sheet
  /// becomes a quiet cancel.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AuthException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthException(
        "Apple didn't sign you in. Try again.",
        cancelled: e.code == AuthorizationErrorCode.canceled,
      );
    } on sb.AuthException catch (e) {
      throw AuthException(_message(e));
    } on SocketException {
      throw const AuthException(
        "Couldn't reach October. Check the connection and try again.",
      );
    }
  }

  static String _message(sb.AuthException e) {
    final status = int.tryParse(e.statusCode ?? '');
    if (status == 429) return 'Too many tries. Wait a minute, then try again.';
    if (e.code == 'invalid_credentials') {
      return "That email and password don't match.";
    }
    if (e.code == 'otp_expired') {
      return "That code didn't work. Check the email and try again.";
    }
    return "Couldn't sign in. Try again.";
  }

  static Account? _account(sb.User? user) {
    if (user == null) return null;
    final meta = user.userMetadata ?? const {};
    final full =
        (meta['full_name'] ?? meta['name'] ?? meta['given_name']) as String?;
    final first = full?.trim().split(RegExp(r'\s+')).first;
    final fromEmail = user.email?.split('@').first;
    final name = (first != null && first.isNotEmpty)
        ? first
        : (fromEmail ?? 'You');
    return Account(
      userId: user.id,
      name: name[0].toUpperCase() + name.substring(1),
    );
  }

  static String _nonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
