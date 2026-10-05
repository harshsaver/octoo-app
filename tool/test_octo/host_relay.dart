/// The computer side of October's relay, for the test Octo: the host socket,
/// outer frames, one Noise responder per phone, and the pairing and active
/// stages. Ported from october-desktop `src/main/remote-relay-client.ts`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:octo_family/transport/relay/device_connection.dart' show SocketConnector, connectIoSocket;
import 'package:octo_family/transport/relay/frames.dart';
import 'package:octo_family/transport/relay/noise.dart';
import 'package:octo_family/transport/relay/relay_protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// What the host knows about a phone before the handshake: from
/// `mobile_pair_intents` while pairing, `mobile_devices` once active.
class HostBinding {
  const HostBinding({
    required this.bind,
    required this.pairing,
    required this.deviceStatic,
    required this.label,
    this.platform,
    this.intentId,
    this.stateVersion,
    this.deviceSignPub,
  });

  final String bind;
  final bool pairing;
  final Uint8List deviceStatic;
  final String label;
  final String? platform;
  final String? intentId;
  final int? stateVersion;
  final String? deviceSignPub;
}

abstract class HostDelegate {
  Future<HostBinding?> resolveBinding(String bind);

  /// Pairing stage: the handshake finished; [code] is on the phone too.
  void pairReady(HostSession session, String code);

  /// Pairing stage: `pairOffer` or `pairAck`.
  void pairFrame(HostSession session, FrameKind kind, Map<String, Object?> value);

  /// Active stage: the phone's first frame. False closes the session.
  bool authenticate(HostSession session, String credential);

  /// Active stage: a `req`; returns the status and JSON body for its `res`
  /// (October's `CoreResponseEnvelope`: `{apiVersion, requestId, ok, result | error}`).
  Future<({int status, Map<String, Object?> body})> request(HostSession session, Map<String, Object?> envelope);

  /// Active stage: the phone subscribed; events may flow.
  void subscribed(HostSession session);

  void closed(HostSession session);

  void log(String line);
}

/// One phone's connection through the relay.
class HostSession {
  HostSession._(this._host, this.bind, this.connectionId);

  final HostRelay _host;
  final String bind;
  final int connectionId;
  HostBinding? binding;
  NoiseHandshake? _handshake;
  NoiseChannel? _channel;
  final _assembler = FrameAssembler();
  final _ids = MessageIds();
  bool authenticated = false;
  bool subscribed = false;
  bool _closed = false;
  Uint8List? _queued;
  Future<void> _receiving = Future.value();
  Future<void> _sending = Future.value();
  int _cursor = 0;
  DateTime _lastActivity = DateTime.now();

  // The relay drops a phone with more than 1 MiB it hasn't ACKed, and the
  // host can't see those ACKs: a token bucket keeps well under it.
  static const _burst = 256 * 1024;
  static const _bytesPerSecond = 1024 * 1024;
  double _tokens = _burst.toDouble();
  DateTime _refilled = DateTime.now();

  bool get isPairing => binding?.pairing ?? true;
  bool get isOpen => !_closed;

  void _receive(Uint8List payload) {
    _lastActivity = DateTime.now();
    _receiving = _receiving.then((_) => _handle(payload)).catchError((Object e) {
      _host.delegate.log('session $bind failed: $e');
      close(e is NoiseException && e.authentication ? RelayClose.authenticationFailed : RelayClose.sessionEnded);
    });
  }

  Future<void> _handle(Uint8List payload) async {
    if (_closed) return;
    if (binding == null) {
      if (_queued != null) throw const FrameViolation('more than one frame before binding authorization');
      _queued = payload;
      final found = await _host.delegate.resolveBinding(bind).timeout(const Duration(seconds: 5));
      if (found == null || found.bind != bind) throw StateError('binding is not authorized');
      binding = found;
      _handshake = await NoiseHandshake.start(
        initiator: false,
        staticKey: _host.staticKey,
        prologue: channelPrologue(_host.hostId, bind, connectionId),
      );
      payload = _queued!;
    }
    final channel = _channel;
    if (channel == null) {
      final hs = _handshake!;
      await hs.readMessage(payload);
      if (!hs.complete) {
        _host._sendOuter(outerData, bind, connectionId, await hs.writeMessage());
        return;
      }
      pinnedOrThrow(hs.channel.remoteStatic, binding!.deviceStatic);
      _channel = hs.channel;
      if (binding!.pairing) _host.delegate.pairReady(this, pairingCode(hs.channel.handshakeHash));
      return;
    }
    final clear = await channel.receive.decrypt(payload);
    final now = DateTime.now();
    _assembler.expire(now);
    final frame = _assembler.push(clear, now);
    if (frame != null) await _frame(frame);
  }

