import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_settings.dart';
import '../../app/providers.dart';
import '../../data/backend/octo_backend.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/grouped_list.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../lock/app_lock.dart';

final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// App settings (brief §5.5): account, appearance, app lock, notifications,
/// about, and — in fake mode — the developer toggle.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);
    final account = ref.watch(accountProvider);
    final isFake = ref.watch(appConfigProvider).isFake;
    final version = ref.watch(packageInfoProvider).value;

    Future<void> toggleLock(bool on) async {
      final auth = ref.read(deviceAuthProvider);
      if (on) {
        if (!await auth.isAvailable()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.appLockUnavailable)));
          }
          return;
        }
        if (!context.mounted || !await auth.authenticate(l.unlockReason)) {
          return;
        }
      }
      await controller.setAppLock(on);
    }

    String notifyLabel(NotifyKind k) => switch (k) {
      NotifyKind.help => l.notifyHelp,
      NotifyKind.todo => l.notifyTodo,
      NotifyKind.consentWaiting => l.notifyConsent,
      NotifyKind.taskEnded => l.notifyTaskEnded,
      NotifyKind.pairing => l.notifyPairing,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: OctoSpace.xxl),
        children: [
          GroupedSection(
            title: l.account,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.accentText,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(account.name.characters.first),
                ),
                title: Text(account.name),
                subtitle: isFake ? Text(l.accountFake) : null,
              ),
            ],
          ),
          GroupedSection(
            title: l.appearance,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: OctoSpace.lg),
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l.themeDark),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => controller.setThemeMode(s.single),
                ),
              ),
            ],
          ),
          GroupedSection(
            children: [
              SwitchListTile(
                title: Text(l.appLock),
                subtitle: Text(l.appLockDetail),
                value: settings.appLock,
                onChanged: toggleLock,
              ),
            ],
          ),
          GroupedSection(
            title: l.notifications,
            footer: l.notificationsLater,
            children: [
              for (final k in NotifyKind.values)
                SwitchListTile(
                  title: Text(notifyLabel(k)),
                  value: settings.notifies(k),
                  onChanged: (on) async {
                    try {
                      await controller.setNotify(k, on);
                    } on BackendException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                ),
            ],
          ),
          GroupedSection(
            title: l.about,
            children: [
              if (version != null)
                ListTile(
                  title: Text(
                    l.versionLabel(
                      '${version.version} (${version.buildNumber})',
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: OctoSpace.lg),
                child: Text(
                  l.aboutBody,
                  style: TextStyle(color: colors.secondaryLabel),
                ),
              ),
            ],
          ),
          if (isFake)
            GroupedSection(
              title: l.developer,
              children: [
                SwitchListTile(
                  title: Text(l.showSimulator),
                  value: settings.showSimulator,
                  onChanged: controller.setShowSimulator,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
