import 'dart:async';
import 'dart:io';

import '../backend/octo_backend.dart';
import 'push_service.dart';

/// Keeps October told which phone to notify (PLAN §3.10): registers on
/// sign-in and on token rotation, and unregisters before sign-out while the
/// access token still works.
class PushRegistrar {
  PushRegistrar({
    required this.push,
    required this.backend,
    required this.deviceLabel,
    required this.appVersion,
    String? platform,
  }) : platform = platform ?? (Platform.isIOS ? 'ios' : 'android');

  final PushService push;
  final OctoBackend backend;
  final String deviceLabel;
  final String? appVersion;
  final String platform;
  String? _registered;
  StreamSubscription<String>? _refresh;

  /// The token registered for this account, if any.
  String? get registeredToken => _registered;

  /// Registers this phone (if push is available) and follows token changes.
  /// Failures are kept quiet; the next start tries again.
  Future<void> register() async {
    final token = await push.token();
    if (token != null) await _send(token);
    _refresh ??= push.tokenRefresh.listen((t) => unawaited(_send(t)));
  }

  Future<void> _send(String token) async {
    try {
      await backend.registerPush(
        token: token,
        platform: platform,
        deviceLabel: deviceLabel,
        appVersion: appVersion,
      );
      _registered = token;
    } on BackendException {
      // Retried on the next start or rotation.
    }
  }

  /// Before signing out: stop notifications to this phone for this account.
  Future<void> unregister() async {
    await _refresh?.cancel();
    _refresh = null;
    final token = _registered ?? await push.token();
    if (token == null) return;
    try {
      await backend.unregisterPush(token);
    } on BackendException {
      // Signing out continues; the server forgets tokens the push service
      // reports dead.
    }
    _registered = null;
  }

  Future<void> dispose() async => _refresh?.cancel();
}
