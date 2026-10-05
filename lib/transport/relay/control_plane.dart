import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:http/http.dart' as http;

import 'encoding.dart';

/// October's mobile control plane: Supabase edge functions under
/// `<auth origin>/functions/v1` (october-desktop `mobile/src/october/supabase.ts`
/// `controlPost`, `src/shared/remoteTicket.ts` for signing).
class ControlPlaneException implements Exception {
  const ControlPlaneException(this.status, this.code, this.message);

  /// HTTP status; 0 when no answer arrived.
  final int status;
  final String? code;
  final String message;

  /// The server answered: retrying the same request won't help.
  bool get answered => status != 0;

  @override
  String toString() => 'ControlPlaneException($status, $code, $message)';
}

/// An Ed25519 key that signs control-plane requests. Stored as its 32-byte
/// seed (libsodium's 64-byte secret key is `seed ‖ public key`).
class SigningKey {
  SigningKey._(this.seed, this.publicKey, this._pair);

  static final _ed25519 = DartEd25519();

  static Future<SigningKey> fromSeed(List<int> seed) async {
    if (seed.length != 32) throw ArgumentError('Ed25519 seed must be 32 bytes');
    final pair = await _ed25519.newKeyPairFromSeed(seed);
    final pub = await pair.extractPublicKey();
    return SigningKey._(Uint8List.fromList(seed), Uint8List.fromList(pub.bytes), pair);
  }

  static Future<SigningKey> generate() => fromSeed(randomBytes(32));

  final Uint8List seed;
  final Uint8List publicKey;
  final SimpleKeyPair _pair;

  Future<Uint8List> sign(List<int> message) async {
    final sig = await _ed25519.sign(message, keyPair: _pair);
    return Uint8List.fromList(sig.bytes);
  }
}

/// The string October signs: `october-mobile/v1\n{op}\n{session}\n{request}\n{sha256(body)}\n{ts}`.
Future<Uint8List> signedRequestMessage(
  String operation,
  List<int> rawBody,
  String sessionId,
  String requestId,
  int timestampSeconds,
) async {
  if (!RegExp(r'^[a-z][a-z0-9-]{0,63}$').hasMatch(operation)) {
    throw ArgumentError('invalid signed request operation');
  }
  if (!isCanonicalUuid(sessionId) || !isCanonicalUuid(requestId)) {
    throw ArgumentError('sessionId and requestId must be canonical UUIDs');
  }
  final digest = await const DartSha256().hash(rawBody);
  return Uint8List.fromList(
    utf8.encode(
      'october-mobile/v1\n$operation\n$sessionId\n$requestId\n'
      '${b64url(digest.bytes)}\n$timestampSeconds',
    ),
  );
}

/// Headers for a signed request.
Future<Map<String, String>> signRequest(
  String operation,
  List<int> rawBody,
  String sessionId,
  SigningKey key, {
  required DateTime now,
  String? requestId,
}) async {
  final id = requestId ?? uuidV4();
  final ts = now.millisecondsSinceEpoch ~/ 1000;
  final message = await signedRequestMessage(operation, rawBody, sessionId, id, ts);
  return {
    'x-october-request-id': id,
    'x-october-request-ts': '$ts',
    'x-october-signature': b64url(await key.sign(message)),
  };
}

class ControlPlane {
  ControlPlane({
    required this.authOrigin,
    required this.accessToken,
    http.Client? client,
    this.apiKey,
    this.timeout = const Duration(seconds: 15),
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  /// `https://auth.october.dev`.
  final Uri authOrigin;

  /// The signed-in person's access token (a Supabase JWT).
  final Future<String?> Function() accessToken;

  /// The project's public key; only PostgREST reads need it.
  final String? apiKey;
  final Duration timeout;
  final http.Client _client;
  final DateTime Function() _now;

  Future<String> _token() async {
    final token = await accessToken();
    if (token == null || token.isEmpty) {
      throw const ControlPlaneException(401, 'SESSION_REQUIRED', 'Sign in to October first.');
    }
    return token;
  }

  /// The signed-in person's id (`sub`) and session id (`session_id`).
  Future<({String userId, String sessionId})> session() async {
    final claims = jwtClaims(await _token());
    final sub = claims['sub'];
    final sid = claims['session_id'];
    if (sub is! String || sid is! String) {
      throw const ControlPlaneException(401, 'SESSION_REQUIRED', 'The October session is incomplete.');
    }
    return (userId: sub, sessionId: sid);
  }

  /// POSTs JSON to a function. With [signer], the request is signed for
  /// [operation].
  Future<Map<String, Object?>> post(
    String function,
    Map<String, Object?> body, {
    SigningKey? signer,
    String? operation,
  }) async {
    final token = await _token();
    final raw = utf8.encode(jsonEncode(body));
    final headers = {
      'authorization': 'Bearer $token',
      'content-type': 'application/json',
    };
    if (signer != null) {
      final sessionId = jwtClaims(token)['session_id'];
      if (sessionId is! String) {
        throw const ControlPlaneException(401, 'SESSION_REQUIRED', 'The October session is incomplete.');
      }
      headers.addAll(await signRequest(operation!, raw, sessionId, signer, now: _now()));
    }
    final uri = authOrigin.replace(path: '/functions/v1/$function');
    final http.Response response;
    try {
      response = await _client.post(uri, headers: headers, body: raw).timeout(timeout);
    } on TimeoutException {
      throw ControlPlaneException(0, null, '$function timed out');
    } on Exception catch (e) {
      throw ControlPlaneException(0, null, '$function failed: $e');
    }
    Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      json = null;
    }
    final map = json is Map<String, Object?> ? json : const <String, Object?>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = map['error'];
      throw ControlPlaneException(
        response.statusCode,
        map['code'] is String ? map['code']! as String : null,
        error is String ? error : (map['message'] is String ? map['message']! as String : '$function failed (${response.statusCode})'),
      );
    }
    return map;
  }

  /// A PostgREST read as the signed-in person (row-level security applies).
  Future<List<Map<String, Object?>>> select(String table, Map<String, String> query) async {
    final token = await _token();
    final uri = authOrigin.replace(path: '/rest/v1/$table', queryParameters: query);
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'authorization': 'Bearer $token', 'apikey': ?apiKey})
          .timeout(timeout);
    } on TimeoutException {
      throw ControlPlaneException(0, null, '$table read timed out');
    }
    if (response.statusCode != 200) {
      throw ControlPlaneException(response.statusCode, null, '$table read failed (${response.statusCode})');
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    return [for (final row in json as List<Object?>) row! as Map<String, Object?>];
  }

  void close() => _client.close();
}