  Future<void> _frame(AssembledFrame f) async {
    if (f.kind == FrameKind.ping) return _send(FrameKind.pong, const [], f.messageId);
    if (f.kind == FrameKind.pong) return;
    if (binding!.pairing) {
      if (f.kind != FrameKind.pairOffer && f.kind != FrameKind.pairAck) {
        throw const FrameViolation('active frame sent during pairing');
      }
      return _host.delegate.pairFrame(this, f.kind, _json(f.data));
    }
    if (!authenticated) {
      if (f.kind != FrameKind.auth || f.data.length < 32) throw StateError('authentication required');
      if (!_host.delegate.authenticate(this, utf8.decode(f.data))) {
        return close(RelayClose.authenticationFailed);
      }
      authenticated = true;
      return;
    }
    switch (f.kind) {
      case FrameKind.req:
        final envelope = _json(f.data);
        ({int status, Map<String, Object?> body}) reply;
        try {
          reply = await _host.delegate.request(this, envelope);
        } on Object catch (e) {
          _host.delegate.log('request failed: $e');
          reply = (
            status: 500,
            body: {
              'apiVersion': 2,
              'requestId': envelope['requestId'],
              'ok': false,
              'error': {'code': 'INTERNAL', 'message': '$e'},
            },
          );
        }
        final body = utf8.encode(jsonEncode(reply.body));
        await _send(
          FrameKind.res,
          encodeResponse(reply.status, DateTime.now().millisecondsSinceEpoch, body),
          f.messageId,
        );
      case FrameKind.sub:
        subscribed = true;
        _host.delegate.subscribed(this);
      case FrameKind.unsub:
        subscribed = false;
      case FrameKind.cancel:
        break;
      default:
        throw const FrameViolation('forbidden active-session frame');
    }
  }

  /// Sends a pairing frame (`pairCredential`, `pairActive`), as October does
  /// with message id 0.
  Future<void> sendPair(FrameKind kind, Map<String, Object?> value) =>
      _send(kind, utf8.encode(jsonEncode(value)), 0);

  /// Sends one family message as an `ev` line on [topic].
  Future<void> sendEvent(String topic, Map<String, Object?> payload) {
    final line = jsonEncode({
      'apiVersion': 2,
      'cursor': ++_cursor,
      'topic': topic,
      'entityId': bind,
      'generation': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'payload': payload,
    });
    return _send(FrameKind.ev, utf8.encode(line), _ids.take());
  }

  Future<void> _send(FrameKind kind, List<int> data, int messageId) {
    final channel = _channel;
    if (channel == null || _closed) return Future.error(StateError('session not ready'));
    final chunks = encodeFrames(kind, data, messageId);
    final sent = _sending.then((_) async {
      for (final chunk in chunks) {
        await _pace(chunk.length + 16);
        if (_closed) throw StateError('session closed');
        _host._sendOuter(outerData, bind, connectionId, await channel.send.encrypt(chunk));
      }
    });
    _sending = sent.catchError((_) {});
    return sent;
  }

  Future<void> _pace(int bytes) async {
    while (true) {
      final now = DateTime.now();
      _tokens = min(_burst.toDouble(), _tokens + now.difference(_refilled).inMicroseconds * _bytesPerSecond / 1e6);
      _refilled = now;
      if (_tokens >= bytes) {
        _tokens -= bytes;
        return;
      }
      final waitUs = ((bytes - _tokens) / _bytesPerSecond * 1e6).ceil();
      await Future<void>.delayed(Duration(microseconds: waitUs));
    }
  }

  void close([int code = RelayClose.sessionEnded]) {
    if (_closed) return;
    _closed = true;
    _host._sendOuter(outerClose, bind, connectionId, closeReason(code));
    _host._drop(this);
    _host.delegate.closed(this);
  }

  void _disposeFromRelay() {
    if (_closed) return;
    _closed = true;
    _host.delegate.closed(this);
  }

  static Map<String, Object?> _json(Uint8List data) {
    final value = jsonDecode(utf8.decode(data));
    if (value is! Map<String, Object?>) throw const FormatException('expected a JSON object');
    return value;
  }
}

