import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'local_notifications.dart';
import 'push_service.dart';

/// iOS pushes straight from Apple (APNs), no Firebase: October's backend
/// sends an alert with content-free text, and the system shows it. The app
/// gets the device token and the taps through a small native bridge
/// (ios/Runner/AppDelegate.swift, channel `dev.october.octo/push`).
class ApnsPushService implements PushService {
  /// [setUpLocal] prepares local notifications (replaced in tests, where
  /// the plugin has no platform side).
  ApnsPushService({MethodChannel? channel, Future<void> Function(void Function(PushMessage) onTap)? setUpLocal})
    : _channel = channel ?? const MethodChannel('dev.october.octo/push'),
      _setUpLocal = setUpLocal ?? ((onTap) => initializeLocalNotifications(FlutterLocalNotificationsPlugin(), onTap: onTap));

  final MethodChannel _channel;
  final Future<void> Function(void Function(PushMessage) onTap) _setUpLocal;
  final _taps = StreamController<PushMessage>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _tokens = StreamController<String>.broadcast();

  @override
  bool get available => true;

  @override
  bool get needsDistributor => false;

  @override
  Future<void> start() async {
    await _setUpLocal(_taps.add);
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments;
      switch (call.method) {
        case 'token' when args is String:
          if (!_tokens.isClosed) _tokens.add(args);
        case 'tap' when args is Map:
          final push = PushMessage.fromData(args.cast<String, Object?>());
          if (push != null && !_taps.isClosed) _taps.add(push);
        case 'foreground' when args is Map:
          final push = PushMessage.fromData(args.cast<String, Object?>());
          if (push != null && !_foreground.isClosed) _foreground.add(push);
      }
    });
    // Taps that launched the app before Dart was listening.
    final pending = await _channel.invokeListMethod<Map<Object?, Object?>>('pendingTaps') ?? const [];
    for (final data in pending) {
      final push = PushMessage.fromData(data.cast<String, Object?>());
      if (push != null) scheduleMicrotask(() => _taps.add(push));
    }
  }

  @override
  Future<bool> requestPermission() async => await _channel.invokeMethod<bool>('requestPermission') ?? false;

  /// The APNs device token (hex), or null until Apple has given one; it
  /// then arrives on [tokenRefresh].
  @override
  Future<String?> token() => _channel.invokeMethod<String>('token');

  @override
  Stream<String> get tokenRefresh => _tokens.stream;

  @override
  Stream<PushMessage> get foreground => _foreground.stream;

  @override
  Stream<PushMessage> get taps => _taps.stream;

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _taps.close();
    await _foreground.close();
    await _tokens.close();
  }
}
