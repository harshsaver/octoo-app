import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../data/session/session_data.dart';
import '../../l10n/app_localizations.dart';
import '../../protocol/models/entry.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

/// The activity log (`log`), grouped by day, with a filter by kind.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key, required this.computerId});

  final String computerId;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  EntryKind? _filter;

  static String kindLabel(AppLocalizations l, EntryKind k) => switch (k) {
    EntryKind.task => l.kindTask,
    EntryKind.step => l.kindStep,
    EntryKind.consent => l.kindConsent,
    EntryKind.limit => l.kindLimit,
    EntryKind.todo => l.kindTodo,
    EntryKind.help => l.kindHelp,
    EntryKind.screen => l.kindScreen,
    EntryKind.message => l.kindMessage,
    EntryKind.pairing => l.kindPairing,
    EntryKind.policy => l.kindPolicy,
    EntryKind.unknown => l.kindOther,
  };

  static IconData kindIcon(EntryKind k) => switch (k) {
    EntryKind.task => Icons.chat_bubble_outline,
    EntryKind.step => Icons.subdirectory_arrow_right,
    EntryKind.consent => Icons.check_circle_outline,
    EntryKind.limit => Icons.shield_outlined,
    EntryKind.todo => Icons.inbox_outlined,
    EntryKind.help => Icons.front_hand_outlined,
    EntryKind.screen => Icons.screenshot_monitor_outlined,
    EntryKind.message => Icons.message_outlined,
    EntryKind.pairing => Icons.person_add_alt,
    EntryKind.policy => Icons.rule,
    EntryKind.unknown => Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final data = ref.watch(sessionDataProvider(widget.computerId)).value;
    final records = <LogRecord>[...?data?.entries.values]
      ..sort((a, b) {
        final c = b.entry.at.compareTo(a.entry.at);
        return c != 0 ? c : b.order.compareTo(a.order);
      });
    final kinds = {for (final r in records) r.entry.kindValue}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final shown = [
      for (final r in records)
        if (_filter == null || r.entry.kindValue == _filter) r,
    ];

    final now = clock.now();
    String day(int at) {
      final t = DateTime.fromMillisecondsSinceEpoch(at);
      final today = DateTime(now.year, now.month, now.day);
      final d = DateTime(t.year, t.month, t.day);
      if (d == today) return l.today;
      if (d == today.subtract(const Duration(days: 1))) return l.timeYesterday;
      return DateFormat.yMMMMEEEEd(l.localeName).format(t);
    }

    final children = <Widget>[];
    String? lastDay;
    for (final r in shown) {
      final d = day(r.entry.at);
      if (d != lastDay) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OctoSpace.lg,
              OctoSpace.lg,
              OctoSpace.lg,
              OctoSpace.xs,
            ),
            child: Semantics(
              header: true,
              child: Text(
                d,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: colors.secondaryLabel),
              ),
            ),
          ),
        );
        lastDay = d;
      }
      final e = r.entry;
      children.add(
        ListTile(
          leading: Icon(kindIcon(e.kindValue), color: colors.secondaryLabel),
          title: Text(e.text),
          subtitle: Text(
            [
              ?e.by,
              DateFormat.jm(l.localeName)
                  .format(DateTime.fromMillisecondsSinceEpoch(e.at)),
            ].join(' · '),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.activity)),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: OctoSpace.md),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: OctoSpace.xs),
                  child: ChoiceChip(
                    label: Text(l.filterAll),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                for (final k in kinds)
                  Padding(
                    padding: const EdgeInsets.only(right: OctoSpace.xs),
                    child: ChoiceChip(
                      label: Text(kindLabel(l, k)),
                      selected: _filter == k,
                      onSelected: (_) =>
                          setState(() => _filter = _filter == k ? null : k),
                    ),
                  ),
              ],
            ),
          ),
          if (data?.logMayBeIncomplete ?? false)
            Padding(
              padding: const EdgeInsets.all(OctoSpace.sm),
              child: Text(
                l.activityMayBeMissing,
                style: TextStyle(color: colors.secondaryLabel),
              ),
            ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      l.activityEmpty,
                      style: TextStyle(color: colors.secondaryLabel),
                    ),
                  )
                : ListView(children: children),
          ),
        ],
      ),
    );
  }
}
