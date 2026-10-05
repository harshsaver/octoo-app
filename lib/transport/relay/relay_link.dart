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
class RelayLink implements OctoLink {
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
    );
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
        binding = binding.withCredential(value);
        await vault.write(binding);
        await c.sendJson(FrameKind.pairAck, const {});
        await Future.any([active.future, closed]).timeout(const Duration(seconds: 60));
      } on TimeoutException {
        return emit(failed(PairingFailureKind.timedOut));
      } on _PairingClosed catch (e) {
        if (cancelled()) return;
        return emit(
          e.code == RelayClose.hostOffline || e.code == RelayClose.hostDisconnected
              ? failed(PairingFailureKind.offline)
              : failed(PairingFailureKind.reportedByComputer, reason: 'Her computer ended the pairing.'),
        );
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
      paired = true;
      emit(
        PairingPaired(
          PairedComputer(computerId: computerId, hostId: qr.hostId, computerName: hostName, bind: binding.bind),
        ),
      );
    } finally {
      if (!paired) await vault.delete(binding.userId, computerId);
    }
  }

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
        if (binding == null || binding.credential == null) {
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

  /// One `req`; completes with the computer's answer. October's convention:
  /// success is a 2xx status *and* `{"ok": true}` in the body.
  Future<_Reply> _request(_Live live, String method, Map<String, Object?> payload) async {
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
    final reply = await _request(live, familyMethod, message);
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

class _Live {
  _Live(this.connection, this.bind);

  final DeviceConnection connection;
  final String bind;
  final Map<int, Completer<_Reply>> pending = {};
  StreamSubscription<AssembledFrame>? frames;

  void close() {
    unawaited(frames?.cancel());
    connection.close();
    for (final p in pending.values) {
      p.completeError(StateError('the connection closed'));
    }
    pending.clear();
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

class _PairingClosed implements Exception {
  const _PairingClosed(this.code);

  final int? code;
}
