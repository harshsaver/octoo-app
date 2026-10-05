/// Turning a scanned or typed code into something to claim and pair with
/// (PLAN §3.8, docs/OCTO_BACKEND.md in saturday).
///
/// The claim secret lives only in memory: never logged, never stored.
library;

import '../../transport/relay/relay_link.dart' show parsePairingLink;
import '../backend/octo_backend.dart';

enum EnrollmentMode {
  /// Claims the computer on the backend, then pairs.
  owner,

  /// Skips the claim; her OK on the relay pairing adds them (contract
  /// question 1: how a helper's QR differs is still open).
  helper,

  /// October Desktop's own pairing code (`https://october.dev/pair#…`): a
  /// computer on the same October account, paired over the relay with no
  /// Octo backend record. How the test Octo pairs.
  direct,
}

/// A resolved code. [pairPayload] is what `OctoLink.pair` receives.
class Enrollment {
  const Enrollment({
    required this.mode,
    this.credentials,
    required this.pairPayload,
    this.computerName,
  });

  final EnrollmentMode mode;

  /// What to claim with; null for [EnrollmentMode.direct].
  final ClaimCredentials? credentials;
  final String pairPayload;
  final String? computerName;

  @override
  String toString() => 'Enrollment(${mode.name}, $credentials)';
}

enum EnrollmentFailure { notAnOctoCode }

class EnrollmentException implements Exception {
  const EnrollmentException(this.failure);

  final EnrollmentFailure failure;

  @override
  String toString() => 'EnrollmentException(${failure.name})';
}

abstract class EnrollmentRepository {
  /// Resolves a QR payload, universal link or typed code.
  Future<Enrollment> resolve(String payloadOrCode);
}

/// The enrollment link: `https://www.october.dev/octo/add#<enrollId>.<claimSecret>`
/// (or `october.dev`), with the backend's formats: `en_` + 24 hex, and a
/// 43-character base64url secret. Null for anything else.
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
  final match = RegExp(r'^(en_[0-9a-f]{24})\.([A-Za-z0-9_-]{43})$')
      .firstMatch(uri.fragment);
  if (match == null) return null;
  return (enrollId: match.group(1)!, secret: match.group(2)!);
}

/// A typed code as the backend stores it: Crockford base32, 8 characters,
/// forgiving about case, spaces, dashes and look-alikes (O→0, I/L→1).
String? normaliseTypedCode(String value) {
  final code = value
      .toUpperCase()
      .replaceAll(RegExp(r'[\s-]'), '')
      .replaceAll('O', '0')
      .replaceAll(RegExp('[IL]'), '1');
  return RegExp(r'^[0-9A-HJKMNP-TV-Z]{8}$').hasMatch(code) ? code : null;
}

/// Real mode: everything needed is in the code itself; the backend checks it
/// when claiming.
class LinkEnrollment implements EnrollmentRepository {
  @override
  Future<Enrollment> resolve(String payloadOrCode) async {
    final value = payloadOrCode.trim();
    if (parsePairingLink(value) != null) {
      return Enrollment(mode: EnrollmentMode.direct, pairPayload: value);
    }
    final link = parseEnrollmentLink(value);
    if (link != null) {
      return Enrollment(
        mode: EnrollmentMode.owner,
        credentials: ClaimByQr(
          enrollId: link.enrollId,
          claimSecret: link.secret,
        ),
        pairPayload: value,
      );
    }
    final code = normaliseTypedCode(value);
    if (code != null) {
      return Enrollment(
        mode: EnrollmentMode.owner,
        credentials: ClaimByCode(code),
        pairPayload: code,
      );
    }
    throw const EnrollmentException(EnrollmentFailure.notAnOctoCode);
  }
}

/// Fake mode: as [LinkEnrollment], plus `octo-sim:` payloads from the
/// developer button; typed codes starting with "H" resolve as a helper, so
/// both paths can be tried.
class FakeEnrollment implements EnrollmentRepository {
  final _real = LinkEnrollment();

  @override
  Future<Enrollment> resolve(String payloadOrCode) async {
    final value = payloadOrCode.trim();
    if (value.startsWith('octo-sim:')) {
      return Enrollment(
        mode: EnrollmentMode.owner,
        credentials: const ClaimByCode('S1MULATE'),
        pairPayload: value,
      );
    }
    final enrollment = await _real.resolve(value);
    if (enrollment.credentials case ClaimByCode(:final code)
        when code.startsWith('H')) {
      return Enrollment(
        mode: EnrollmentMode.helper,
        credentials: enrollment.credentials,
        pairPayload: code,
      );
    }
    return enrollment;
  }
}
