import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import 'push_service.dart';

/// Push through Firebase Cloud Messaging (Android) and APNs via FCM (iOS).
///
/// - iOS: the server sends an alert with content-free text and
///   `mutable-content`; the system shows it (the notification extension adds
///   the Octo's picture). In the foreground the app shows its own banner.
/// - Android: the server sends data only; [showOctoNotification] displays it
///   on the kind's channel, unless this phone muted that computer or turned
///   the kind off.
/// - Every tap (cold start, background, local) goes through [taps].
class FirebasePush implements PushService {
  @override
  bool get available => true;

  final _local = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<PushMessage>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];

  @override
  Future<void> start() async {
    await initializeLocalNotifications(_local, onTap: _taps.add);
    final messaging = FirebaseMessaging.instance;
    // iOS: no system alert while the app is open; the in-app banner shows it.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
    _subs
      ..add(
        FirebaseMessaging.onMessage.listen((m) {
          final push = PushMessage.fromData(m.data);
          if (push != null) _foreground.add(push);
        }),
      )
      ..add(
        FirebaseMessaging.onMessageOpenedApp.listen((m) {
          final push = PushMessage.fromData(m.data);
          if (push != null) _taps.add(push);
        }),
      );
    final initial = await messaging.getInitialMessage();
    final cold = initial == null ? null : PushMessage.fromData(initial.data);
    if (cold != null) scheduleMicrotask(() => _taps.add(cold));
    final launch = await _local.getNotificationAppLaunchDetails();
    final payload = launch?.didNotificationLaunchApp == true
        ? launch?.notificationResponse?.payload
        : null;
    final local = _fromPayload(payload);
    if (local != null) scheduleMicrotask(() => _taps.add(local));
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() async {
    try {
      if (Platform.isIOS &&
          await FirebaseMessaging.instance.getAPNSToken() == null) {
        return null;
      }
      return await FirebaseMessaging.instance.getToken();
    } on FirebaseException {
      return null;
    }
  }

  @override
  Stream<String> get tokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<PushMessage> get foreground => _foreground.stream;

  @override
  Stream<PushMessage> get taps => _taps.stream;

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _taps.close();
    await _foreground.close();
  }
}

PushMessage? _fromPayload(String? payload) {
  if (payload == null) return null;
  try {
    return PushMessage.fromData(jsonDecode(payload) as Map<String, Object?>);
  } on Object {
    return null;
  }
}

/// SharedPreferences keys the app keeps in step for the background isolate.
abstract final class PushPrefsKeys {
  /// Computer ids this person muted.
  static const muted = 'push.mutedComputers';

  /// The same per-kind switches as Settings.
  static String kind(String kind) => 'settings.notify.$kind';
}

/// One Android channel per kind, so people can silence "A task finishes"
/// and keep "needs a hand" (brief §9).
Future<void> initializeLocalNotifications(
  FlutterLocalNotificationsPlugin plugin, {
  void Function(PushMessage tap)? onTap,
}) async {
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
    onDidReceiveNotificationResponse: (response) {
      final push = _fromPayload(response.payload);
      if (push != null) onTap?.call(push);
    },
  );
  if (!Platform.isAndroid) return;
  final l = lookupAppLocalizations(
    WidgetsBinding.instance.platformDispatcher.locale,
  );
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  for (final kind in pushKinds) {
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        kind,
        _channelName(l, kind),
        importance: kind == 'help' || kind == 'consentWaiting'
            ? Importance.high
            : Importance.defaultImportance,
      ),
    );
  }
}

String _channelName(AppLocalizations l, String kind) => switch (kind) {
  'help' => l.notifyHelp,
  'todo' => l.notifyTodo,
  'consentWaiting' => l.notifyConsent,
  'taskEnded' => l.notifyTaskEnded,
  _ => l.notifyPairing,
};

/// Android: shows a data-only push as a conversation from that computer's
/// Octo, on the kind's channel. Respects this phone's mute and kind switches.
Future<void> showOctoNotification(
  FlutterLocalNotificationsPlugin plugin,
  PushMessage push,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  if (prefs.getStringList(PushPrefsKeys.muted)?.contains(push.computerId) ??
      false) {
    return;
  }
  if (prefs.getBool(PushPrefsKeys.kind(push.kind)) == false) return;
  final l = lookupAppLocalizations(
    WidgetsBinding.instance.platformDispatcher.locale,
  );
  final octo = Person(name: l.octoName, key: push.computerId, bot: true);
  final title = push.title ?? l.appTitle;
  await plugin.show(
    id: push.computerId.hashCode ^ push.kind.hashCode,
    title: title,
    body: push.body,
    payload: jsonEncode(push.toData()),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        push.kind,
        _channelName(l, push.kind),
        category: AndroidNotificationCategory.message,
        shortcutId: push.computerId,
        styleInformation: MessagingStyleInformation(
          octo,
          conversationTitle: title,
          messages: [Message(push.body ?? title, DateTime.now(), octo)],
        ),
      ),
    ),
  );
}

/// FCM's background entry point (Android data-only pushes).
@pragma('vm:entry-point')
Future<void> octoBackgroundMessage(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final push = PushMessage.fromData(message.data);
  if (push == null || !Platform.isAndroid) return;
  final plugin = FlutterLocalNotificationsPlugin();
  await initializeLocalNotifications(plugin);
  await showOctoNotification(plugin, push);
}
