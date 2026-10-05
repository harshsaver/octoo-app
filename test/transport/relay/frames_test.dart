import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/transport/relay/frames.dart';

void main() {
  final now = DateTime(2026, 10, 5);

  test('a small message is one chunk with the October header', () {
    final chunks = encodeFrames(FrameKind.req, [1, 2, 3], 7);
    expect(chunks, hasLength(1));
    expect(chunks.single.sublist(0, 16), [1, 2, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1, 0, 0, 0, 3]);
    final out = FrameAssembler().push(chunks.single, now)!;
    expect(out.kind, FrameKind.req);
    expect(out.messageId, 7);
    expect(out.data, [1, 2, 3]);
  });

  test('a large message (a screenshot) splits into full chunks and reassembles', () {
    final data = Uint8List.fromList(List.generate(200000, (i) => i % 251));
    final chunks = encodeFrames(FrameKind.ev, data, 0);
    expect(chunks.map((c) => c.length), [65519, 65519, 65519, 16 + 200000 - 3 * 65503]);
    final assembler = FrameAssembler();
    AssembledFrame? done;
    for (final c in chunks) {
      done = assembler.push(c, now);
    }
    expect(done!.data, data);
  });

  test('empty bodies (ping, pong) are one empty chunk', () {
    final chunk = encodeFrames(FrameKind.ping, const [], 9).single;
    expect(chunk.length, 16);
    expect(FrameAssembler().push(chunk, now)!.kind, FrameKind.ping);
    expect(() => encodeFrames(FrameKind.ping, [1], 9), throwsA(isA<FrameViolation>()));
  });

  test('violations: out of order, bad version, unknown kind, over the ceiling, timeouts', () {
    final data = Uint8List(70000);
    final chunks = encodeFrames(FrameKind.req, data, 1);
    expect(() => FrameAssembler().push(chunks[1], now), throwsA(isA<FrameViolation>()));
    final bad = Uint8List.fromList(chunks[0])..[0] = 2;
    expect(() => FrameAssembler().push(bad, now), throwsA(isA<FrameViolation>()));
    final unknown = Uint8List.fromList(encodeFrames(FrameKind.req, [1], 1).single)..[1] = 99;
    expect(() => FrameAssembler().push(unknown, now), throwsA(isA<FrameViolation>()));
    expect(() => encodeFrames(FrameKind.auth, Uint8List(2000), 1), throwsA(isA<FrameViolation>()));
    final a = FrameAssembler()..push(chunks[0], now);
    expect(() => a.expire(now.add(const Duration(seconds: 11))), throwsA(isA<FrameViolation>()));
  });

  test('message ids count from 1', () {
    final ids = MessageIds();
    expect(ids.take(), 1);
    expect(ids.take(), 2);
  });

  test('responses carry status and server time', () {
    final r = decodeResponse(encodeResponse(200, 1790000000000, [9]));
    expect(r.status, 200);
    expect(r.serverTimeMs, 1790000000000);
    expect(r.body, [9]);
  });
}
