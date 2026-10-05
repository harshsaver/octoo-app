import 'dart:math';
import 'dart:typed_data';

import 'noise.dart' show uuidBytes;

/// The relay's transport rules (october-desktop
/// `src/shared/remoteRelayProtocol.ts`, `infra/relay/src/relay-object.ts`).
abstract final class RelayClose {
  static const sessionEnded = 4400;
  static const authenticationFailed = 4401;
  static const revoked = 4403;
  static const hostOffline = 4404;
  static const leaseExpired = 4407;
  static const billingSuspended = 4408;
  static const replaced = 4409;
  static const hostDisconnected = 4410;
  static const frameTooLarge = 4413;
  static const rateLimited = 4429;
}

const relayAck = 0x04;

/// A device may have this much unacknowledged from the relay before the
/// relay drops it (4429).
const deviceUnacknowledgedBytes = 1024 * 1024;

/// The most a device may send in one WebSocket message.
const deviceFrameLimit = 65535;

/// A device's ACK: `[0x04][bytes u32]`, after reading each message.
Uint8List deviceAck(int bytes) {
  final out = Uint8List(5);
  ByteData.sublistView(out)
    ..setUint8(0, relayAck)
    ..setUint32(1, bytes);
  return out;
}

/// Retry delay after [attempt] failures: 1 s doubling to 30 s.
Duration relayRetryDelay(int attempt) =>
    Duration(milliseconds: min(30000, 1000 * (1 << min(attempt, 5))));

// --- The host side (the test Octo) -----------------------------------------

const outerOpen = 1;
const outerClose = 2;
const outerData = 3;
const outerHeaderBytes = 25;

/// `[type][bind 16][connectionId u64][payload]`.
Uint8List encodeOuter(int type, String bind, int connectionId, [List<int> payload = const []]) {
  final out = Uint8List(outerHeaderBytes + payload.length);
  out[0] = type;
  out.setAll(1, uuidBytes(bind));
  ByteData.sublistView(out).setUint64(17, connectionId);
  out.setAll(outerHeaderBytes, payload);
  return out;
}

typedef OuterFrame = ({int type, String bind, int connectionId, Uint8List payload});

OuterFrame? decodeOuter(Uint8List bytes) {
  if (bytes.length < outerHeaderBytes || bytes[0] < outerOpen || bytes[0] > outerData) return null;
  final hex = bytes.sublist(1, 17).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  final bind = '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
  final connectionId = ByteData.sublistView(bytes).getUint64(17);
  if (connectionId == 0) return null;
  return (type: bytes[0], bind: bind, connectionId: connectionId, payload: Uint8List.sublistView(bytes, outerHeaderBytes));
}

/// A host's ACK: `[0x04][connectionId u64][bytes u32]`, where bytes counts
/// the whole outer frame.
Uint8List hostAck(int connectionId, int bytes) {
  final out = Uint8List(13);
  ByteData.sublistView(out)
    ..setUint8(0, relayAck)
    ..setUint64(1, connectionId)
    ..setUint32(9, bytes);
  return out;
}

Uint8List closeReason(int code) => Uint8List.fromList([code >> 8, code & 0xff]);
