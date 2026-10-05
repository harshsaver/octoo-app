import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Base64url without padding, as October writes keys and signatures.
String b64url(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

Uint8List b64urlDecode(String value) {
  final padded = value.padRight((value.length + 3) ~/ 4 * 4, '=');
  return base64Url.decode(padded);
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// A lowercase UUID with version 1–5, as October's functions require.
bool isCanonicalUuid(Object? value) =>
    value is String && _uuidPattern.hasMatch(value);

final _secure = Random.secure();

Uint8List randomBytes(int length) =>
    Uint8List.fromList(List.generate(length, (_) => _secure.nextInt(256)));

/// A random version-4 UUID.
String uuidV4() {
  final b = randomBytes(16);
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// The unverified claims of a JWT (the server verifies it; this only reads
/// `sub` and `session_id`).
Map<String, Object?> jwtClaims(String token) {
  final parts = token.split('.');
  if (parts.length != 3) throw const FormatException('not a JWT');
  final json = jsonDecode(utf8.decode(b64urlDecode(parts[1])));
  if (json is! Map<String, Object?>) throw const FormatException('JWT claims');
  return json;
}
