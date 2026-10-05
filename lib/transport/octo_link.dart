/// The transport between this app and a family computer (brief §7.1).
///
/// The rest of the app only sees this interface; `SimulatorLink` and
/// `RelayLink` implement it.
library;

// The brief's signature, kept verbatim.
// dart format off
abstract class OctoLink {
  /// Pairs with a computer from its QR payload or typed code. Emits progress
  /// (scanned → code to compare → waiting for her OK → paired) and finishes with the paired computer.
  Stream<PairingProgress> pair(String qrPayloadOrCode, {required String helperName, required String deviceLabel});
  /// Connects to a paired computer (reconnects with backoff while the app is in the foreground).
  Stream<LinkState> connect(String computerId);
  /// Sends one message to the computer.
  Future<void> send(String computerId, Map<String, Object?> message);
  /// Every message from the computer, in order.
  Stream<Map<String, Object?>> messages(String computerId);
  Future<void> unpair(String computerId);
}
// dart format on

/// The state of a [OctoLink.connect] stream. Cancelling that subscription
/// disconnects.
enum LinkState {
  /// Trying to reach her computer (first attempt or a backoff retry).
  connecting,

  /// Messages flow both ways.
  connected,

  /// Her computer can't be reached; the link keeps retrying.
  offline,
}

/// [OctoLink.send] was called while the link isn't connected. The message
/// was not sent.
class LinkUnavailableException implements Exception {
  const LinkUnavailableException(this.computerId);

  final String computerId;

  @override
  String toString() => 'LinkUnavailableException($computerId)';
}

/// A computer that finished pairing.
class PairedComputer {
  const PairedComputer({
    required this.computerId,
    required this.hostId,
    required this.computerName,
    this.person,
    String? bind,
  }) : bind = bind ?? hostId;

  final String computerId;
  final String hostId;

  /// This phone's pairing with it (the relay binding); outbox entries are
  /// bound to it.
  final String bind;
  final String computerName;
  final String? person;
}

/// Progress of [OctoLink.pair]. Cancelling the stream subscription cancels
/// the handshake.
sealed class PairingProgress {
  const PairingProgress();
}

/// The code was read; [computerName] is the name the QR reports.
final class PairingScanned extends PairingProgress {
  const PairingScanned(this.computerName);

  final String computerName;
}

/// Her screen shows a code. The helper compares them: `confirm(true)` sends
/// `pair.confirm`; `confirm(false)` ends the pairing.
final class PairingCompareCode extends PairingProgress {
  const PairingCompareCode(this.code, this.confirm);

  final String code;
  final Future<void> Function(bool match) confirm;
}

/// Waiting for her to tap OK on her computer.
final class PairingWaitingForHer extends PairingProgress {
  const PairingWaitingForHer();
}

final class PairingPaired extends PairingProgress {
  const PairingPaired(this.computer);

  final PairedComputer computer;
}

enum PairingFailureKind {
  /// Her computer said why, in [PairingFailed.reason].
  reportedByComputer,

  /// The helper said the codes don't match.
  codeMismatch,

  /// Her computer went offline during pairing.
  offline,

  /// No answer in time.
  timedOut,

  /// The QR or typed code isn't one this app can use.
  invalidCode,

  /// This build can't connect to computers yet (real mode before RelayLink).
  notAvailable,
}

/// Pairing ended without pairing. [reason] is her computer's own sentence
/// when [kind] is [PairingFailureKind.reportedByComputer]. When [isFinal] is
/// false, scanning a fresh code can work.
final class PairingFailed extends PairingProgress {
  const PairingFailed({required this.kind, required this.isFinal, this.reason});

  final PairingFailureKind kind;
  final bool isFinal;
  final String? reason;
}
