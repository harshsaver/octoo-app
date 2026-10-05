import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:octo_family/transport/octo_link.dart';
import 'package:octo_family/transport/relay/control_plane.dart';
import 'package:octo_family/transport/relay/encoding.dart';
import 'package:octo_family/transport/relay/noise.dart';
import 'package:octo_family/transport/relay/relay_link.dart';
import 'package:octo_family/transport/relay/relay_vault.dart';
import 'package:octo_family/transport/simulator/simulated_computer.dart';

import '../../../tool/test_octo/host_relay.dart';
import '../../../tool/test_octo/october_cloud.dart';
import '../../../tool/test_octo/test_octo.dart';
import 'fake_relay.dart';

/// October's control plane for one account: intents, devices, and checks of
/// the phone's signed requests.
class FakeOctober implements HostCloud {
  FakeOctober(this.hostId, this.hostStatic);

  final String hostId;
  final String hostStatic;
  final userId = uuidV4();
  final sessionId = uuidV4();
  final Map<String, Map<String, Object?>> intents = {};
  final Map<String, Map<String, Object?>> devices = {};
  final List<String> signedOps = [];
  int _version = 1;

  String get jwt {
    String part(Object json) => b64url(utf8.encode(jsonEncode(json)));
    return '${part({'alg': 'none'})}.${part({'sub': userId, 'session_id': sessionId})}.sig';
  }

  @override
  Future<String> hostTicket() async => 'host-ticket';

  @override
  Future<({String intentId, String secret, int expiresAt})> createPairing() async {
    final intentId = uuidV4();
    final secret = b64url(randomBytes(32));
    final expiresAt = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    intents[intentId] = {'secret': secret, 'state': 'created'};
    return (intentId: intentId, secret: secret, expiresAt: expiresAt);
  }

  String qrFor(({String intentId, String secret, int expiresAt}) intent) {
    final payload = {
      'v': 2,
      'hostId': hostId,
      'hostStatic': hostStatic,
      'intentId': intent.intentId,
      'secret': intent.secret,
      'exp': intent.expiresAt,
    };
    return 'https://october.dev/pair#${b64url(utf8.encode(jsonEncode(payload)))}';
  }

  @override
  Future<HostBinding?> lookupBinding(String bind) async {
    final device = devices[bind];
    if (device != null && device['revoked'] != true) {
      return HostBinding(
        bind: bind,
        pairing: false,
        deviceStatic: b64urlDecode(device['deviceStaticPub']! as String),
        label: device['label']! as String,
      );
    }
    for (final MapEntry(key: intentId, value: i) in intents.entries) {
      if (i['bind'] == bind && (i['state'] == 'pending' || i['state'] == 'approved')) {
        return HostBinding(
          bind: bind,
          pairing: true,
          deviceStatic: b64urlDecode(i['deviceStaticPub']! as String),
          label: i['label']! as String,
          intentId: intentId,
          stateVersion: i['stateVersion']! as int,
          deviceSignPub: i['deviceSignPub']! as String,
        );
      }
    }
    return null;
  }

  @override
  Future<int> decide(HostBinding binding, {required bool approve}) async {
    final i = intents[binding.intentId]!;
    expect(i['stateVersion'], binding.stateVersion);
    i['state'] = approve ? 'approved' : 'denied';
    return i['stateVersion'] = ++_version;
  }

  @override
  Future<int> finalize(String intentId, int stateVersion) async {
    final i = intents[intentId]!;
    expect(i['state'], 'approved');
    i['state'] = 'active';
    devices[i['bind']! as String] = {...i};
    return i['stateVersion'] = ++_version;
  }

  @override
  Future<void> revokeDevice(String bind) async => devices[bind]?['revoked'] = true;

