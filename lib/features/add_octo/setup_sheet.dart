import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/backend/octo_backend.dart';
import '../../data/db/database.dart';
import '../../data/enrollment/enrollment_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../transport/octo_link.dart';
import '../../ui/octo_avatar.dart';
import '../../ui/languages.dart';
import '../../ui/look_picker.dart';
import '../../ui/octo_looks.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

const _nameChips = ['Mom', 'Dad', 'Nani', 'Dadi', 'Grandma', 'Grandpa'];

/// The sheet after a code is read: pairing (scanned → compare key → waiting
/// for her → outcome), then "Who is it for?", then "Pick their Octo".
/// Pops with the new computer's id, or null. Closing it cancels pairing.
class SetupSheet extends ConsumerStatefulWidget {
  const SetupSheet({super.key, required this.enrollment});

  final Enrollment enrollment;

  static Future<String?> show(BuildContext context, Enrollment enrollment) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => SetupSheet(enrollment: enrollment),
      );

  @override
  ConsumerState<SetupSheet> createState() => _SetupSheetState();
}

enum _Step { pairing, name, look, saving }

class _SetupSheetState extends ConsumerState<SetupSheet> {
  StreamSubscription<PairingProgress>? _pairing;
  PairingProgress? _progress;
  String? _computerName;
  PairedComputer? _paired;
  _Step _step = _Step.pairing;

  final _person = TextEditingController();
  final _computer = TextEditingController();
  String _language = 'en';
  OctoLook _look = OctoLook.orange;
  String? _error;

  @override
  void initState() {
    super.initState();
    final name = ref.read(accountProvider).name;
    final device = Platform.isIOS ? "$name's iPhone" : "$name's Android phone";
    _pairing = ref
        .read(octoLinkProvider)
        .pair(
          widget.enrollment.pairPayload,
          helperName: name,
          deviceLabel: device,
        )
        .listen((p) {
          if (!mounted) return;
          if (p is PairingScanned) _computerName = p.computerName;
          if (p is PairingPaired) {
            _paired = p.computer;
            _computer.text = p.computer.computerName;
            if (p.computer.person != null) _person.text = p.computer.person!;
            unawaited(HapticFeedback.mediumImpact());
            setState(() => _step = _Step.name);
            return;
          }
          setState(() => _progress = p);
        });
  }

  @override
  void dispose() {
    unawaited(_pairing?.cancel());
    _person.dispose();
    _computer.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final paired = _paired!;
    final person = _person.text.trim();
    final computerName = _computer.text.trim().isEmpty
        ? paired.computerName
        : _computer.text.trim();
    setState(() {
      _step = _Step.saving;
      _error = null;
    });
    final l = AppLocalizations.of(context);
    final helper = ref.read(accountProvider).name;
    final db = ref.read(databaseProvider);
    final now = clock.now().millisecondsSinceEpoch;
    try {
      // The backend owns the profile (PLAN §3.8): PATCH first.
      await ref
          .read(backendProvider)
          .patchComputer(
            paired.computerId,
            name: computerName,
            person: person,
            language: _language,
            octo: _look.id,
          );
      final count = (await db.allComputers()).length;
      await db.upsertComputer(
        ComputersCompanion.insert(
          id: paired.computerId,
          hostId: Value(paired.hostId),
          bind: Value(paired.bind),
          computerName: computerName,
          person: person,
          language: Value(_language),
          look: Value(_look.id),
          role: Value(widget.enrollment.mode.name),
          sortOrder: Value(count),
          lastReadAt: Value(now),
          profileGen: const Value(1),
          addedAt: now,
        ),
      );
      final session = await ref
          .read(sessionsControllerProvider)
          .ensure(paired.computerId, bind: paired.bind);
      await session.addNote('welcome', l.welcome(helper, person));
      // Her computer learns the names through the profile sync: it is owed
      // (generation 1) and runs now or when she's back.
      unawaited(ref.read(profileSyncProvider).sync(session.computerId));
      if (count == 0 && mounted) await _askForNotifications(person);
      if (mounted) Navigator.pop(context, paired.computerId);
    } on BackendException catch (e) {
      setState(() {
        _step = _Step.look;
        _error = l.setupFailed(e.message);
      });
    }
  }

