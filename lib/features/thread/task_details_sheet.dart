import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../protocol/models/task.dart';
import '../../ui/labels.dart';
import '../../ui/theme.dart';
import '../../ui/time_format.dart';
import '../../ui/tokens.dart';

/// A task's full timeline, from its `steps`, `result` and times.
class TaskDetailsSheet extends StatelessWidget {
  const TaskDetailsSheet({super.key, required this.task, required this.person});

  final Task task;
  final String person;

  static Future<void> show(BuildContext context, Task task, String person) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, controller) => TaskDetailsSheet(
            task: task,
            person: person,
          )._list(context, controller),
        ),
      );

  Widget _list(BuildContext context, ScrollController? controller) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final theme = Theme.of(context);
    final now = clock.now();
    String at(int? ms) => ms == null ? '' : threadStamp(l, ms, now);

    Widget row(
      String title,
      String? subtitle, {
      IconData icon = Icons.circle,
      Color? color,
    }) => ListTile(
      leading: Icon(icon, size: 18, color: color ?? colors.secondaryLabel),
      title: Text(title),
      subtitle: subtitle == null || subtitle.isEmpty ? null : Text(subtitle),
      dense: true,
    );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.only(bottom: OctoSpace.xl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            OctoSpace.lg,
            0,
            OctoSpace.lg,
            OctoSpace.sm,
          ),
          child: Text(l.timelineTitle, style: theme.textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: OctoSpace.lg),
          child: Text(task.text, style: theme.textTheme.bodyLarge),
        ),
        const SizedBox(height: OctoSpace.sm),
        row(
          l.timelineAsked(task.fromName ?? ''),
          at(task.createdAt),
          icon: Icons.chat_bubble_outline,
        ),
        if (task.startedAt != null)
          row(
            l.timelineStarted,
            at(task.startedAt),
            icon: Icons.play_circle_outline,
          ),
        for (final s in task.steps)
          row(
            s.say ?? s.did ?? l.liveStep(s.n),
            [
              if (s.did != null && s.did != s.say) s.did!,
              if (s.error != null) s.error!,
              at(s.at),
            ].where((x) => x.isNotEmpty).join(' · '),
            icon: s.ok == false
                ? Icons.error_outline
                : Icons.check_circle_outline,
            color: s.ok == false ? colors.needsYou : colors.working,
          ),
        if (task.phase.isEnded)
          row(
            '${l.timelineEnded}: ${taskPhaseLabel(l, task.phase, person)}',
            [
              task.result ?? '',
              at(task.endedAt),
            ].where((x) => x.isNotEmpty).join(' · '),
            icon: Icons.flag_outlined,
          )
        else
          row(
            taskPhaseLabel(l, task.phase, person),
            task.say,
            icon: Icons.more_horiz,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => _list(context, null);
}
