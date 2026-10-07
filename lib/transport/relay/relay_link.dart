import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../octo_link.dart';
import 'control_plane.dart';
import 'device_connection.dart';
import 'encoding.dart';
import 'frames.dart';
import 'noise.dart';
import 'relay_protocol.dart';
import 'relay_vault.dart';

/// The topic family messages ride on, computer → phone (docs/relay-protocol.md).
const familyTopic = 'octo.family';

/// The request method for family messages, phone → computer.
const familyMethod = 'octo.message';

/// The first request on every connection; only an Octo computer answers it
/// with `{"ok": true, "result": {"octo": 1}}`.
const helloMethod = 'octo.hello';

/// The family protocol version this app speaks.
const familyProtocol = 1;

/// A computer paired over the relay without the Octo backend has this id.
String relayComputerId(String hostId) => 'rly_${hostId.replaceAll('-', '')}';

bool isRelayComputerId(String computerId) => computerId.startsWith('rly_');

/// October Desktop's pairing QR: `https://october.dev/pair#<base64url(JSON)>`
/// with `{v: 2, hostId, hostStatic, intentId, secret, exp}`.
typedef PairingQr = ({String hostId, String hostStatic, String intentId, String secret, int exp});

PairingQr? parsePairingLink(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https' || uri.host != 'october.dev' || uri.path != '/pair') return null;
  try {
    final json = jsonDecode(utf8.decode(b64urlDecode(uri.fragment)));
    if (json is! Map<String, Object?>) return null;
    final (v, hostId, intentId, hostStatic, secret, exp) =
        (json['v'], json['hostId'], json['intentId'], json['hostStatic'], json['secret'], json['exp']);
    if (v != 2 || !isCanonicalUuid(hostId) || !isCanonicalUuid(intentId)) return null;
    if (hostStatic is! String || secret is! String || exp is! int) return null;
    return (hostId: hostId! as String, hostStatic: hostStatic, intentId: intentId! as String, secret: secret, exp: exp);
  } on Object {
    return null;
  }
}

