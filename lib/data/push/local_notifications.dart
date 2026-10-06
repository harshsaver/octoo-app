import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import 'push_service.dart';

/// What every push service shares: the Android channels, showing a push as
/// Octo's conversation notification (respecting this phone's mute and kind
/// switches), and reading a tapped notification back.

PushMessage? pushFromPayload(String? payload) {
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
      final push = pushFromPayload(response.payload);
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
