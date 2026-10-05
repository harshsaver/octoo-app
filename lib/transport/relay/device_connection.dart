import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'frames.dart';
import 'noise.dart';
import 'relay_protocol.dart';

/// Opens a WebSocket (replaced in tests).
typedef SocketConnector = Future<WebSocketChannel> Function(Uri uri, List<String> protocols);

Future<WebSocketChannel> connectIoSocket(Uri uri, List<String> protocols) async {
  final channel = IOWebSocketChannel.connect(uri, protocols: protocols);
  await channel.ready;
  return channel;
}

/// `wss://relay…/v1/device/{hostId}/{bind}`.
Uri deviceSocketUri(Uri relay, String hostId, String bind) => relay.replace(
  scheme: relay.scheme == 'http' ? 'ws' : 'wss',
  path: '/v1/device/$hostId/$bind',
);

/// One phone-side relay connection, ported from october-desktop
/// `mobile/src/october/relay.ts` `RelaySession`: the 8-byte connection id,
/// the Noise XX handshake as initiator with her computer's key pinned, then
/// framed messages. Every received WebSocket message is ACKed, pings go out
/// every 25 s and her computer's pings are answered.
class DeviceConnection {
  DeviceConnection._(this._socket, this._pingEvery);

  final WebSocketChannel _socket;
  final Duration _pingEvery;
  final _assembler = FrameAssembler();
  final _ids = MessageIds();
  final _frames = StreamController<AssembledFrame>.broadcast(sync: true);
  final _done = Completer<int?>();
  final _ready = Completer<void>();
  NoiseHandshake? _handshake;
  NoiseChannel? _channel;
  int? _connectionId;
  Timer? _ping;
  Future<void> _receiving = Future.value();
  Future<void> _sending = Future.value();

  /// Connects and completes the handshake. Throws on timeout, a refused
  /// socket, or a key that isn't [hostStatic].
  static Future<DeviceConnection> open({
    required Uri relay,
    required String hostId,
    required String bind,
    required String ticket,
    required NoiseKeyPair deviceStatic,
    required Uint8List hostStatic,
    SocketConnector connector = connectIoSocket,
    Duration timeout = const Duration(seconds: 15),
    Duration pingEvery = const Duration(seconds: 25),
  }) async {
    final socket = await connector(deviceSocketUri(relay, hostId, bind), ['october-ticket.$ticket']).timeout(timeout);
    final c = DeviceConnection._(socket, pingEvery);
    c._listen(hostId, bind, deviceStatic, hostStatic);
    try {
      await c._ready.future.timeout(timeout);
    } on Object {
      c.close();
      rethrow;
    }
    return c;
  }

  /// The six digits both screens show.
  String get pairingCode => pairingCodeFor(_channel!.handshakeHash);

  /// Every assembled frame except pings.
  Stream<AssembledFrame> get frames => _frames.stream;

  /// Completes with the close code when the connection ends.
  Future<int?> get done => _done.future;

  bool get isOpen => !_done.isCompleted && _channel != null;

  void _listen(String hostId, String bind, NoiseKeyPair deviceStatic, Uint8List hostStatic) {
    _socket.stream.listen(
      (message) {
        if (message is! List<int>) return _fail(const FrameViolation('relay sent a non-binary frame'));
        final bytes = message is Uint8List ? message : Uint8List.fromList(message);
        _receiving = _receiving.then((_) async {
          if (_done.isCompleted) return;
          await _receive(bytes, hostId, bind, deviceStatic, hostStatic);
          if (!_done.isCompleted) _socket.sink.add(deviceAck(bytes.length));
        }).catchError(_fail);
      },
      // Messages already received (a last "removed") are handled first.
      onDone: () => _receiving.whenComplete(() => _finish(_socket.closeCode)),
      onError: (Object e) => _fail(e),
      cancelOnError: true,
    );
  }

  Future<void> _receive(
    Uint8List bytes,
    String hostId,
    String bind,
    NoiseKeyPair deviceStatic,
    Uint8List hostStatic,
  ) async {
    if (_connectionId == null) {
      if (bytes.length != 8) throw const FrameViolation('relay connection identity is invalid');
      _connectionId = ByteData.sublistView(bytes).getUint64(0);
      final hs = _handshake = await NoiseHandshake.start(
        initiator: true,
        staticKey: deviceStatic,
        prologue: channelPrologue(hostId, bind, _connectionId!),
      );
      _socket.sink.add(await hs.writeMessage());
      return;
    }
    final channel = _channel;
    if (channel == null) {
      final hs = _handshake!;
      await hs.readMessage(bytes);
      if (!hs.complete) _socket.sink.add(await hs.writeMessage());
      if (hs.complete) {
        pinnedOrThrow(hs.channel.remoteStatic, hostStatic);
        _channel = hs.channel;
        _ping = Timer.periodic(_pingEvery, (_) => _keepAlive());
        if (!_ready.isCompleted) _ready.complete();
      }
      return;
    }
    final clear = await channel.receive.decrypt(bytes);
    final now = DateTime.now();
    _assembler.expire(now);
    final frame = _assembler.push(clear, now);
    if (frame == null) return;
    if (frame.kind == FrameKind.ping) {
      unawaited(_send(FrameKind.pong, const [], frame.messageId));
      return;
    }
    if (frame.kind == FrameKind.pong) return;
    _frames.add(frame);
  }

  void _keepAlive() {
    try {
      _assembler.expire(DateTime.now());
      unawaited(_send(FrameKind.ping, const [], _ids.take()));
    } on Object catch (e) {
      _fail(e);
    }
  }

  /// Sends one message; returns its id. Throws [StateError] when closed.
  Future<int> send(FrameKind kind, List<int> data) async {
    final id = _ids.take();
    await _send(kind, data, id);
    return id;
  }

  /// An id for [sendWithId], so a reply can be awaited before it's sent.
  int newMessageId() => _ids.take();

  Future<void> sendWithId(FrameKind kind, List<int> data, int messageId) => _send(kind, data, messageId);

  Future<int> sendJson(FrameKind kind, Object? value) => send(kind, utf8.encode(jsonEncode(value ?? const {})));

  Future<void> _send(FrameKind kind, List<int> data, int messageId) {
    final channel = _channel;
    if (channel == null || _done.isCompleted) {
      return Future.error(StateError('The secure channel is not connected.'));
    }
    final chunks = encodeFrames(kind, data, messageId);
    // In order: each chunk's nonce must match the order the relay sees.
    final sent = _sending.then((_) async {
      for (final chunk in chunks) {
        final sealed = await channel.send.encrypt(chunk);
        if (_done.isCompleted) throw StateError('The secure channel closed.');
        _socket.sink.add(sealed);
      }
    });
    _sending = sent.catchError((_) {});
    return sent;
  }

  void _fail(Object error) {
    if (!_ready.isCompleted) _ready.completeError(error);
    final code = error is FrameViolation || (error is NoiseException) ? 1003 : 1011;
    _finish(code);
    unawaited(_socket.sink.close(code));
  }

  void _finish(int? code) {
    _ping?.cancel();
    if (!_ready.isCompleted) _ready.completeError(StateError('The relay closed the connection ($code).'));
    if (!_done.isCompleted) _done.complete(code);
    if (!_frames.isClosed) unawaited(_frames.close());
  }

  void close([int code = 1000]) {
    _finish(code);
    unawaited(_socket.sink.close(code));
  }
}

String pairingCodeFor(Uint8List handshakeHash) => pairingCode(handshakeHash);