/// The real [OctoLink]: October's relay, end-to-end encrypted with Noise
/// (october-desktop `mobile/src/october/pairing.ts` and `relay.ts`).
///
/// Family JSON goes to her computer as `req` frames (method `octo.message`)
/// and comes back as `ev` lines on topic `octo.family`.
class RelayLink implements OctoLink, HelperIdentity {
  RelayLink({
    required this.control,
    required this.vault,
    required this.relay,
    required this.platform,
    this.connector = connectIoSocket,
    this.requestTimeout = const Duration(seconds: 20),
    this.credentialTimeout = const Duration(minutes: 5),
    this.retryDelay = relayRetryDelay,
    this.stableAfter = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ControlPlane control;
  final RelayVault vault;

  /// `https://relay.afteroctober.xyz`.
  final Uri relay;

  /// `ios` or `android`.
  final String platform;
  final SocketConnector connector;
  final Duration requestTimeout;
  final Duration credentialTimeout;
  final Duration Function(int attempt) retryDelay;

  /// A connection that lasted this long resets the backoff when it drops.
  final Duration stableAfter;
  final DateTime Function() _now;

  final Map<String, _Live> _live = {};
  final Map<String, StreamController<Map<String, Object?>>> _messages = {};

  // ---------------------------------------------------------------------
  // Pairing

  @override
  Stream<PairingProgress> pair(String qrPayloadOrCode, {required String helperName, required String deviceLabel}) {
    late final StreamController<PairingProgress> out;
    DeviceConnection? connection;
    var cancelled = false;
    out = StreamController<PairingProgress>(
      onListen: () => unawaited(
        _pair(qrPayloadOrCode, deviceLabel, out, (c) => connection = c, () => cancelled).whenComplete(() {
          connection?.close();
          if (!out.isClosed) out.close();
        }),
      ),
      onCancel: () {
        cancelled = true;
        connection?.close();
      },
    );
    return out.stream;
  }

  Future<void> _pair(
    String payload,
    String deviceLabel,
    StreamController<PairingProgress> out,
    void Function(DeviceConnection) onConnection,
    bool Function() cancelled,
  ) async {
    void emit(PairingProgress p) {
      if (!cancelled() && !out.isClosed) out.add(p);
    }

    PairingFailed failed(PairingFailureKind kind, {String? reason, bool isFinal = false}) =>
        PairingFailed(kind: kind, reason: reason, isFinal: isFinal);

    final qr = parsePairingLink(payload);
    if (qr == null) return emit(failed(PairingFailureKind.invalidCode));
    if (qr.exp <= _now().millisecondsSinceEpoch) return emit(failed(PairingFailureKind.timedOut));

    final ({String userId, String sessionId}) session;
    try {
      session = await control.session();
    } on ControlPlaneException catch (e) {
      return emit(failed(PairingFailureKind.reportedByComputer, reason: e.message));
    }
    final deviceStatic = await NoiseKeyPair.generate();
    final deviceSign = await SigningKey.generate();
    final body = {
      'intentId': qr.intentId,
      'secret': qr.secret,
      'deviceStaticPub': b64url(deviceStatic.publicKey),
      'deviceSignPub': b64url(deviceSign.publicKey),
      'label': deviceLabel,
      'platform': platform,
    };
    Map<String, Object?> consumed;
    try {
      // A lost answer may hide a consume that worked; the server replays it
      // for the same keys, so retrying is safe. A server answer is final.
      for (var attempt = 1; ; attempt++) {
        try {
          consumed = await control.post('mobile-pair-consume', body);
          break;
        } on ControlPlaneException catch (e) {
          if (e.answered || attempt == 3 || cancelled()) rethrow;
        }
      }
    } on ControlPlaneException catch (e) {
      return emit(switch (e.code) {
        'PAIRING_EXPIRED' || 'PAIRING_USED' => failed(PairingFailureKind.timedOut),
        'PAIRING_REJECTED' => failed(
          PairingFailureKind.reportedByComputer,
          reason: 'This code belongs to a different October account, or is no longer valid.',
        ),
        'PAIRING_DENIED' => failed(PairingFailureKind.reportedByComputer, reason: 'Pairing was turned down.'),
        _ when !e.answered => failed(PairingFailureKind.offline),
        _ => failed(PairingFailureKind.reportedByComputer, reason: e.message),
      });
    }
    if (cancelled()) return;
    final bind = consumed['bind'];
    final ticket = consumed['ticket'];
    if (consumed['hostId'] != qr.hostId ||
        consumed['hostStatic'] != qr.hostStatic ||
        !isCanonicalUuid(bind) ||
        ticket is! String) {
      return emit(
        failed(PairingFailureKind.reportedByComputer, reason: 'The computer identity changed while pairing.'),
      );
    }
    final hostName = consumed['hostName'] is String ? consumed['hostName']! as String : 'Computer';
    emit(PairingScanned(hostName));

    final computerId = relayComputerId(qr.hostId);
    var binding = RelayBinding(
      computerId: computerId,
      userId: session.userId,
      hostId: qr.hostId,
      bind: bind! as String,
      hostStatic: qr.hostStatic,
      hostName: hostName,
      deviceStaticKey: b64url(deviceStatic.privateKey),
      deviceSignSeed: b64url(deviceSign.seed),
      startedAt: _now().millisecondsSinceEpoch,
    );
    // Pairing this computer again must not lose a pairing that works if
    // this attempt fails: the old one is only replaced at `finalizing`, and
    // put back on failure.
    final previous = await vault.read(session.userId, computerId);
    final keepPrevious = previous != null && previous.usable;
    if (!keepPrevious) await vault.write(binding);
    _pairing.add(computerId);
    var paired = false;
    try {
      final DeviceConnection c;
      try {
        c = await DeviceConnection.open(
          relay: relay,
          hostId: qr.hostId,
          bind: binding.bind,
          ticket: ticket,
          deviceStatic: deviceStatic,
          hostStatic: b64urlDecode(qr.hostStatic),
          connector: connector,
        );
      } on Object {
        return emit(failed(PairingFailureKind.offline));
      }
      onConnection(c);
      if (cancelled()) return;

      final credential = Completer<String>();
      final active = Completer<void>();
      final frames = c.frames.listen((f) {
        if (f.kind == FrameKind.pairCredential && !credential.isCompleted) {
          final value = _json(f.data)['credential'];
          if (value is String && value.length >= 32) {
            credential.complete(value);
          } else {
            credential.completeError(const FormatException('invalid credential'));
          }
        }
        if (f.kind == FrameKind.pairActive && !active.isCompleted) active.complete();
      });
      final closed = c.done.then<Never>((code) => throw _PairingClosed(code));
      closed.ignore();

      final confirmed = Completer<bool>();
      emit(
        PairingCompareCode(c.pairingCode, (match) async {
          if (!confirmed.isCompleted) confirmed.complete(match);
        }),
      );
      try {
        final match = await Future.any([confirmed.future, closed]);
        if (!match) return emit(failed(PairingFailureKind.codeMismatch, isFinal: true));
        await c.sendJson(FrameKind.pairOffer, {'intentId': qr.intentId, 'nonce': uuidV4()});
        emit(const PairingWaitingForHer());
        final value = await Future.any([credential.future, closed]).timeout(credentialTimeout);
        binding = binding.copyWith(credential: value, phase: BindingPhase.finalizing, profile: previous?.profile);
        await vault.write(binding);
        await c.sendJson(FrameKind.pairAck, const {});
        await Future.any([active.future, closed]).timeout(const Duration(seconds: 60));
      } on TimeoutException {
        return emit(failed(PairingFailureKind.timedOut));
      } on _PairingClosed catch (e) {
        if (cancelled()) return;
        if (e.code == RelayClose.hostOffline || e.code == RelayClose.hostDisconnected) {
          return emit(failed(PairingFailureKind.offline));
        }
        // Her computer ended it: October knows whether she said no.
        return emit(switch (await _intentState(qr.intentId)) {
          'denied' => failed(PairingFailureKind.reportedByComputer, reason: 'She said no on her computer.'),
          'expired' => failed(PairingFailureKind.timedOut),
          _ => failed(PairingFailureKind.reportedByComputer, reason: 'Her computer ended the pairing.'),
        });
      } on Object {
        return emit(failed(PairingFailureKind.reportedByComputer, reason: 'Pairing failed. Try a fresh code.'));
      } finally {
        await frames.cancel();
      }
      c.close();
      // Pairing used October's own protocol, which any October computer
      // speaks. Before calling it paired, check this one runs Octo.
      try {
        final probe = await _openActive(computerId, binding);
        probe.close();
      } on NotOctoException {
        await _selfRevoke(binding);
        return emit(failed(PairingFailureKind.notOcto, isFinal: true));
      } on Object {
        // Not reachable right now: it'll be checked on every connection.
      }
      if (cancelled()) return;
      binding = binding.copyWith(phase: BindingPhase.complete);
      await vault.write(binding);
      paired = true;
      emit(
        PairingPaired(
          PairedComputer(computerId: computerId, hostId: qr.hostId, computerName: hostName, bind: binding.bind),
        ),
      );
    } finally {
      _pairing.remove(computerId);
      if (!paired) {
        if (keepPrevious) {
          await vault.write(previous);
        } else {
          await vault.delete(binding.userId, computerId);
        }
      }
    }
  }

  final Set<String> _pairing = {};

  /// Computers being paired right now; their `started` bindings are not
  /// leftovers.
  Set<String> get pairingNow => Set.unmodifiable(_pairing);

  // ---------------------------------------------------------------------
  // Connection

  @override
  Stream<LinkState> connect(String computerId) {
    late final StreamController<LinkState> out;
    var stopped = false;
    Timer? retry;
    _Live? current;
    var attempt = 0;

    void state(LinkState s) {
      if (!stopped && !out.isClosed) out.add(s);
    }

    Future<void> run() async {
      if (stopped) return;
      state(LinkState.connecting);
      Duration? wait;
      try {
        final binding = await _binding(computerId);
        if (binding == null || !binding.usable) {
          state(LinkState.offline);
          return; // not paired on this phone: nothing to retry
        }
        final live = current = await _openActive(computerId, binding);
        if (stopped) return live.close();
        _live[computerId] = live;
        final since = _now();
        state(LinkState.connected);
        final code = await live.connection.done;
        if (_live[computerId] == live) _live.remove(computerId);
        live.close();
        if (stopped) return;
        // The relay or her computer says this phone may not reconnect.
        if (code == RelayClose.revoked || code == RelayClose.authenticationFailed || code == RelayClose.replaced) {
          state(LinkState.offline);
          return;
        }
        // A connection that lasted is a routine drop (the relay renews
        // leases every few minutes): show "connecting", not "offline", and
        // start the backoff over. One that died at once counts as a failure.
        if (_now().difference(since) >= stableAfter) {
          attempt = 0;
          state(LinkState.connecting);
        } else {
          state(LinkState.offline);
        }
        if (code == RelayClose.rateLimited) wait = const Duration(seconds: 60);
      } on NotOctoException {
        // Her computer answers but isn't running Octo (October Desktop's own
        // pairing code was scanned). Retrying won't change that.
        state(LinkState.notOcto);
        return;
      } on ControlPlaneException catch (e) {
        state(LinkState.offline);
        if (e.code == 'plan_required' || e.code == 'HOST_INACTIVE' || e.code == 'BINDING_INACTIVE') {
          wait = const Duration(minutes: 5);
        } else if (e.status == 429) {
          wait = const Duration(seconds: 60);
        }
      } on Object {
        state(LinkState.offline);
      }
      if (stopped) return;
      retry = Timer(wait ?? retryDelay(attempt++), () => unawaited(run()));
    }

    out = StreamController<LinkState>(
      onListen: () => unawaited(run()),
      onCancel: () {
        stopped = true;
        retry?.cancel();
        current?.close();
        unawaited(out.close());
      },
    );
    return out.stream;
  }

  /// Ticket → socket → Noise → `auth` → `octo.hello` → `sub`. Throws
  /// [NotOctoException] when her computer answers but doesn't speak Octo.
  Future<_Live> _openActive(String computerId, RelayBinding binding) async {
    final sign = await SigningKey.fromSeed(b64urlDecode(binding.deviceSignSeed));
    final ticket = await control.post(
      'mobile-relay-ticket',
      {'role': 'device', 'hostId': binding.hostId, 'bind': binding.bind, 'key': await _staticPub(binding)},
      signer: sign,
      operation: 'ticket-device',
    );
    final c = await DeviceConnection.open(
      relay: relay,
      hostId: binding.hostId,
      bind: binding.bind,
      ticket: ticket['ticket']! as String,
      deviceStatic: await NoiseKeyPair.fromPrivateKey(b64urlDecode(binding.deviceStaticKey)),
      hostStatic: b64urlDecode(binding.hostStatic),
      connector: connector,
    );
    final live = _Live(c, binding.bind);
    live.frames = c.frames.listen((f) => _onFrame(computerId, live, f));
    try {
      await c.send(FrameKind.auth, utf8.encode(binding.credential!));
      // Before subscribing: October Desktop's core refuses the Octo topic
      // and would end the session before the answer arrived.
      final hello = await _request(live, helloMethod, const {'app': 'octo-family', 'protocol': familyProtocol});
      final result = hello.body['result'];
      if (!hello.ok || result is! Map<String, Object?> || result['octo'] != familyProtocol) {
        throw const NotOctoException();
      }
      await _rememberHelperId(computerId, binding, result['helperId']);
      await c.sendJson(FrameKind.sub, {
        'cursor': null,
        'topics': [familyTopic],
        'terminals': const <String>[],
      });
      return live;
    } on Object {
      live.close();
      rethrow;
    }
  }

  final Map<String, String> _helperIds = {};

  @override
  String? helperIdFor(String computerId) => _helperIds[computerId];

  /// The computer says who this phone is (`octo.hello` → `helperId`); kept
  /// with the pairing so it's known offline and after a restart.
  Future<void> _rememberHelperId(String computerId, RelayBinding binding, Object? helperId) async {
    final id = helperId is String && helperId.isNotEmpty ? helperId : binding.helperId;
    if (id == null) return;
    _helperIds[computerId] = id;
    if (binding.helperId != id) {
      final current = await vault.read(binding.userId, computerId);
      if (current != null) await vault.write(current.copyWith(helperId: id));
    }
  }

  /// Loads helper ids saved with earlier pairings.
  Future<void> loadHelperIds(String userId) async {
    for (final b in await vault.list(userId)) {
      if (b.helperId != null) _helperIds[b.computerId] = b.helperId!;
    }
  }

  /// One `req`; completes with the computer's answer. October's convention:
  /// success is a 2xx status *and* `{"ok": true}` in the body.
  /// The pairing intent's state (`pending`, `approved`, `denied`,
  /// `expired`, `active`), or null if October can't say right now.
  Future<String?> _intentState(String intentId) async {
    try {
      final rows = await control
          .select('mobile_pair_intents', {'select': 'state', 'intent_id': 'eq.$intentId', 'limit': '1'})
          .timeout(const Duration(seconds: 5));
      return rows.isEmpty ? null : rows.first['state'] as String?;
    } on Object {
      return null;
    }
  }

  Future<_Reply> _request(_Live live, String method, Map<String, Object?> payload) async {
    // At most [maxInFlight] requests wait for her computer at once (October
    // Desktop ends the session past 16).
    try {
      await live.slots.acquire();
    } on Object {
      throw const _NotSent();
    }
    try {
      return await _requestNow(live, method, payload);
    } finally {
      live.slots.release();
    }
  }

  Future<_Reply> _requestNow(_Live live, String method, Map<String, Object?> payload) async {
    final envelope = {
      'apiVersion': 2,
      'requestId': uuidV4(),
      'deadlineAt': _now().add(requestTimeout).millisecondsSinceEpoch,
      'principal': {'kind': 'remote', 'id': live.bind},
      'method': method,
      'payload': payload,
    };
    final id = live.connection.newMessageId();
    final reply = live.pending[id] = Completer<_Reply>();
    try {
      await live.connection.sendWithId(FrameKind.req, utf8.encode(jsonEncode(envelope)), id);
    } on Object {
      live.pending.remove(id);
      rethrow;
    }
    return reply.future.timeout(
      requestTimeout,
      onTimeout: () {
        live.pending.remove(id);
        // Tell her computer to stop working on it.
        final target = ByteData(4)..setUint32(0, id);
        if (live.connection.isOpen) {
          live.connection.send(FrameKind.cancel, target.buffer.asUint8List()).ignore();
        }
        throw TimeoutException('her computer did not answer');
      },
    );
  }

  void _onFrame(String computerId, _Live live, AssembledFrame f) {
    switch (f.kind) {
      case FrameKind.res:
        final pending = live.pending.remove(f.messageId);
        if (pending == null) return;
        try {
          final r = decodeResponse(f.data);
          pending.complete(_Reply(r.status, _json(r.body)));
        } on FrameViolation catch (e) {
          pending.completeError(e);
        }
      case FrameKind.ev:
        final sink = _sink(computerId); // ignore: close_sinks (closed in dispose)
        for (final line in utf8.decode(f.data).split('\n')) {
          if (line.trim().isEmpty) continue;
          final Object? envelope;
          try {
            envelope = jsonDecode(line);
          } on FormatException {
            continue;
          }
          if (envelope is! Map<String, Object?> || envelope['topic'] != familyTopic) continue;
          final payload = envelope['payload'];
          if (payload is Map<String, Object?>) sink.add(payload);
        }
      default:
        break;
    }
  }

  @override
  Future<void> send(String computerId, Map<String, Object?> message) async {
    final live = _live[computerId];
    if (live == null || !live.connection.isOpen) throw LinkUnavailableException(computerId);
    final _Reply reply;
    try {
      reply = await _request(live, familyMethod, message);
    } on _NotSent {
      throw LinkUnavailableException(computerId);
    }
    if (!reply.ok) {
      final error = reply.body['error'];
      final code = error is Map<String, Object?> ? error['code'] : null;
      throw StateError('her computer refused the message (${reply.status}${code == null ? '' : ' $code'})');
    }
  }

  @override
  Stream<Map<String, Object?>> messages(String computerId) => _sink(computerId).stream;

  StreamController<Map<String, Object?>> _sink(String computerId) =>
      _messages.putIfAbsent(computerId, StreamController<Map<String, Object?>>.broadcast);

  @override
  Future<void> unpair(String computerId) async {
    _live.remove(computerId)?.close();
    final binding = await _binding(computerId);
    if (binding == null) return;
    await _selfRevoke(binding);
    await vault.delete(binding.userId, computerId);
  }

  /// Best effort: her computer may already have forgotten this phone.
  Future<void> _selfRevoke(RelayBinding binding) async {
    try {
      await control.post(
        'mobile-device-revoke',
        {'hostId': binding.hostId, 'bind': binding.bind},
        signer: await SigningKey.fromSeed(b64urlDecode(binding.deviceSignSeed)),
        operation: 'device-self-revoke',
      );
    } on ControlPlaneException {
      // ignored
    }
  }

  void dispose() {
    for (final live in _live.values) {
      live.close();
    }
    _live.clear();
    for (final sink in _messages.values) {
      unawaited(sink.close());
    }
    _messages.clear();
    control.close();
  }

  Future<RelayBinding?> _binding(String computerId) async {
    final session = await control.session();
    return vault.read(session.userId, computerId);
  }

  static Future<String> _staticPub(RelayBinding binding) async =>
      b64url((await NoiseKeyPair.fromPrivateKey(b64urlDecode(binding.deviceStaticKey))).publicKey);

  static Map<String, Object?> _json(Uint8List data) {
    try {
      final value = jsonDecode(utf8.decode(data));
      return value is Map<String, Object?> ? value : const {};
    } on FormatException {
      return const {};
    }
  }
}

/// Requests allowed to wait for her computer at once, per connection.
const maxInFlight = 8;

class _Live {
  _Live(this.connection, this.bind);

  final DeviceConnection connection;
  final String bind;
  final Map<int, Completer<_Reply>> pending = {};
  final slots = _Slots(maxInFlight);
  StreamSubscription<AssembledFrame>? frames;

  void close() {
    unawaited(frames?.cancel());
    connection.close();
    for (final p in pending.values) {
      p.completeError(StateError('the connection closed'));
    }
    pending.clear();
    slots.fail(StateError('the connection closed'));
  }
}

/// A counting semaphore; [fail] wakes everyone waiting with an error.
class _Slots {
  _Slots(this._free);

  int _free;
  final _waiting = <Completer<void>>[];

  Future<void> acquire() {
    if (_free > 0) {
      _free--;
      return Future.value();
    }
    final c = Completer<void>();
    _waiting.add(c);
    return c.future;
  }

  void release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete();
    } else {
      _free++;
    }
  }

  void fail(Object error) {
    for (final c in _waiting) {
      c.completeError(error);
    }
    _waiting.clear();
  }
}

class _Reply {
  const _Reply(this.status, this.body);

  final int status;
  final Map<String, Object?> body;

  bool get ok => status >= 200 && status < 300 && body['ok'] == true;
}

/// Her computer answered, but not as Octo: it's October Desktop (or another
/// October host) without Octo.
class NotOctoException implements Exception {
  const NotOctoException();
}

/// Closed while waiting for a slot: nothing went out.
class _NotSent implements Exception {
  const _NotSent();
}

class _PairingClosed implements Exception {
  const _PairingClosed(this.code);

  final int? code;
}
