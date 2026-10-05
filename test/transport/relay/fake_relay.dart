import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:octo_family/transport/relay/relay_protocol.dart';

/// October's relay in miniature (infra/relay/src/relay-object.ts), on
/// localhost: one host socket per host id, devices by binding, outer frames,
/// connection ids, ACK accounting, and the 1 MiB device backlog rule.
class FakeRelay {
  FakeRelay._(this._server);

  static Future<FakeRelay> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final relay = FakeRelay._(server);
    server.listen(relay._request);
    return relay;
  }

  final HttpServer _server;
  final Map<String, WebSocket> _hosts = {};
  final Map<String, _Device> _devices = {};
  int _nextConnection = 1;

  /// Tickets seen, newest last.
  final List<String> tickets = [];

  /// Device sockets the relay dropped for a backlog over 1 MiB.
  int backlogDrops = 0;

  Uri get uri => Uri.parse('http://127.0.0.1:${_server.port}');

  Future<void> _request(HttpRequest request) async {
    final parts = request.uri.pathSegments;
    final ticket = request.headers.value('sec-websocket-protocol');
    if (ticket != null) tickets.add(ticket);
    if (parts.length == 3 && parts[0] == 'v1' && parts[1] == 'host') {
      final socket = await WebSocketTransformer.upgrade(request, protocolSelector: (p) => p.first);
      _host(parts[2], socket);
    } else if (parts.length == 4 && parts[0] == 'v1' && parts[1] == 'device') {
      final socket = await WebSocketTransformer.upgrade(request, protocolSelector: (p) => p.first);
      _device(parts[2], parts[3], socket);
    } else {
      request.response.statusCode = 404;
      await request.response.close();
    }
  }

  void _host(String hostId, WebSocket socket) {
    unawaited(_hosts[hostId]?.close(RelayClose.replaced));
    _hosts[hostId] = socket;
    socket.listen(
      (message) {
        final bytes = message as Uint8List;
        if (bytes[0] == relayAck) return;
        final frame = decodeOuter(bytes);
        if (frame == null) return;
        final device = _devices[frame.bind];
        if (device == null || device.connectionId != frame.connectionId) return;
        if (frame.type == outerData) {
          device.unacknowledged += frame.payload.length;
          if (device.unacknowledged > deviceUnacknowledgedBytes) {
            backlogDrops++;
            _drop(device, RelayClose.rateLimited);
            return;
          }
          _add(device.socket, Uint8List.fromList(frame.payload));
        } else if (frame.type == outerClose) {
          _devices.remove(frame.bind);
          final code = frame.payload.length == 2 ? (frame.payload[0] << 8) | frame.payload[1] : 4400;
          unawaited(device.socket.close(code));
        }
      },
      onDone: () {
        if (_hosts[hostId] != socket) return;
        _hosts.remove(hostId);
        for (final d in _devices.values.where((d) => d.hostId == hostId).toList()) {
          _devices.remove(d.bind);
          unawaited(d.socket.close(RelayClose.hostDisconnected));
        }
      },
    );
  }

  void _device(String hostId, String bind, WebSocket socket) {
    final host = _hosts[hostId]; // ignore: close_sinks (owned by _hosts)
    if (host == null) {
      unawaited(socket.close(RelayClose.hostOffline));
      return;
    }
    final old = _devices.remove(bind);
    if (old != null) unawaited(old.socket.close(RelayClose.replaced));
    final device = _devices[bind] = _Device(hostId, bind, _nextConnection++, socket);
    final id = ByteData(8)..setUint64(0, device.connectionId);
    socket.add(id.buffer.asUint8List());
    host.add(encodeOuter(outerOpen, bind, device.connectionId));
    socket.listen(
      (message) {
        final bytes = message as Uint8List;
        if (bytes.length == 5 && bytes[0] == relayAck) {
          device.unacknowledged -= ByteData.sublistView(bytes).getUint32(1);
          return;
        }
        if (bytes.length > deviceFrameLimit) {
          _drop(device, RelayClose.frameTooLarge);
          return;
        }
        final host = _hosts[hostId];
        if (host != null) _add(host, encodeOuter(outerData, bind, device.connectionId, bytes));
      },
      onDone: () {
        if (_devices[bind] != device) return;
        _devices.remove(bind);
        final host = _hosts[hostId];
        if (host != null) {
          _add(host, encodeOuter(outerClose, bind, device.connectionId, closeReason(socket.closeCode ?? 1000)));
        }
      },
    );
  }

  void _drop(_Device device, int code) {
    _devices.remove(device.bind);
    unawaited(device.socket.close(code));
    final host = _hosts[device.hostId];
    if (host != null) _add(host, encodeOuter(outerClose, device.bind, device.connectionId, closeReason(code)));
  }

  static void _add(WebSocket socket, Uint8List bytes) {
    if (socket.closeCode == null) {
      try {
        socket.add(bytes);
      } on StateError {
        // closing
      }
    }
  }

  /// The host's socket drops (the computer went away).
  Future<void> dropHost(String hostId) async => _hosts[hostId]?.close(RelayClose.leaseExpired);

  Future<void> close() async {
    for (final h in _hosts.values) {
      await h.close();
    }
    for (final d in _devices.values) {
      await d.socket.close();
    }
    await _server.close(force: true);
  }
}

class _Device {
  _Device(this.hostId, this.bind, this.connectionId, this.socket);

  final String hostId;
  final String bind;
  final int connectionId;
  final WebSocket socket;
  int unacknowledged = 0;
}