  Future<http.Response> handle(http.Request request) async {
    expect(request.headers['authorization'], 'Bearer $jwt');
    final body = jsonDecode(request.body) as Map<String, Object?>;
    http.Response ok(Object json) => http.Response(jsonEncode(json), 200);
    switch (request.url.path) {
      case '/functions/v1/mobile-pair-consume':
        final i = intents[body['intentId']];
        if (i == null || i['secret'] != body['secret']) {
          return http.Response(jsonEncode({'error': 'no', 'code': 'PAIRING_REJECTED'}), 403);
        }
        i
          ..['state'] = 'pending'
          ..['bind'] = i['bind'] ?? uuidV4()
          ..['stateVersion'] = ++_version
          ..['deviceStaticPub'] = body['deviceStaticPub']
          ..['deviceSignPub'] = body['deviceSignPub']
          ..['label'] = body['label'];
        return ok({
          'bind': i['bind'],
          'hostId': hostId,
          'hostName': "Mom's laptop",
          'hostPlatform': 'linux',
          'machine': 'laptop',
          'hostStatic': hostStatic,
          'stateVersion': i['stateVersion'],
          'ticket': 'pair-ticket',
        });
      case '/functions/v1/mobile-relay-ticket':
        final device = devices[body['bind']];
        if (device == null || device['revoked'] == true) {
          return http.Response(jsonEncode({'error': 'gone', 'code': 'BINDING_INACTIVE'}), 403);
        }
        expect(body['key'], device['deviceStaticPub']);
        await _verify(request, 'ticket-device', device['deviceSignPub']! as String);
        return ok({'ticket': 'device-ticket'});
      case '/functions/v1/mobile-device-revoke':
        await _verify(request, 'device-self-revoke', devices[body['bind']]!['deviceSignPub']! as String);
        devices[body['bind']]!['revoked'] = true;
        return ok({'revoked': true});
    }
    return http.Response('{}', 404);
  }

  Future<void> _verify(http.Request request, String op, String publicKey) async {
    final message = await signedRequestMessage(
      op,
      request.bodyBytes,
      sessionId,
      request.headers['x-october-request-id']!,
      int.parse(request.headers['x-october-request-ts']!),
    );
    final ok = await DartEd25519().verify(
      message,
      signature: Signature(
        b64urlDecode(request.headers['x-october-signature']!),
        publicKey: SimplePublicKey(b64urlDecode(publicKey), type: KeyPairType.ed25519),
      ),
    );
    expect(ok, isTrue, reason: 'signature for $op');
    signedOps.add(op);
  }
}

/// The test Octo that can pretend to be October Desktop without Octo: its
/// core answers every request `{"ok": false}` and refuses the Octo topic by
/// ending the session.
class SwitchableOcto extends TestOcto {
  SwitchableOcto({
    required super.cloud,
    required super.computer,
    required super.state,
    required super.approve,
    required super.say,
  });

  bool octoberOnly = false;
  bool dropAfterSubscribe = false;

  @override
  Future<({int status, Map<String, Object?> body})> request(
    HostSession session,
    Map<String, Object?> envelope,
  ) async {
    if (!octoberOnly) return super.request(session, envelope);
    return (
      status: 200,
      body: {
        'apiVersion': 2,
        'requestId': envelope['requestId'],
        'ok': false,
        'error': {'code': 'INVALID_ARGUMENT', 'message': 'unknown method'},
      },
    );
  }

  @override
  void subscribed(HostSession session) {
    if (octoberOnly || dropAfterSubscribe) session.close();
  }
}

