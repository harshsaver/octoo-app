import 'dart:async';

import 'octo_link.dart';

/// Real mode until `RelayLink` (stage 5): every computer reads as offline and
/// pairing says plainly that this version can't connect yet. Lets sign-in,
/// the backend and claiming run for real without pretending to reach Mom.
class UnavailableLink implements OctoLink {
  @override
  Stream<PairingProgress> pair(
    String qrPayloadOrCode, {
    required String helperName,
    required String deviceLabel,
  }) => Stream.value(
    const PairingFailed(kind: PairingFailureKind.notAvailable, isFinal: true),
  );

  @override
  Stream<LinkState> connect(String computerId) =>
      Stream.value(LinkState.offline);

  @override
  Stream<Map<String, Object?>> messages(String computerId) =>
      const Stream.empty();

  @override
  Future<void> send(String computerId, Map<String, Object?> message) async =>
      throw LinkUnavailableException(computerId);

  @override
  Future<void> unpair(String computerId) async {}
}