  /// The first time an Octo is added, with one line of why (brief §5.1).
  Future<void> _askForNotifications(String person) async {
    final push = ref.read(pushServiceProvider);
    if (!push.available) return;
    final l = AppLocalizations.of(context);
    final allow = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.notifications),
        content: Text(l.notificationsWhy(person)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l.allowNotifications),
          ),
        ],
      ),
    );
    if (allow == true && await push.requestPermission()) {
      await ref.read(pushRegistrarProvider).register();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          OctoSpace.xl,
          0,
          OctoSpace.xl,
          OctoSpace.xl + bottom,
        ),
        child: AnimatedSwitcher(
          duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
              ? Duration.zero
              : OctoMotion.medium,
          child: switch (_step) {
            _Step.pairing => _pairingView(context),
            _Step.name => _nameView(context),
            _Step.look || _Step.saving => _lookView(context),
          },
        ),
      ),
    );
  }

  Widget _column(List<Widget> children) => Column(
    key: ValueKey(_step.name + (_progress?.runtimeType.toString() ?? '')),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );

  Widget _pairingView(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = OctoTheme.of(context);
    final computer = _computerName ?? widget.enrollment.computerName ?? '';
    Widget title(String t) => Text(
      t,
      style: theme.textTheme.headlineSmall,
      textAlign: TextAlign.center,
    );
    Widget body(String t) =>
        Text(t, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center);

    return switch (_progress) {
      null || PairingScanned() => _column([
        const Center(child: OctoAvatar(size: 96)),
        const SizedBox(height: OctoSpace.lg),
        title(computer.isEmpty ? l.connecting : computer),
        const SizedBox(height: OctoSpace.sm),
        body(l.connecting),
        const SizedBox(height: OctoSpace.lg),
      ]),
      PairingCompareCode(:final code, :final confirm) => _column([
        Semantics(
          label: code.split('').join(' '),
          excludeSemantics: true,
          child: Text(
            '${code.substring(0, 3)} ${code.substring(3)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: OctoSpace.md),
        body(l.compareKeyBody(computer)),
        const SizedBox(height: OctoSpace.xl),
        FilledButton(onPressed: () => confirm(true), child: Text(l.theyMatch)),
        const SizedBox(height: OctoSpace.sm),
        TextButton(
          onPressed: () => confirm(false),
          child: Text(l.theyDontMatch),
        ),
      ]),
      PairingWaitingForHer() => _column([
        const Center(child: OctoAvatar(size: 120, mood: OctoMood.waiting)),
        const SizedBox(height: OctoSpace.lg),
        body(l.waitingForOk(computer)),
        const SizedBox(height: OctoSpace.lg),
      ]),
      PairingFailed(:final kind, :final reason, :final isFinal) => _column([
        const Center(child: OctoAvatar(size: 96, mood: OctoMood.sleepy)),
        const SizedBox(height: OctoSpace.lg),
        title(l.pairNotAdded),
        const SizedBox(height: OctoSpace.sm),
        body(switch (kind) {
          PairingFailureKind.reportedByComputer => reason ?? '',
          PairingFailureKind.codeMismatch => l.mismatchExplain,
          PairingFailureKind.offline => l.pairOffline(computer),
          PairingFailureKind.notOcto => l.pairNotOcto(computer),
          PairingFailureKind.timedOut => l.pairTimedOut(computer),
          PairingFailureKind.invalidCode => l.codeNotRecognised,
          PairingFailureKind.notAvailable => l.pairNotAvailable,
        }),
        const SizedBox(height: OctoSpace.xl),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.accentText),
          onPressed: () => Navigator.pop(context),
          child: Text(isFinal ? l.scanAgain : l.tryAgain),
        ),
      ]),
      PairingPaired() => _column(const []),
    };
  }

  Widget _nameView(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _column([
      Text(l.nameTitle, style: theme.textTheme.headlineSmall),
      const SizedBox(height: OctoSpace.md),
      Wrap(
        spacing: OctoSpace.sm,
        runSpacing: OctoSpace.sm,
        children: [
          for (final n in _nameChips)
            ChoiceChip(
              label: Text(n),
              selected: _person.text == n,
              onSelected: (_) => setState(() => _person.text = n),
            ),
        ],
      ),
      const SizedBox(height: OctoSpace.md),
      TextField(
        controller: _person,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: l.nameOther),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: OctoSpace.xl),
      Text(l.languageTitle, style: theme.textTheme.titleMedium),
      const SizedBox(height: OctoSpace.sm),
      Wrap(
        spacing: OctoSpace.sm,
        runSpacing: OctoSpace.sm,
        children: [
          for (final (code, name) in octoLanguages)
            ChoiceChip(
              label: Text(name),
              selected: _language == code,
              onSelected: (_) => setState(() => _language = code),
            ),
        ],
      ),
      const SizedBox(height: OctoSpace.xl),
      TextField(
        controller: _computer,
        decoration: InputDecoration(labelText: l.computerNameLabel),
      ),
      const SizedBox(height: OctoSpace.xl),
      FilledButton(
        onPressed: _person.text.trim().isEmpty
            ? null
            : () => setState(() => _step = _Step.look),
        child: Text(l.next),
      ),
    ]);
  }

  Widget _lookView(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = OctoTheme.of(context);
    final saving = _step == _Step.saving;
    return _column([
      Text(l.lookTitle, style: theme.textTheme.headlineSmall),
      const SizedBox(height: OctoSpace.lg),
      Center(child: OctoAvatar(look: _look, size: 120)),
      const SizedBox(height: OctoSpace.lg),
      LookPicker(
        selected: _look,
        onChanged: saving ? null : (look) => setState(() => _look = look),
      ),
      if (_error != null) ...[
        const SizedBox(height: OctoSpace.md),
        Text(_error!, style: TextStyle(color: colors.needsYou)),
      ],
      const SizedBox(height: OctoSpace.xl),
      FilledButton(
        onPressed: saving ? null : _finish,
        child: saving
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l.done),
      ),
    ]);
  }
}