void main() {
  late FakeRelay relay;
  late FakeOctober october;
  late SwitchableOcto octo;
  late SimulatedComputer computer;
  late RelayLink link;
  late List<String> hostLog;
  var approve = true;

  setUp(() async {
    approve = true;
    relay = await FakeRelay.start();
    final state = HostState.fresh();
    final staticKey = await NoiseKeyPair.fromPrivateKey(b64urlDecode(state.staticKey));
    october = FakeOctober(state.hostId, b64url(staticKey.publicKey));
    computer = SimulatedComputer(
      computerId: 'test-octo',
      hostId: state.hostId,
      computerName: "Mom's laptop",
      settings: SimulatorSettings(autopilot: false),
    );
    hostLog = [];
    octo = SwitchableOcto(
      cloud: october,
      computer: computer,
      state: state,
      approve: (label, code) async => approve,
      say: hostLog.add,
    );
    octo.relay = HostRelay(
      relay: relay.uri,
      hostId: state.hostId,
      staticKey: staticKey,
      ticket: october.hostTicket,
      delegate: octo,
    );
    final up = octo.relay.connectedChanges.firstWhere((c) => c);
    await octo.relay.start();
    await up;
    link = RelayLink(
      control: ControlPlane(
        authOrigin: Uri.parse('https://auth.test'),
        accessToken: () async => october.jwt,
        client: MockClient(october.handle),
      ),
      vault: MemoryVault(),
      relay: relay.uri,
      platform: 'android',
      retryDelay: (_) => const Duration(milliseconds: 200),
    );
  });

  RelayLink newLink({Duration stableAfter = const Duration(seconds: 30), List<int>? attempts}) => RelayLink(
    control: ControlPlane(
      authOrigin: Uri.parse('https://auth.test'),
      accessToken: () async => october.jwt,
      client: MockClient(october.handle),
    ),
    vault: (link.vault as MemoryVault),
    relay: relay.uri,
    platform: 'android',
    stableAfter: stableAfter,
    retryDelay: (attempt) {
      attempts?.add(attempt);
      return const Duration(milliseconds: 150);
    },
  );

  tearDown(() async {
    link.dispose();
    await octo.dispose();
    computer.dispose();
    await relay.close();
  });

  Future<List<PairingProgress>> pair({bool match = true}) async {
    final qr = october.qrFor(await october.createPairing());
    final seen = <PairingProgress>[];
    await for (final p in link.pair(qr, helperName: 'Harsh', deviceLabel: "Harsh's Android phone")) {
      seen.add(p);
      if (p is PairingCompareCode) {
        // The same six digits on both screens.
        await _until(() => hostLog.any((l) => l.contains('Code on both screens: ${p.code}')));
        await p.confirm(match);
      }
    }
    return seen;
  }

  test('pairs, connects, and carries family messages both ways', () async {
    final progress = await pair();
    expect(progress.first, isA<PairingScanned>());
    expect(progress.whereType<PairingWaitingForHer>(), hasLength(1));
    final paired = (progress.last as PairingPaired).computer;
    expect(paired.computerId, relayComputerId(october.hostId));
    expect(paired.computerName, "Mom's laptop");
    expect(computer.helpers.values.single.name, 'Harsh');

    final states = <LinkState>[];
    final connected = Completer<void>();
    final sub = link.connect(paired.computerId).listen((s) {
      states.add(s);
      if (s == LinkState.connected && !connected.isCompleted) connected.complete();
    });
    await connected.future;
    expect(october.signedOps, contains('ticket-device'));

    final inbox = <Map<String, Object?>>[];
    link.messages(paired.computerId).listen(inbox.add);
    await link.send(paired.computerId, {'type': 'status', 'requestId': 'r1'});
    await _until(() => inbox.any((m) => m['type'] == 'status' && m['requestId'] == 'r1'), what: 'status $inbox $hostLog');

    // A screenshot-sized event crosses the relay without the 1 MiB backlog
    // drop: the host paces itself.
    final big = 'x' * (3 * 1024 * 1024);
    await octo.relay.sessions.values.single.sendEvent(familyTopic, {'type': 'big', 'data': big});
    await _until(() => inbox.any((m) => m['type'] == 'big'), timeout: const Duration(seconds: 20), what: 'big ${relay.backlogDrops} $hostLog');
    expect((inbox.firstWhere((m) => m['type'] == 'big')['data']! as String).length, big.length);
    expect(relay.backlogDrops, 0);

    // Mom removes the phone: "removed" arrives and the link stops retrying.
    await octo.removeAll();
    await _until(() => inbox.any((m) => m['type'] == 'removed'), what: 'removed');
    await _until(() => states.last == LinkState.offline, what: 'offline $states');
    final before = states.length;
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(states.length, before);
    await sub.cancel();
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('reconnects after her computer comes back', () async {
    final paired = ((await pair()).last as PairingPaired).computer;
    final states = <LinkState>[];
    final sub = link.connect(paired.computerId).listen(states.add);
    await _until(() => states.contains(LinkState.connected));
    states.clear();
    await relay.dropHost(october.hostId);
    await _until(() => states.contains(LinkState.offline));
    await _until(() => octo.relay.connected); // the host renews its lease
    await _until(() => states.last == LinkState.connected, timeout: const Duration(seconds: 10));
    await link.send(paired.computerId, {'type': 'status', 'requestId': 'r2'});
    await sub.cancel();
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('send without a connection is definitely not sent', () async {
    await expectLater(
      link.send('rly_nothing', {'type': 'status', 'requestId': 'r'}),
      throwsA(isA<LinkUnavailableException>()),
    );
  });

  test('she says no: pairing fails and nothing is kept', () async {
    approve = false;
    final progress = await pair();
    expect(progress.last, isA<PairingFailed>());
    expect((progress.last as PairingFailed).kind, PairingFailureKind.reportedByComputer);
    expect(computer.helpers, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 1)));

  test("the helper says the codes don't match", () async {
    final progress = await pair(match: false);
    expect((progress.last as PairingFailed).kind, PairingFailureKind.codeMismatch);
  }, timeout: const Timeout(Duration(minutes: 1)));

  test("October Desktop's own code pairs at October's level but is refused: not Octo", () async {
    octo.octoberOnly = true;
    final progress = await pair();
    final last = progress.last as PairingFailed;
    expect(last.kind, PairingFailureKind.notOcto);
    expect(last.isFinal, isTrue);
    expect(october.signedOps, contains('device-self-revoke'));
    expect((link.vault as MemoryVault).bindings, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('an already-paired computer that is not Octo: one notOcto, no reconnect loop', () async {
    final paired = ((await pair()).last as PairingPaired).computer;
    octo.octoberOnly = true;
    final states = <LinkState>[];
    final sub = link.connect(paired.computerId).listen(states.add);
    await _until(() => states.contains(LinkState.notOcto), what: '$states');
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(states, [LinkState.connecting, LinkState.notOcto]);
    await sub.cancel();
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('a connection that dies at once backs off instead of flickering', () async {
    final paired = ((await pair()).last as PairingPaired).computer;
    octo.dropAfterSubscribe = true;
    final attempts = <int>[];
    final flaky = newLink(attempts: attempts);
    final states = <LinkState>[];
    final sub = flaky.connect(paired.computerId).listen(states.add);
    await _until(() => attempts.length >= 3, timeout: const Duration(seconds: 10), what: '$attempts $states');
    expect(attempts.take(3), [0, 1, 2]);
    await sub.cancel();
    flaky.dispose();
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('a routine drop after a stable connection shows connecting, not offline', () async {
    final paired = ((await pair()).last as PairingPaired).computer;
    final steady = newLink(stableAfter: const Duration(milliseconds: 100));
    final states = <LinkState>[];
    final sub = steady.connect(paired.computerId).listen(states.add);
    await _until(() => states.contains(LinkState.connected));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    states.clear();
    await relay.dropHost(october.hostId); // the relay renews the host's lease
    await _until(() => states.contains(LinkState.connected), timeout: const Duration(seconds: 10), what: '$states');
    expect(states, isNot(contains(LinkState.offline)));
    await sub.cancel();
    steady.dispose();
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('a link that is not an October pairing code', () async {
    final progress = await link.pair('https://october.dev/pair#nope', helperName: 'H', deviceLabel: 'D').toList();
    expect((progress.single as PairingFailed).kind, PairingFailureKind.invalidCode);
  });
}

Future<void> _until(bool Function() test, {Duration timeout = const Duration(seconds: 5), String? what}) async {
  final end = DateTime.now().add(timeout);
  while (!test()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('condition not met: ${what ?? ''}');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
