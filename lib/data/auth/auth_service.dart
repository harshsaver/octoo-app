import 'dart:async';

import '../account_scope.dart';

/// Signing in with October (brief §5.1): email link, Google, Apple. The rest
/// of the app sees only the signed-in [Account] and a fresh access token.
abstract class AuthService {
  /// The signed-in account now, or null.
  Account? get current;

  /// Every change of account (sign-in, sign-out, a switch).
  Stream<Account?> get changes;

  /// A valid access token for October APIs (refreshed if needed), or null
  /// when signed out.
  Future<String?> accessToken();

  /// Emails a sign-in link (and, if October's email template includes it, a
  /// 6-digit code).
  Future<void> sendEmailLink(String email);

  /// Signs in with the 6-digit code from that email.
  Future<void> verifyEmailCode(String email, String code);

  /// Email and password (October accounts can have one; needs no redirect).
  Future<void> signInWithPassword(String email, String password);

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> signOut();

  void dispose();
}

/// Why signing in didn't work, in a sentence that can be shown.
class AuthException implements Exception {
  const AuthException(this.message, {this.cancelled = false});

  final String message;

  /// The person closed the sign-in sheet: say nothing.
  final bool cancelled;

  @override
  String toString() => 'AuthException';
}

/// Fake mode and tests: one local account, signed in from the start unless
/// told otherwise. Any email and the code `123456` sign in.
class FakeAuth implements AuthService {
  FakeAuth({bool signedIn = true, this.account = Account.fake})
    : _current = signedIn ? account : null;

  final Account account;
  Account? _current;
  final _changes = StreamController<Account?>.broadcast();
  final sentLinks = <String>[];

  @override
  Account? get current => _current;

  @override
  Stream<Account?> get changes => _changes.stream;

  @override
  Future<String?> accessToken() async => _current == null ? null : 'fake-token';

  @override
  Future<void> sendEmailLink(String email) async {
    if (!email.contains('@')) {
      throw const AuthException('Check the email address.');
    }
    sentLinks.add(email);
  }

  @override
  Future<void> verifyEmailCode(String email, String code) async {
    if (code != '123456') {
      throw const AuthException(
        "That code didn't work. Check the email and try again.",
      );
    }
    _set(account);
  }

  /// Any email with the password `octo-test` signs in.
  @override
  Future<void> signInWithPassword(String email, String password) async {
    if (password != 'octo-test') {
      throw const AuthException("That email and password don't match.");
    }
    _set(account);
  }

  @override
  Future<void> signInWithGoogle() async => _set(account);

  @override
  Future<void> signInWithApple() async => _set(account);

  @override
  Future<void> signOut() async => _set(null);

  void _set(Account? value) {
    _current = value;
    if (!_changes.isClosed) _changes.add(value);
  }

  @override
  void dispose() => _changes.close();
}
