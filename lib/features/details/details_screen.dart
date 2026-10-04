import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../data/backend/octo_backend.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/grouped_list.dart';
import '../../ui/languages.dart';
import '../../ui/look_picker.dart';
import '../../ui/octo_avatar.dart';
import '../../ui/octo_looks.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

/// This month, for [computerId] (`GET /api/octo/usage`).
final usageProvider = FutureProvider.family<Usage, String>((ref, computerId) {
  final now = clock.now();
  final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  return ref.watch(backendProvider).usage(computerId, month);
});

/// The contact-details sheet for one Octo (brief §5.5).
class DetailsScreen extends ConsumerWidget {
  const DetailsScreen({super.key, required this.computerId});

  final String computerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final theme = Theme.of(context);
    final computer = ref.watch(computerProvider(computerId));
    final data = ref.watch(sessionDataProvider(computerId)).value;
    if (computer == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final person = computer.person;
    final me = ref.watch(accountProvider).name;
    final family = data?.status?.family ?? const [];
    final usage = ref.watch(usageProvider(computerId));
    final syncOwed = computer.profileGen > computer.profileSyncedGen;

    Future<void> edit({
      String? person,
      String? computerName,
      String? language,
      String? look,
    }) async {
      try {
        await ref
            .read(profileSyncProvider)
            .edit(
              computerId,
              person: person,
              computerName: computerName,
              language: language,
              look: look,
            );
      } on BackendException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }

    Widget value(String text) => Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(color: colors.secondaryLabel),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.detailsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: OctoSpace.xxl),
        children: [
          const SizedBox(height: OctoSpace.md),
          Center(
            child: OctoAvatar(
              look: OctoLook.fromId(computer.look),
              size: 104,
              semanticLabel: person,
            ),
          ),
          const SizedBox(height: OctoSpace.md),
          Text(
            person,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          Text(
            computer.computerName,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.secondaryLabel),
          ),
          Center(
            child: TextButton(
              onPressed: () async {
                final look = await _pickLook(
                  context,
                  OctoLook.fromId(computer.look),
                );
                if (look != null) await edit(look: look.id);
              },
              child: Text(l.changeOcto),
            ),
          ),
          GroupedSection(
            footer: syncOwed ? l.syncPending(person) : null,
            children: [
              ListTile(
                title: Text(l.nameLabel),
                trailing: value(person),
                onTap: () async {
                  final name = await _askText(context, l.rename, person);
                  if (name != null) await edit(person: name);
                },
              ),
              ListTile(
                title: Text(l.computerNameLabel),
                trailing: value(computer.computerName),
                onTap: () async {
                  final name = await _askText(
                    context,
                    l.rename,
                    computer.computerName,
                  );
                  if (name != null) await edit(computerName: name);
                },
              ),
              ListTile(
                title: Text(l.languageLabel),
                trailing: value(languageName(computer.language)),
                onTap: () async {
                  final code = await _pickLanguage(context, computer.language);
                  if (code != null) await edit(language: code);
                },
              ),
            ],
          ),
          GroupedSection(
            children: [
              ListTile(
                leading: const Icon(Icons.rule),
                title: Text(l.rules),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/octo/$computerId/details/rules'),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(l.activity),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/octo/$computerId/details/activity'),
              ),
            ],
          ),
          GroupedSection(
            title: l.helpers,
            footer: family.isEmpty ? l.helpersEmpty : null,
            children: [
              for (final m in family)
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(m.name == me ? l.youSuffix(m.name) : m.name),
                  subtitle: m.device == null ? null : Text(m.device!),
                ),
            ],
          ),
          GroupedSection(
            title: l.thisMonth,
            children: [
              ...usage.when(
                data: (u) => [
                  ListTile(
                    title: Text(l.usageTasks),
                    trailing: value('${u.tasks}'),
                  ),
                  ListTile(
                    title: Text(l.usageQuestions),
                    trailing: value('${u.questions}'),
                  ),
                  ListTile(title: Text(l.usageCost), trailing: value(u.cost)),
                ],
                loading: () => [
                  const ListTile(title: LinearProgressIndicator()),
                ],
                error: (_, _) => [ListTile(title: Text(l.usageUnavailable))],
              ),
            ],
          ),
          GroupedSection(
            children: [
              SwitchListTile(
                title: Text(l.muteNotifications),
                value: computer.muted,
                onChanged: (on) => ref
                    .read(databaseProvider)
                    .updateComputer(
                      computerId,
                      ComputersCompanion(muted: Value(on)),
                    ),
              ),
            ],
          ),
          GroupedSection(
            children: [
              ListTile(
                title: Text(
                  l.removeOcto,
                  style: TextStyle(color: colors.needsYou),
                ),
                onTap: () => _confirmRemove(context, ref, computer),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    ComputerRow c,
  ) async {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final owner = c.role == 'owner';
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OctoSpace.xl,
            0,
            OctoSpace.xl,
            OctoSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.removeTitle(c.person),
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
              const SizedBox(height: OctoSpace.sm),
              Text(
                owner
                    ? l.removeBodyOwner(c.computerName)
                    : l.removeBodyHelper(c.computerName),
              ),
              const SizedBox(height: OctoSpace.xl),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.needsYou,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(sheet, true),
                child: Text(owner ? l.removeForEveryone : l.removeFromPhone),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheet, false),
                child: Text(l.cancel),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(sessionsControllerProvider).remove(c.id);
      if (context.mounted) context.go('/');
    } on BackendException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.removeFailed(e.message))));
      }
    }
  }
}

Future<String?> _askText(
  BuildContext context,
  String title,
  String initial,
) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => _TextPrompt(title: title, initial: initial),
  );
  final value = result?.trim();
  return value == null || value.isEmpty || value == initial ? null : value;
}

/// Owns its controller, so it lives as long as the dialog (including its
/// closing animation).
class _TextPrompt extends StatefulWidget {
  const _TextPrompt({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l.save),
        ),
      ],
    );
  }
}

Future<String?> _pickLanguage(BuildContext context, String? current) =>
    showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OctoSpace.lg,
            0,
            OctoSpace.lg,
            OctoSpace.lg,
          ),
          child: Wrap(
            spacing: OctoSpace.sm,
            runSpacing: OctoSpace.sm,
            children: [
              for (final (code, name) in octoLanguages)
                ChoiceChip(
                  label: Text(name),
                  selected: code == current,
                  onSelected: (_) =>
                      Navigator.pop(sheet, code == current ? null : code),
                ),
            ],
          ),
        ),
      ),
    );

Future<OctoLook?> _pickLook(
  BuildContext context,
  OctoLook current,
) => showModalBottomSheet<OctoLook>(
  context: context,
  showDragHandle: true,
  builder: (sheet) {
    var selected = current;
    final l = AppLocalizations.of(sheet);
    return StatefulBuilder(
      builder: (context, setSheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OctoSpace.xl,
            0,
            OctoSpace.xl,
            OctoSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.changeOcto, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: OctoSpace.lg),
              Center(child: OctoAvatar(look: selected, size: 104)),
              const SizedBox(height: OctoSpace.lg),
              LookPicker(
                selected: selected,
                onChanged: (look) => setSheet(() => selected = look),
              ),
              const SizedBox(height: OctoSpace.xl),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(sheet, selected == current ? null : selected),
                child: Text(l.save),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
