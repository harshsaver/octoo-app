import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/app/config.dart';
import 'package:octo_family/data/backend/octo_backend.dart';
import 'package:octo_family/data/backend/relay_aware_backend.dart';
import 'package:octo_family/data/db/database.dart';
import 'package:octo_family/data/enrollment/enrollment_repository.dart';
import 'package:octo_family/transport/relay/control_plane.dart';
import 'package:octo_family/transport/relay/encoding.dart';
import 'package:octo_family/transport/relay/relay_link.dart';
import 'package:octo_family/transport/relay/relay_protocol.dart';

String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

List<int> _unhex(String s) => [for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)];

String _pairLink(Map<String, Object?> payload) => 'https://october.dev/pair#${b64url(utf8.encode(jsonEncode(payload)))}';

void main() {
  test('Ed25519 from a 32-byte seed matches RFC 8032 (what libsodium signs with)', () async {
    final key = await SigningKey.fromSeed(_unhex('9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60'));
    expect(_hex(key.publicKey), 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a');
    expect(
      _hex(await key.sign(const [])),
      'e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b',
    );
  });

  test('the signed message is the one October verifies', () async {
    final message = await signedRequestMessage(
      'ticket-device',
      utf8.encode('{}'),
      '11111111-1111-4111-8111-111111111111',
      '22222222-2222-4222-8222-222222222222',
      1790000000,
    );
    // sha256("{}") = 44136fa3…
    expect(
      utf8.decode(message),
      'october-mobile/v1\nticket-device\n11111111-1111-4111-8111-111111111111\n'
      '22222222-2222-4222-8222-222222222222\nRBNvo1WzZ4oRRq0W9-hknpT7T8If536DEMBg9hyq_4o\n1790000000',
    );
    expect(isCanonicalUuid(uuidV4()), isTrue);
  });

  test('signed requests: the timestamp is whole seconds of now, the signature verifies, bad ids are refused', () async {
    final key = await SigningKey.fromSeed(List.filled(32, 7));
    const session = '11111111-1111-4111-8111-111111111111';
    final now = DateTime.fromMillisecondsSinceEpoch(1790000000999);
    final body = utf8.encode('{"role":"device"}');
    final headers = await signRequest('ticket-device', body, session, key, now: now);
    expect(headers['x-october-request-ts'], '1790000000');
    expect(isCanonicalUuid(headers['x-october-request-id']), isTrue);
    final message = await signedRequestMessage(
      'ticket-device',
      body,
      session,
      headers['x-october-request-id']!,
      1790000000,
    );
    final ok = await DartEd25519().verify(
      message,
      signature: Signature(
        b64urlDecode(headers['x-october-signature']!),
        publicKey: SimplePublicKey(key.publicKey, type: KeyPairType.ed25519),
      ),
    );
    expect(ok, isTrue);
    // One changed byte of the body breaks it.
    final other = await signedRequestMessage('ticket-device', utf8.encode('{"role":"host"}'), session, headers['x-october-request-id']!, 1790000000);
    expect(_hex(other), isNot(_hex(message)));
    await expectLater(signedRequestMessage('Ticket', body, session, uuidV4(), 1), throwsArgumentError);
    await expectLater(signedRequestMessage('ticket-device', body, 'NOT-A-UUID', uuidV4(), 1), throwsArgumentError);
  });

  test('pairing links: valid, expired-but-well-formed, and broken', () {
    final good = {
      'v': 2,
      'hostId': uuidV4(),
      'hostStatic': b64url(List.filled(32, 7)),
      'intentId': uuidV4(),
      'secret': 's' * 43,
      'exp': 1790000000000,
    };
    expect(parsePairingLink(_pairLink(good))?.intentId, good['intentId']);
    expect(parsePairingLink(_pairLink({...good, 'v': 1})), isNull);
    expect(parsePairingLink(_pairLink({...good, 'hostId': 'h_1'})), isNull);
    expect(parsePairingLink('https://www.october.dev/pair#x'), isNull);
    expect(relayComputerId('aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'), 'rly_aaaaaaaabbbb4ccc8dddeeeeeeeeeeee');
  });

  test('an October pairing QR enrolls directly, with nothing to claim', () async {
    final link = _pairLink({
      'v': 2,
      'hostId': uuidV4(),
      'hostStatic': b64url(List.filled(32, 7)),
      'intentId': uuidV4(),
      'secret': 's' * 43,
      'exp': 1790000000000,
    });
    final e = await LinkEnrollment().resolve(link);
    expect(e.mode, EnrollmentMode.direct);
    expect(e.credentials, isNull);
    expect(e.pairPayload, link);
  });

  test('relay frames: device and host ACKs, outer frames, retry delays', () {
    expect(deviceAck(65535), [4, 0, 0, 255, 255]);
    final bind = uuidV4();
    final outer = encodeOuter(outerData, bind, 9, [1, 2]);
    final back = decodeOuter(outer)!;
    expect((back.type, back.bind, back.connectionId), (outerData, bind, 9));
    expect(back.payload, [1, 2]);
    expect(hostAck(9, 27).length, 13);
    expect([for (var i = 0; i < 7; i++) relayRetryDelay(i).inSeconds], [1, 2, 4, 8, 16, 30, 30]);
  });

  test('config: the relay defaults to October and must be https', () {
    final base = {'OCTO_MODE': 'fake'};
    expect((parseConfig(base, isRelease: false) as ConfigOk).config.relayUrl, 'https://relay.afteroctober.xyz');
    expect(
      parseConfig({...base, 'OCTO_RELAY_URL': 'http://x'}, isRelease: false),
      isA<ConfigProblem>(),
    );
  });

  group('RelayAwareBackend', () {
    late OctoDatabase db;
    late RelayAwareBackend backend;
    final id = relayComputerId(uuidV4());

    setUp(() async {
      db = OctoDatabase(NativeDatabase.memory());
      backend = RelayAwareBackend(FakeBackend(), db);
      await db.upsertComputer(
        ComputersCompanion.insert(
          id: id,
          computerName: "Mom's laptop",
          person: 'Mom',
          language: const Value('hi'),
          role: const Value('direct'),
          addedAt: 0,
        ),
      );
    });
    tearDown(() => db.close());

    test('relay computers are profiled locally and need no backend', () async {
      final patched = await backend.patchComputer(id, name: 'Laptop', person: 'Ma');
      expect((patched.name, patched.person, patched.language), ('Laptop', 'Ma', 'hi'));
      final listed = await backend.listComputers();
      expect(listed.where((c) => c.id == id).single.person, 'Mom');
      await backend.deleteComputer(id);
      await backend.setMuted(id, true);
      expect((await backend.usage(id, '2026-10')).tasks, 0);
    });
  });
}
