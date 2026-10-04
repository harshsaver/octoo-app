import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Push kinds (brief §9), each with its own switch.
enum NotifyKind { help, todo, consentWaiting, taskEnded, pairing }

/// This phone's preferences. Kept on the phone (not the account database):
/// appearance, the app lock, which notifications to show, and the developer
/// toggle.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.appLock = false,
    this.notify = const {},
    this.showSimulator = false,
  });

  final ThemeMode themeMode;
  final bool appLock;

  /// Off kinds are listed as false; everything else is on.
  final Map<NotifyKind, bool> notify;

  /// Fake mode only: the simulator's debug panel button.
  final bool showSimulator;

  bool notifies(NotifyKind kind) => notify[kind] ?? true;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? appLock,
    Map<NotifyKind, bool>? notify,
    bool? showSimulator,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    appLock: appLock ?? this.appLock,
    notify: notify ?? this.notify,
    showSimulator: showSimulator ?? this.showSimulator,
  );
}

/// Overridden at the root with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('sharedPreferencesProvider must be overridden'),
);

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

class AppSettingsController extends Notifier<AppSettings> {
  static const _theme = 'settings.theme';
  static const _lock = 'settings.appLock';
  static const _simulator = 'settings.showSimulator';
  static String _notifyKey(NotifyKind k) => 'settings.notify.${k.name}';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode:
          ThemeMode.values.asNameMap()[prefs.getString(_theme)] ??
          ThemeMode.system,
      appLock: prefs.getBool(_lock) ?? false,
      notify: {
        for (final k in NotifyKind.values)
          if (prefs.getBool(_notifyKey(k)) case final bool on) k: on,
      },
      showSimulator: prefs.getBool(_simulator) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_theme, mode.name);
  }

  Future<void> setAppLock(bool on) async {
    state = state.copyWith(appLock: on);
    await _prefs.setBool(_lock, on);
  }

  Future<void> setNotify(NotifyKind kind, bool on) async {
    state = state.copyWith(notify: {...state.notify, kind: on});
    await _prefs.setBool(_notifyKey(kind), on);
  }

  Future<void> setShowSimulator(bool on) async {
    state = state.copyWith(showSimulator: on);
    await _prefs.setBool(_simulator, on);
  }
}
