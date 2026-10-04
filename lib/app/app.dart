import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../features/not_configured/not_configured_screen.dart';
import '../l10n/app_localizations.dart';
import '../ui/theme.dart';
import '../data/account_scope.dart';
import 'config.dart';
import 'providers.dart';
import 'router.dart';

/// The root widget for a [ConfigResult]. Anything other than a usable
/// fake-mode config shows "This build isn't configured"; real mode joins
/// when sign-in and the relay land (stages 4 and 5).
Widget buildApp(
  ConfigResult result, {
  required AccountDirs dirs,
  List<Override> overrides = const [],
}) => switch (result) {
  ConfigOk(:final config) when config.isFake => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      accountDirsProvider.overrideWithValue(dirs),
      ...overrides,
    ],
    child: const OctoApp(),
  ),
  ConfigOk() => const _Unconfigured([
    'real mode is not built yet (stages 4 and 5)',
  ]),
  ConfigProblem(:final problems) => _Unconfigured(problems),
};

class OctoApp extends ConsumerStatefulWidget {
  const OctoApp({super.key});

  @override
  ConsumerState<OctoApp> createState() => _OctoAppState();
}

class _OctoAppState extends ConsumerState<OctoApp> {
  late final GoRouter _router = buildRouter();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Sessions connect while the app is in the foreground (PLAN §3.3).
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(sessionsControllerProvider).resume(),
      onPause: () => ref.read(sessionsControllerProvider).pause(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionsStartupProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: octoLightTheme(),
      darkTheme: octoDarkTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
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
