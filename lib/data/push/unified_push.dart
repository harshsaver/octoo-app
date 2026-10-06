import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unifiedpush/unifiedpush.dart';

import 'local_notifications.dart';
import 'push_service.dart' as octo;

/// Android pushes through UnifiedPush, with ntfy as the distributor: no
/// Google services. The backend encrypts each push for this phone (Web
/// Push); the plugin decrypts it and this shows it as Octo's conversation
/// notification, or an in-app banner while the app is open.
///
/// The "token" registered with October is the JSON
/// `{"endpoint", "p256dh", "auth"}` (saturday `api/lib/_octo/webpush.js`).
class UnifiedPushService implements octo.PushService {
  UnifiedPushService({FlutterLocalNotificationsPlugin? local}) : _local = local ?? FlutterLocalNotificationsPlugin();

  static const tokenKey = 'push.unifiedpush.token';

  /// The person allowed notifications; once a distributor is installed, the
  /// next start registers without asking again.
  static const wantedKey = 'push.unifiedpush.wanted';

  final FlutterLocalNotificationsPlugin _local;
  final _taps = StreamController<octo.PushMessage>.broadcast();
  final _foreground = StreamController<octo.PushMessage>.broadcast();
  final _tokens = StreamController<String>.broadcast();
  bool _needsDistributor = false;

  @override
  bool get available => true;

  /// No UnifiedPush distributor (the ntfy app) is installed: notifications
  /// can't arrive until one is.
  @override
  bool get needsDistributor => _needsDistributor;

  @override
  Future<void> start() async {
    await initializeLocalNotifications(_local, onTap: _taps.add);
    final launch = await _local.getNotificationAppLaunchDetails();
    final cold = launch?.didNotificationLaunchApp == true ? pushFromPayload(launch?.notificationResponse?.payload) : null;
    if (cold != null) scheduleMicrotask(() => _taps.add(cold));
    final registered = await UnifiedPush.initialize(
      onNewEndpoint: (endpoint, _) => unawaited(_saveEndpoint(endpoint)),
      onRegistrationFailed: (reason, _) {},
      onUnregistered: (_) => unawaited(_forget()),
      onMessage: (message, _) => unawaited(_onMessage(message)),
    );
    // Registered before: renew, in case the distributor changed the endpoint.
    if (registered) {
      await UnifiedPush.register();
      return;
    }
    // Allowed before ntfy was installed: pick it up now.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(wantedKey) ?? false) {
      if (await UnifiedPush.tryUseCurrentOrDefaultDistributor()) await UnifiedPush.register();
    }
  }

  @override
  Future<bool> requestPermission() async {
    final allowed = await _local
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
    if (allowed) await (await SharedPreferences.getInstance()).setBool(wantedKey, true);
    final found = await UnifiedPush.tryUseCurrentOrDefaultDistributor();
    _needsDistributor = !found;
    if (found) await UnifiedPush.register();
    return allowed && found;
  }

  @override
  Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(tokenKey);
  }

  @override
  Stream<String> get tokenRefresh => _tokens.stream;

  @override
  Stream<octo.PushMessage> get foreground => _foreground.stream;

  @override
  Stream<octo.PushMessage> get taps => _taps.stream;

  Future<void> _saveEndpoint(PushEndpoint endpoint) async {
    final token = webPushToken(endpoint);
    if (token == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    if (!_tokens.isClosed) _tokens.add(token);
  }

  Future<void> _forget() async => (await SharedPreferences.getInstance()).remove(tokenKey);

  Future<void> _onMessage(PushMessage message) async {
    final push = decodePush(message);
    if (push == null) return;
    // While the app is on screen, a banner; otherwise the notification.
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      if (!_foreground.isClosed) _foreground.add(push);
    } else {
      await showOctoNotification(_local, push);
    }
  }

  @override
  Future<void> dispose() async {
    await _taps.close();
    await _foreground.close();
    await _tokens.close();
  }

  /// Pushes that arrive while the app isn't running: Android starts Dart
  /// with `--unifiedpush-bg` (see main.dart) and this shows them.
  static Future<void> background() async {
    final local = FlutterLocalNotificationsPlugin();
    await initializeLocalNotifications(local);
    await UnifiedPush.initialize(
      onNewEndpoint: (endpoint, _) async {
        final token = webPushToken(endpoint);
        // Registered with October the next time the app opens.
        if (token != null) await (await SharedPreferences.getInstance()).setString(tokenKey, token);
      },
      onMessage: (message, _) async {
        final push = decodePush(message);
        if (push != null) await showOctoNotification(local, push);
      },
    );
  }
}

/// The token October stores for this phone, or null without Web Push keys
/// (a distributor too old to encrypt; the backend would refuse it).
String? webPushToken(PushEndpoint endpoint) {
  final keys = endpoint.pubKeySet;
  if (keys == null) return null;
  String url(String b64) => b64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  return jsonEncode({'endpoint': endpoint.url, 'p256dh': url(keys.pubKey), 'auth': url(keys.auth)});
}

/// The push October sent: JSON with the same fields as an APNs push's data.
octo.PushMessage? decodePush(PushMessage message) {
  if (!message.decrypted) return null;
  try {
    final json = jsonDecode(utf8.decode(message.content));
    return json is Map<String, Object?> ? octo.PushMessage.fromData(json) : null;
  } on FormatException {
    return null;
  }
}
