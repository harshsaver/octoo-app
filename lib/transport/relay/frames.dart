import 'dart:convert';
import 'dart:typed_data';

/// The plaintext framing inside each Noise message, as october-desktop
/// `src/shared/remoteFrames.ts`: a 16-byte big-endian header
/// `[version=1][kind][flags=0 u16][messageId u32][sequence u16][totalChunks u16][totalBytes u32]`
/// followed by up to 65,503 bytes, so a chunk plus the 16-byte tag fits a
/// 65,535-byte Noise message.
///
/// Family messages ride `req` (phone → computer) and `ev` (computer →
/// phone). Their ceilings are higher than October Desktop's 1 MiB because a
/// screenshot may be 8 MB of base64 (docs/relay-protocol.md).
enum FrameKind {
  auth(1, 1024),
  req(2, 9 * 1024 * 1024),
  res(3, 4 * 1024 * 1024 + 10),
  sub(4, 4096),
  unsub(5, 4096),
  ev(6, 9 * 1024 * 1024),
  pairOffer(7, 4096),
  pairCredential(8, 4096),
  pairAck(9, 4096),
  pairActive(10, 4096),
  ping(11, 0),
  pong(12, 0),
  cancel(13, 4);

  const FrameKind(this.value, this.ceiling);

  final int value;
  final int ceiling;

  static FrameKind? fromValue(int v) {
    for (final k in values) {
      if (k.value == v) return k;
    }
    return null;
  }
}

const frameHeaderBytes = 16;
const frameMaxChunkData = 65503;
const frameMaxInFlight = 16;
const frameMaxBuffered = 16 * 1024 * 1024;
const frameAssemblyTimeout = Duration(seconds: 10);

class FrameViolation implements Exception {
  const FrameViolation(this.message);

  final String message;

  @override
  String toString() => 'FrameViolation($message)';
}

class AssembledFrame {
  const AssembledFrame(this.kind, this.messageId, this.data);

  final FrameKind kind;
  final int messageId;
  final Uint8List data;

  String get text => utf8.decode(data);
}

int _chunkCount(int totalBytes) => totalBytes == 0 ? 1 : (totalBytes + frameMaxChunkData - 1) ~/ frameMaxChunkData;

/// One message as chunks, each to be encrypted separately.
List<Uint8List> encodeFrames(FrameKind kind, List<int> data, int messageId) {
  if (data.length > kind.ceiling) throw const FrameViolation('frame exceeds its kind ceiling');
  if (messageId < 0 || messageId > 0xffffffff) throw const FrameViolation('messageId must be u32');
  final total = _chunkCount(data.length);
  if (total > 0xffff) throw const FrameViolation('too many chunks');
  return [
    for (var seq = 0; seq < total; seq++)
      () {
        final start = seq * frameMaxChunkData;
        final end = (start + frameMaxChunkData).clamp(0, data.length);
        final body = data.sublist(start, end);
        final frame = Uint8List(frameHeaderBytes + body.length);
        ByteData.sublistView(frame)
          ..setUint8(0, 1)
          ..setUint8(1, kind.value)
          ..setUint16(2, 0)
          ..setUint32(4, messageId)
          ..setUint16(8, seq)
          ..setUint16(10, total)
          ..setUint32(12, data.length);
        frame.setAll(frameHeaderBytes, body);
        return frame;
      }(),
  ];
}

class _Assembly {
  _Assembly(this.kind, this.total, this.bytes, this.startedAt);

  final FrameKind kind;
  final int total;
  final int bytes;
  final DateTime startedAt;
  final chunks = BytesBuilder(copy: false);
  int next = 0;
}

/// Reassembles chunks. Any violation throws [FrameViolation] and resets;
/// the connection should then be closed.
class FrameAssembler {
  final Map<int, _Assembly> _open = {};
  int _buffered = 0;

  Never _fail(String message) {
    _open.clear();
    _buffered = 0;
    throw FrameViolation(message);
  }

  AssembledFrame? push(Uint8List chunk, DateTime now) {
    if (chunk.length < frameHeaderBytes || chunk.length > frameHeaderBytes + frameMaxChunkData) {
      _fail('invalid frame length');
    }
    final view = ByteData.sublistView(chunk);
    if (view.getUint8(0) != 1) _fail('unsupported frame version');
    final kind = FrameKind.fromValue(view.getUint8(1)) ?? _fail('unknown frame kind');
    if (view.getUint16(2) != 0) _fail('frame flags must be zero');
    final messageId = view.getUint32(4);
    final seq = view.getUint16(8);
    final total = view.getUint16(10);
    final bytes = view.getUint32(12);
    final data = Uint8List.sublistView(chunk, frameHeaderBytes);
    if (total == 0 || total != _chunkCount(bytes)) _fail('invalid chunk count');
    final expected = seq < total - 1 ? frameMaxChunkData : bytes - frameMaxChunkData * (total - 1);
    if (seq >= total || data.length != expected) _fail('invalid chunk size');

    var a = _open[messageId];
    if (a == null) {
      if (seq != 0) _fail('sequence must start at zero');
      if (bytes > kind.ceiling) _fail('frame exceeds its kind ceiling');
      if (_open.length >= frameMaxInFlight) _fail('too many messages in flight');
      a = _open[messageId] = _Assembly(kind, total, bytes, now);
    } else if (a.kind != kind || a.total != total || a.bytes != bytes) {
      _fail('frame metadata changed during assembly');
    }
    if (seq != a.next) _fail('chunks out of order');
    if (_buffered + data.length > frameMaxBuffered) _fail('frame buffer limit exceeded');
    a.chunks.add(Uint8List.fromList(data));
    a.next++;
    _buffered += data.length;
    if (a.next != a.total) return null;
    _open.remove(messageId);
    _buffered -= a.bytes;
    final body = a.chunks.takeBytes();
    if (body.length != a.bytes) _fail('inconsistent body length');
    return AssembledFrame(a.kind, messageId, body);
  }

  /// Throws if any message has been assembling too long.
  void expire(DateTime now) {
    for (final a in _open.values) {
      if (now.difference(a.startedAt) >= frameAssemblyTimeout) _fail('frame assembly timed out');
    }
  }
}

/// Message ids count from 1 and wrap back to 1.
class MessageIds {
  int _next = 1;

  int take() {
    final id = _next;
    _next = _next == 0xffffffff ? 1 : _next + 1;
    return id;
  }
}

/// A `res` body: `[status u16][serverTimeMs u64][body]`.
Uint8List encodeResponse(int status, int serverTimeMs, List<int> body) {
  final out = Uint8List(10 + body.length);
  ByteData.sublistView(out)
    ..setUint16(0, status)
    ..setUint64(2, serverTimeMs);
  out.setAll(10, body);
  return out;
}

({int status, int serverTimeMs, Uint8List body}) decodeResponse(Uint8List data) {
  if (data.length < 10) throw const FrameViolation('response too short');
  final view = ByteData.sublistView(data);
  return (status: view.getUint16(0), serverTimeMs: view.getUint64(2), body: Uint8List.sublistView(data, 10));
}
