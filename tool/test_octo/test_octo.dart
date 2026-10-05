/// The test Octo: a computer that speaks the family protocol over October's
/// real relay, so the app can be tried end to end before the Octo desktop
/// app exists. Her side is the app's own [SimulatedComputer]; pairing,
/// keys and the relay are October's real ones.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:octo_family/transport/relay/encoding.dart';
import 'package:octo_family/transport/relay/frames.dart';
import 'package:octo_family/transport/relay/relay_link.dart' show familyMethod, familyProtocol, familyTopic, helloMethod;
import 'package:octo_family/transport/relay/relay_protocol.dart';
import 'package:octo_family/transport/simulator/simulated_computer.dart';

import 'host_relay.dart';
import 'october_cloud.dart';

/// What the test Octo remembers between runs (a JSON file, mode 600).
class HostState {
  HostState({
    required this.hostId,
    required this.staticKey,
    required this.signSeed,
    Map<String, ({String credential, String label})>? devices,
  }) : devices = devices ?? {};

  factory HostState.fresh() => HostState(
    hostId: uuidV4(),
    staticKey: b64url(randomBytes(32)),
    signSeed: b64url(randomBytes(32)),
  );

  factory HostState.fromJson(Map<String, Object?> json) => HostState(
    hostId: json['hostId']! as String,
    staticKey: json['staticKey']! as String,
    signSeed: json['signSeed']! as String,
    devices: {
      for (final MapEntry(:key, :value) in (json['devices'] as Map<String, Object?>? ?? {}).entries)
        key: (
          credential: (value! as Map<String, Object?>)['credential']! as String,
          label: (value as Map<String, Object?>)['label'] as String? ?? '',
        ),
    },
  );

  final String hostId;

  /// X25519 private key, base64url.
  final String staticKey;

  /// Ed25519 seed, base64url.
  final String signSeed;

  /// Paired phones by binding id.
  final Map<String, ({String credential, String label})> devices;

  Map<String, Object?> toJson() => {
    'hostId': hostId,
    'staticKey': staticKey,
    'signSeed': signSeed,
    'devices': {
      for (final MapEntry(:key, :value) in devices.entries)
        key: {'credential': value.credential, 'label': value.label},
    },
  };

  static HostState load(File file) {
    if (!file.existsSync()) return HostState.fresh();
    return HostState.fromJson(jsonDecode(file.readAsStringSync()) as Map<String, Object?>);
  }

  void save(File file) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(toJson()));
    if (!Platform.isWindows) Process.runSync('chmod', ['600', file.path]);
  }
}

/// "Harsh's Android phone" → "Harsh".
String helperNameFromLabel(String label) =>
    RegExp(r"^(.+?)['’]s ").firstMatch(label)?.group(1) ?? (label.isEmpty ? 'Helper' : label);

class TestOcto implements HostDelegate {
  TestOcto({
    required this.cloud,
    required this.computer,
    required this.state,
    required this.approve,
    required this.say,
    this.save,
  }) {
    _outbound = computer.outbound.listen(_broadcast);
    for (final MapEntry(:key, :value) in state.devices.entries) {
      computer.helpers[key] = SimHelper(id: key, name: helperNameFromLabel(value.label), device: value.label);
    }
  }

  final HostCloud cloud;
  final SimulatedComputer computer;
  final HostState state;

  /// Asks the person at the laptop to approve a phone (Mom's OK).
  final Future<bool> Function(String label, String code) approve;
  final void Function(String line) say;

  /// Persists [state] after a change.
  final void Function()? save;
  late final HostRelay relay;
  late final StreamSubscription<Map<String, Object?>> _outbound;
  final Map<String, Completer<void>> _acks = {};
  final Map<String, String> _codes = {};

  void _broadcast(Map<String, Object?> message) {
    for (final s in relay.sessions.values.toList()) {
      if (!s.authenticated || !s.subscribed || !s.isOpen) continue;
      s.sendEvent(familyTopic, message).catchError((Object e) => say('could not send to ${s.bind}: $e'));
    }
  }

  @override
  Future<HostBinding?> resolveBinding(String bind) => cloud.lookupBinding(bind);

  @override
  void pairReady(HostSession session, String code) {
    _codes[session.bind] = code;
    say('A phone connected to pair: "${session.binding!.label}". Code on both screens: $code');
  }