/// The host socket, reconnecting with October's backoff. The relay ends the
/// socket about every five minutes (4407, the ticket lease); that is normal.
class HostRelay {
  HostRelay({
    required this.relay,
    required this.hostId,
    required this.staticKey,
    required this.ticket,
    required this.delegate,
    this.connector = connectIoSocket,
  });

  final Uri relay;
  final String hostId;
  final NoiseKeyPair staticKey;

  /// A fresh `ticket-host` ticket.
  final Future<String> Function() ticket;
  final HostDelegate delegate;
  final SocketConnector connector;

  final Map<String, HostSession> sessions = {};
  WebSocketChannel? _socket;
  bool _stopped = false;
  int _attempt = 0;
  Timer? _retry;
  Timer? _idle;
  final _connected = StreamController<bool>.broadcast();

  /// True when the host socket opens, false when it drops.
  Stream<bool> get connectedChanges => _connected.stream;

  bool get connected => _socket != null;

  Future<void> start() async {
    _stopped = false;
    _idle ??= Timer.periodic(const Duration(seconds: 10), (_) {
      final cutoff = DateTime.now().subtract(const Duration(seconds: 60));
      for (final s in sessions.values.toList()) {
        if (s._lastActivity.isBefore(cutoff)) s.close();
      }
    });
    await _connect();
  }

  Future<void> _connect() async {
    if (_stopped) return;
    try {
      final t = await ticket();
      final uri = relay.replace(scheme: relay.scheme == 'http' ? 'ws' : 'wss', path: '/v1/host/$hostId');
      final socket = _socket = await connector(uri, ['october-ticket.$t']);
      _attempt = 0;
      _connected.add(true);
      delegate.log('relay connected');
      socket.stream.listen(
        (message) {
          if (message is! List<int>) return;
          final bytes = message is Uint8List ? message : Uint8List.fromList(message);
          final frame = decodeOuter(bytes);
          if (frame == null) return;
          socket.sink.add(hostAck(frame.connectionId, bytes.length));
          _outer(frame);
        },
        onDone: () => _dropped(socket, socket.closeCode),
        onError: (Object _) => _dropped(socket, null),
        cancelOnError: true,
      );
    } on Object catch (e) {
      delegate.log('relay connect failed: $e');
      _schedule();
    }
  }

  void _outer(OuterFrame frame) {
    final existing = sessions[frame.bind];
    switch (frame.type) {
      case outerOpen:
        existing?._disposeFromRelay();
        sessions[frame.bind] = HostSession._(this, frame.bind, frame.connectionId);
      case outerClose:
        if (existing != null && existing.connectionId == frame.connectionId) {
          sessions.remove(frame.bind);
          existing._disposeFromRelay();
        }
      case outerData:
        if (existing != null && existing.connectionId == frame.connectionId) {
          existing._receive(Uint8List.fromList(frame.payload));
        }
    }
  }

  void _dropped(WebSocketChannel socket, int? code) {
    if (_socket != socket) return;
    _socket = null;
    _connected.add(false);
    for (final s in sessions.values) {
      s._disposeFromRelay();
    }
    sessions.clear();
    delegate.log('relay closed ($code)${code == RelayClose.leaseExpired ? ' — lease renewal, reconnecting' : ''}');
    if (code == RelayClose.replaced) {
      delegate.log('another copy of this host connected; stopping');
      return;
    }
    if (code == RelayClose.leaseExpired) {
      _attempt = 0;
      unawaited(_connect());
      return;
    }
    _schedule();
  }

  void _schedule() {
    if (_stopped || _retry != null) return;
    final delay = relayRetryDelay(_attempt++);
    _retry = Timer(delay, () {
      _retry = null;
      unawaited(_connect());
    });
  }

  void _sendOuter(int type, String bind, int connectionId, List<int> payload) {
    _socket?.sink.add(encodeOuter(type, bind, connectionId, payload));
  }

  void _drop(HostSession session) {
    if (sessions[session.bind] == session) sessions.remove(session.bind);
  }

  Future<void> stop() async {
    _stopped = true;
    _retry?.cancel();
    _idle?.cancel();
    _idle = null;
    for (final s in sessions.values.toList()) {
      s.close();
    }
    await _socket?.sink.close(1000);
    _socket = null;
  }
}
