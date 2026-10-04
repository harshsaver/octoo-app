import 'dart:async';
import 'dart:convert';

import 'package:octo_family/transport/octo_link.dart';

/// An [OctoLink] a test drives by hand: it records what the app sends and
/// delivers whatever the test pushes.
class ScriptedLink implements OctoLink {
  final sent = <Map<String, Object?>>[];
  final _messages = StreamController<Map<String, Object?>>.broadcast(
    sync: true,
  );
  StreamController<LinkState>? _states;
  bool connected = false;

  /// Called for each sent message; may push replies.
  void Function(Map<String, Object?> message)? onSend;

  /// When set, `send` throws this.
  Object? sendError;

  void goOnline() {
    connected = true;
    _states?.add(LinkState.connected);
  }

  void goOffline() {
    connected = false;
    _states?.add(LinkState.offline);
  }

  void push(Map<String, Object?> message) =>
      _messages.add(jsonDecode(jsonEncode(message)) as Map<String, Object?>);

  List<Map<String, Object?>> sentOfType(String type) => [
    for (final m in sent)
      if (m['type'] == type) m,
  ];

  @override
  Stream<LinkState> connect(String computerId) {
    _states = StreamController<LinkState>(
      onListen: () =>
          _states!.add(connected ? LinkState.connected : LinkState.offline),
    );
    return _states!.stream;
  }

  @override
  Stream<Map<String, Object?>> messages(String computerId) => _messages.stream;

  @override
  Future<void> send(String computerId, Map<String, Object?> message) async {
    if (!connected) throw LinkUnavailableException(computerId);
    if (sendError != null) throw sendError!;
    sent.add(message);
    onSend?.call(message);
  }

  @override
  Stream<PairingProgress> pair(
    String qrPayloadOrCode, {
    required String helperName,
    required String deviceLabel,
  }) => const Stream.empty();

  @override
  Future<void> unpair(String computerId) async {}
}
