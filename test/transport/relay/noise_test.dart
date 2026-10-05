import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/transport/relay/noise.dart';

/// october-desktop src/shared/remoteChannel.vectors.ts (REMOTE_CHANNEL_VECTOR).
const _v = (
  hostId: '01234567-89ab-4def-8123-456789abcdef',
  bind: 'fedcba98-7654-4321-9abc-def012345678',
  connectionId: 0x0102030405060708,
  initiatorStaticSeed: '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20',
  responderStaticSeed: '4142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f60',
  initiatorEphemeralSeed: '8182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0',
  responderEphemeralSeed: 'c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0',
  messages: [
    'cc27c49ae6a3bc6b2ccba388318fbc79ab8e668f6d0ea1dcc76dd4027c90c72b',
    '0a8665a960bb70b15a5ccb90411c80f563553f56721ff5d47c8cf79762dd605c130dd5a6734e665b473fdfc79e1f1eafd20e7f19475a8e8493b2ad0aeb0b3edcfbb3f477714150bd432c9e4de16287dee1a57e3d8ad70bf468615e711cc8e2d0',
    '70c58eb1e7608486a37e7242a5caa666e0629c4ed242b5e90465f480df357f91d086797606dafafcd2d0632e908902a4912addc3d7993ceb4488249bc469c539',
  ],
  handshakeHash:
      '12f17393018735d1d35a2ceb1b453521d259313ba87fa329445cb86add148b4be8131a78d970da5c98b9cdb59d1f4a4f079fbc3539859a01e425d9dddc2fdce5',
  transportPlaintext: '6f63746f626572',
  transportCiphertext: 'b1b5c66508e5e0ef3a205afc462e5b168b296bd225fe5e',
);

Uint8List _hex(String h) => Uint8List.fromList([for (var i = 0; i < h.length; i += 2) int.parse(h.substring(i, i + 2), radix: 16)]);
String _toHex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

Future<(NoiseHandshake, NoiseHandshake)> _pair() async {
  final prologue = channelPrologue(_v.hostId, _v.bind, _v.connectionId);
  final initiator = await NoiseHandshake.start(
    initiator: true,
    staticKey: await NoiseKeyPair.fromSeed(_hex(_v.initiatorStaticSeed)),
    prologue: prologue,
    ephemeral: await NoiseKeyPair.fromSeed(_hex(_v.initiatorEphemeralSeed)),
  );
  final responder = await NoiseHandshake.start(
    initiator: false,
    staticKey: await NoiseKeyPair.fromSeed(_hex(_v.responderStaticSeed)),
    prologue: prologue,
    ephemeral: await NoiseKeyPair.fromSeed(_hex(_v.responderEphemeralSeed)),
  );
  return (initiator, responder);
}

void main() {
  test('prologue: "october-remote/1" ‖ hostId ‖ bind ‖ connectionId BE (56 bytes)', () {
    final p = channelPrologue(_v.hostId, _v.bind, _v.connectionId);
    expect(p.length, 56);
    expect(ascii.decode(p.sublist(0, 16)), 'october-remote/1');
    expect(_toHex(p.sublist(48)), '0102030405060708');
    expect(() => channelPrologue('NOT-A-UUID', _v.bind, 1), throwsA(isA<NoiseException>()));
  });

  test('matches the october-desktop handshake vector byte for byte', () async {
    final (i, r) = await _pair();
    final m1 = await i.writeMessage();
    expect(_toHex(m1), _v.messages[0]);
    await r.readMessage(m1);
    final m2 = await r.writeMessage();
    expect(_toHex(m2), _v.messages[1]);
    await i.readMessage(m2);
    final m3 = await i.writeMessage();
    expect(_toHex(m3), _v.messages[2]);
    await r.readMessage(m3);

    expect(_toHex(i.channel.handshakeHash), _v.handshakeHash);
    expect(_toHex(r.channel.handshakeHash), _v.handshakeHash);
    final ct = await i.channel.send.encrypt(_hex(_v.transportPlaintext));
    expect(_toHex(ct), _v.transportCiphertext);
    expect(_toHex(await r.channel.receive.decrypt(ct)), _v.transportPlaintext);

    // The responder pins the initiator's static key and vice versa.
    final initiatorStatic = await NoiseKeyPair.fromSeed(_hex(_v.initiatorStaticSeed));
    pinnedOrThrow(r.channel.remoteStatic, initiatorStatic.publicKey);
    expect(() => pinnedOrThrow(r.channel.remoteStatic, Uint8List(32)), throwsA(isA<NoiseException>()));
  });

  test('both directions, many messages; tampering and reordering fail closed', () async {
    final (i, r) = await _pair();
    await r.readMessage(await i.writeMessage());
    await i.readMessage(await r.writeMessage());
    await r.readMessage(await i.writeMessage());
    for (var n = 0; n < 5; n++) {
      expect(utf8.decode(await r.channel.receive.decrypt(await i.channel.send.encrypt(utf8.encode('to host $n')))), 'to host $n');
      expect(utf8.decode(await i.channel.receive.decrypt(await r.channel.send.encrypt(utf8.encode('to phone $n')))), 'to phone $n');
    }
    final a = await i.channel.send.encrypt([1, 2, 3]);
    final b = await i.channel.send.encrypt([4, 5, 6]);
    // Reordered: b arrives first.
    await expectLater(r.channel.receive.decrypt(b), throwsA(isA<NoiseException>().having((e) => e.authentication, 'auth', true)));
    // Tampered.
    final tampered = Uint8List.fromList(a)..[0] ^= 1;
    await expectLater(r.channel.receive.decrypt(tampered), throwsA(isA<NoiseException>()));
    // Truncated.
    await expectLater(r.channel.receive.decrypt(a.sublist(0, 10)), throwsA(isA<NoiseException>()));
  });

  test('a wrong prologue (another bind or connection) fails the handshake', () async {
    final initiator = await NoiseHandshake.start(
      initiator: true,
      staticKey: await NoiseKeyPair.generate(),
      prologue: channelPrologue(_v.hostId, _v.bind, 1),
    );
    final responder = await NoiseHandshake.start(
      initiator: false,
      staticKey: await NoiseKeyPair.generate(),
      prologue: channelPrologue(_v.hostId, _v.bind, 2),
    );
    await responder.readMessage(await initiator.writeMessage());
    await expectLater(initiator.readMessage(await responder.writeMessage()), throwsA(isA<NoiseException>()));
  });

  test('fresh ephemerals each time: two handshakes with the same keys differ', () async {
    final s = await NoiseKeyPair.generate();
    final p = channelPrologue(_v.hostId, _v.bind, 7);
    final a = await (await NoiseHandshake.start(initiator: true, staticKey: s, prologue: p)).writeMessage();
    final b = await (await NoiseHandshake.start(initiator: true, staticKey: s, prologue: p)).writeMessage();
    expect(_toHex(a), isNot(_toHex(b)));
  });

  test('pairing code: u32 BE of the handshake hash, mod 10^6, six digits', () {
    expect(pairingCode(_hex('000f424000')), '000000');
    expect(pairingCode(_hex('00003039ff')), '012345');
  });
}
