import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../features/not_configured/not_configured_screen.dart';
import '../l10n/app_localizations.dart';
import '../ui/theme.dart';
import '../data/account_scope.dart';
import '../data/db/database.dart';
import '../data/push/local_notifications.dart' show PushPrefsKeys;
import '../data/push/push_service.dart';
import '../data/sign_out.dart';
import '../features/lock/app_lock.dart';
import '../features/welcome/welcome_screen.dart';
import 'app_settings.dart';
import 'config.dart';
import 'providers.dart';
import 'router.dart';

/// The root widget for a [ConfigResult]: the app for a usable config (fake
/// mode with the simulator; real mode with October sign-in and the backend),
/// otherwise "This build isn't configured". Never falls back to fake.
Widget buildApp(
  ConfigResult result, {
  required AppRoots roots,
  List<Override> overrides = const [],
}) => switch (result) {
  ConfigOk(:final config) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      appRootsProvider.overrideWithValue(roots),
      ...overrides,
    ],
    child: const OctoApp(),
  ),
  ConfigProblem(:final problems) => _Unconfigured(problems),
};

class OctoApp extends ConsumerStatefulWidget {
  const OctoApp({super.key});

  @override
  ConsumerState<OctoApp> createState() => _OctoAppState();
}

class _OctoAppState extends ConsumerState<OctoApp> {
  late final AuthRefresh _refresh = AuthRefresh(ref.read(authServiceProvider));
  late final GoRouter _router = buildRouter(
    ref.read(authServiceProvider),
    _refresh,
  );
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final AppLifecycleListener _lifecycle;
  final _subs = <StreamSubscription<Object?>>[];

  bool get _signedIn => ref.read(signedInAccountProvider) != null;

  @override
  void initState() {
    super.initState();
    // Sessions connect while the app is in the foreground (PLAN §3.3).
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_signedIn) ref.read(sessionsControllerProvider).resume();
      },
      onPause: () {
        if (_signedIn) ref.read(sessionsControllerProvider).pause();
      },
    );
    final push = ref.read(pushServiceProvider);
    _subs
      ..add(push.taps.listen(_openFromPush))
      ..add(push.foreground.listen(_banner));
    unawaited(push.start());
    unawaited(wipePending(ref.read(sharedPreferencesProvider)));
    if (_signedIn) unawaited(ref.read(pushRegistrarProvider).register());
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _lifecycle.dispose();
    _router.dispose();
    _refresh.dispose();
    super.dispose();
  }

  /// One handler for every tap (PLAN §3.10): signed in → the app lock
  /// covers everything → that Octo's thread, or the list if it's unknown.
  void _openFromPush(PushMessage push) {
    if (!_signedIn) return;
    final known =
        ref
            .read(computersProvider)
            .value
            ?.any((c) => c.id == push.computerId) ??
        false;
    _router.go(known ? '/octo/${push.computerId}' : '/');
  }

  /// A push while the app is open: an in-app banner (not a system alert),
  /// unless this phone muted that computer or switched the kind off.
  void _banner(PushMessage push) {
    if (!_signedIn) return;
    final computer = ref
        .read(computersProvider)
        .value
        ?.where((c) => c.id == push.computerId)
        .firstOrNull;
    if (computer == null || computer.muted) return;
    final kind = NotifyKind.values
        .where((k) => k.name == push.kind)
        .firstOrNull;
    if (kind != null && !ref.read(appSettingsProvider).notifies(kind)) return;
    final context = _messenger.currentContext;
    final text = push.title ?? computer.person;
    _messenger.currentState?.showSnackBar(
      SnackBar(
        content: Text(text),
        action: context == null
            ? null
            : SnackBarAction(
                label: AppLocalizations.of(context).pushOpen,
                onPressed: () => _openFromPush(push),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(signedInAccountProvider);
    if (account != null) {
      ref.watch(sessionsStartupProvider);
      // Android shows pushes from a background isolate: it reads mutes here.
      ref.listen(computersProvider, (_, rows) {
        final muted = [
          for (final c in rows.value ?? const <ComputerRow>[])
            if (c.muted) c.id,
        ];
        unawaited(
          ref
              .read(sharedPreferencesProvider)
              .setStringList(PushPrefsKeys.muted, muted),
        );
      });
    }
    ref.listen(signedInAccountProvider, (before, now) {
      if (now != null && before?.userId != now.userId) {
        unawaited(ref.read(pushRegistrarProvider).register());
      }
    });
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: octoLightTheme(),
      darkTheme: octoDarkTheme(),
      themeMode: ref.watch(appSettingsProvider.select((s) => s.themeMode)),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scaffoldMessengerKey: _messenger,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      // Signed out, nothing that belongs to an account is mounted: only the
      // welcome screen (the router's redirect follows).
      builder: (context, child) => account == null
          ? const _SignedOut()
          : AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) => Navigator(
    onGenerateRoute: (_) =>
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
  );
}

class _Unconfigured extends StatelessWidget {
  const _Unconfigured(this.problems);

  final List<String> problems;

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: octoLightTheme(),
    darkTheme: octoDarkTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: NotConfiguredScreen(problems: problems),
    debugShowCheckedModeBanner: false,
  );
}
