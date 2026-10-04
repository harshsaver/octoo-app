/// Turning a scanned or typed code into something to pair with (PLAN §3.8).
///
/// The enrollment secret lives only in memory: never logged, never stored.
library;

enum EnrollmentMode {
  /// Claims the computer on the backend, then pairs.
  owner,

  /// Skips the claim; her OK on the relay pairing adds them.
  helper,
}

/// A resolved code. [pairPayload] is what `OctoLink.pair` receives.
class Enrollment {
  const Enrollment({
    required this.mode,
    required this.enrollId,
    required this.secret,
    required this.pairPayload,
    this.computerName,
  });

  final EnrollmentMode mode;
  final String enrollId;
  final String secret;
  final String pairPayload;
  final String? computerName;

  @override
  String toString() => 'Enrollment(${mode.name}, $enrollId)';
}

enum EnrollmentFailure { notAnOctoCode, expired, offline }

class EnrollmentException implements Exception {
  const EnrollmentException(this.failure);

  final EnrollmentFailure failure;

  @override
  String toString() => 'EnrollmentException(${failure.name})';
}

abstract class EnrollmentRepository {
  /// Resolves a QR payload, universal link or 8-character code.
  Future<Enrollment> resolve(String payloadOrCode);
}

/// The enrollment link: `https://www.october.dev/octo/add#<enrollId>.<secret>`
/// (or `october.dev`). Returns null for anything else.
({String enrollId, String secret})? parseEnrollmentLink(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https') return null;
  if (uri.host != 'www.october.dev' && uri.host != 'october.dev') return null;
  if (uri.path != '/octo/add' ||
      uri.hasQuery ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort) {
    return null;
  }
  final match = RegExp(r'^([A-Za-z0-9_-]{1,128})\.([A-Za-z0-9_-]{8,256})$')
      .firstMatch(uri.fragment);
  if (match == null) return null;
  return (enrollId: match.group(1)!, secret: match.group(2)!);
}

/// A typed code: 8 letters or digits, spaces and dashes ignored.
String? normaliseTypedCode(String value) {
  final code = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  return RegExp(r'^[A-Z0-9]{8}$').hasMatch(code) ? code : null;
}

/// Fake mode: links and typed codes resolve as an owner (codes containing
/// "H" as the first character resolve as a helper, so both paths can be
/// tried). `octo-sim:` payloads from the developer button pass through.
class FakeEnrollment implements EnrollmentRepository {
  @override
  Future<Enrollment> resolve(String payloadOrCode) async {
    final value = payloadOrCode.trim();
    if (value.startsWith('octo-sim:')) {
      return Enrollment(
        mode: EnrollmentMode.owner,
        enrollId: 'sim',
        secret: 'sim',
        pairPayload: value,
      );
    }
    final link = parseEnrollmentLink(value);
    if (link != null) {
      return Enrollment(
        mode: EnrollmentMode.owner,
        enrollId: link.enrollId,
        secret: link.secret,
        pairPayload: value,
      );
    }
    final code = normaliseTypedCode(value);
    if (code != null) {
      return Enrollment(
        mode: code.startsWith('H')
            ? EnrollmentMode.helper
            : EnrollmentMode.owner,
        enrollId: code,
        secret: code,
        pairPayload: code,
      );
    }
    throw const EnrollmentException(EnrollmentFailure.notAnOctoCode);
  }
}