  @override
  void pairFrame(HostSession session, FrameKind kind, Map<String, Object?> value) {
    if (kind == FrameKind.pairAck) {
      _acks.remove(session.bind)?.complete();
      return;
    }
    if (kind == FrameKind.pairOffer && !_acks.containsKey(session.bind)) {
      // Settled with an error if the phone leaves; read only when approved.
      _acks[session.bind] = Completer<void>()..future.ignore();
      unawaited(_decide(session));
    }
  }

  Future<void> _decide(HostSession session) async {
    final binding = session.binding!;
    try {
      final ok = await approve(binding.label, _codes[session.bind] ?? '');
      if (!session.isOpen) return;
      final version = await cloud.decide(binding, approve: ok);
      if (!ok) {
        say('Turned down.');
        session.close();
        return;
      }
      final credential = b64url(randomBytes(32));
      await session.sendPair(FrameKind.pairCredential, {'credential': credential});
      await _acks[session.bind]!.future.timeout(const Duration(seconds: 60));
      final finalVersion = await cloud.finalize(binding.intentId!, version);
      state.devices[session.bind] = (credential: credential, label: binding.label);
      save?.call();
      computer.helpers[session.bind] = SimHelper(
        id: session.bind,
        name: helperNameFromLabel(binding.label),
        device: binding.label,
      );
      await session.sendPair(FrameKind.pairActive, {'bind': session.bind, 'stateVersion': finalVersion});
      say('Paired with "${binding.label}".');
    } on Object catch (e) {
      say('Pairing failed: $e');
      session.close();
    } finally {
      _acks.remove(session.bind);
      _codes.remove(session.bind);
    }
  }

  @override
  bool authenticate(HostSession session, String credential) {
    final known = state.devices[session.bind];
    final ok = known != null && known.credential == credential;
    if (ok) say('"${known.label}" connected.');
    return ok;
  }

  @override
  Future<({int status, Map<String, Object?> body})> request(
    HostSession session,
    Map<String, Object?> envelope,
  ) async {
    ({int status, Map<String, Object?> body}) ok([Map<String, Object?> result = const {}]) => (
      status: 200,
      body: {'apiVersion': 2, 'requestId': envelope['requestId'], 'ok': true, 'result': result},
    );
    ({int status, Map<String, Object?> body}) error(int status, String code) => (
      status: status,
      body: {
        'apiVersion': 2,
        'requestId': envelope['requestId'],
        'ok': false,
        'error': {'code': code, 'message': code},
      },
    );
    final payload = envelope['payload'];
    switch (envelope['method']) {
      case helloMethod:
        return ok({'octo': familyProtocol, 'computer': computer.computerName, 'person': computer.person});
      case familyMethod when payload is Map<String, Object?>:
        say('← ${payload['type']}');
        computer.receive(payload, from: session.bind);
        if (payload['type'] == 'leave') {
          // After the `res` for this request has gone out.
          unawaited(Future<void>.delayed(const Duration(seconds: 1), () => _forget(session.bind, notify: false)));
        }
        return ok();
      case familyMethod:
        return error(400, 'INVALID_ARGUMENT');
      default:
        return error(404, 'NOT_FOUND');
    }
  }

  @override
  void subscribed(HostSession session) {}

  @override
  void closed(HostSession session) {
    _acks.remove(session.bind)?.completeError(StateError('the phone disconnected'));
  }

  @override
  void log(String line) => say(line);

  /// Mom removes every phone (the app shows "removed").
  Future<void> removeAll() async {
    for (final bind in state.devices.keys.toList()) {
      await _forget(bind, notify: true);
    }
  }

  Future<void> _forget(String bind, {required bool notify}) async {
    final session = relay.sessions[bind];
    if (notify && session != null && session.authenticated) {
      await session.sendEvent(familyTopic, const {'type': 'removed'}).catchError((_) {});
    }
    session?.close(RelayClose.revoked);
    state.devices.remove(bind);
    computer.helpers.remove(bind);
    save?.call();
    try {
      await cloud.revokeDevice(bind);
    } on Object catch (e) {
      say('(cloud revoke failed: $e)');
    }
  }

  Future<void> dispose() async {
    await _outbound.cancel();
    await relay.stop();
  }
}
