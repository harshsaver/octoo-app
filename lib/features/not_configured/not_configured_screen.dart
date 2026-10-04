import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/octo_avatar.dart';
import '../../ui/tokens.dart';

/// Shown when the build has no usable configuration (brief §11), or when a
/// release build somehow reaches fake mode. Never falls back to fake.
class NotConfiguredScreen extends StatelessWidget {
  const NotConfiguredScreen({super.key, this.problems = const []});

  /// Developer details; only shown in debug builds.
  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(OctoSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OctoAvatar(size: 120, mood: OctoMood.sleepy),
                const SizedBox(height: OctoSpace.xl),
                Text(
                  l.notConfiguredTitle,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: OctoSpace.md),
                Text(
                  l.notConfiguredBody,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode && problems.isNotEmpty) ...[
                  const SizedBox(height: OctoSpace.xl),
                  for (final p in problems)
                    Text(
                      p,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  Text(
                    'Run with --dart-define-from-file=config/fake.json',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
