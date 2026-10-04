import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/session/computer_session.dart';
import '../../data/thread/projection.dart';
import '../../l10n/app_localizations.dart';
import '../../protocol/models/task.dart';
import '../../transport/octo_link.dart';
import '../../ui/octo_avatar.dart';
import '../../ui/octo_looks.dart';
import '../../ui/theme.dart';
import '../../ui/time_format.dart';
import '../../ui/tokens.dart';
import 'composer.dart';
import 'task_details_sheet.dart';
import 'thread_bubbles.dart';

/// One Octo's conversation (brief §5.4).
class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({super.key, required this.computerId});

  final String computerId;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _composer = ComposerController();

  /// Keys already on screen; anything new slides in.
  final Set<String> _seen = {};
  bool _firstFrame = true;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  ComputerSession? get _session =>
      ref.read(sessionsControllerProvider).session(widget.computerId);

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _stop(String taskId, String person) async {
    final l = AppLocalizations.of(context);
    final outcome = await _session?.stopTask(taskId);
    switch (outcome) {
      case StopOutcome.stopped || null:
        break;
      case StopOutcome.offline:
        _snack(l.stopOffline(person));
      case StopOutcome.refused:
        _snack(l.stopRefused);
      case StopOutcome.noReply:
        _snack(l.stopNoReply);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final id = widget.computerId;
    final computer = ref.watch(computerProvider(id));
    final data = ref.watch(sessionDataProvider(id)).value;
    final thread = ref.watch(threadProvider(id));

    // Reading the thread marks it read.
    ref.listen(
      threadProvider(id),
      (_, _) => ref.read(sessionsControllerProvider).markRead(id),
    );

    if (computer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final person = computer.person;
    final now = clock.now();
    final running =
        data?.tasks.values.any((t) => t.task.phase == TaskPhase.running) ??
        false;
    final link = data?.link;
    final (String status, Color statusColor) = switch (link) {
      LinkState.connected when running => (l.statusWorking, colors.working),
      LinkState.connected => (l.statusOnline, colors.secondaryLabel),
      LinkState.connecting => (l.statusConnecting, colors.secondaryLabel),
      _ when data?.lastSeenAt != null => (
        l.statusLastSeen(agoText(l, data!.lastSeenAt!, now)),
        colors.secondaryLabel,
      ),
      _ => (l.statusOffline, colors.secondaryLabel),
    };
    final mood = link == LinkState.offline && data?.lastSeenAt != null
        ? OctoMood.sleepy
        : (running ? OctoMood.working : OctoMood.idle);

    final actions = ThreadActions(
      tryAgain: (outboxId) => _session?.tryAgain(outboxId),
      stop: (taskId) => _stop(taskId, person),
      details: (taskId) {
        final task = data?.tasks[taskId]?.task;
        if (task != null) TaskDetailsSheet.show(context, task, person);
      },
      reply: _composer.replyToTodo,
      doIt: (todo) => _session?.askOcto(todo.text),
      seeScreen: () => _session?.requestScreen(),
    );

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final entries = thread.reversed.toList();
    final animateNew = !_firstFrame && !reduceMotion;
    final fresh = <String>{
      for (final e in entries)
        if (animateNew && !_seen.contains(e.item.key)) e.item.key,
    };
    _seen.addAll(entries.map((e) => e.item.key));
    _firstFrame = false;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Semantics(
          header: true,
          label: '$person. $status',
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OctoAvatar(
                look: OctoLook.fromId(computer.look),
                size: 36,
                mood: mood,
              ),
              const SizedBox(width: OctoSpace.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(person, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: data == null
                ? const Center(child: CircularProgressIndicator.adaptive())
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: OctoSpace.sm),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      final view = ThreadEntryView(
                        key: ValueKey(entry.item.key),
                        entry: entry,
                        person: person,
                        actions: actions,
                      );
                      return fresh.contains(entry.item.key)
                          ? _SlideIn(
                              key: ValueKey('in:${entry.item.key}'),
                              fromRight: entry.item.side == ThreadSide.right,
                              child: view,
                            )
                          : view;
                    },
                  ),
          ),
          if (data?.logMayBeIncomplete ?? false)
            Text(
              l.activityMayBeMissing,
              style: TextStyle(color: colors.secondaryLabel, fontSize: 12),
            ),
          Composer(
            controller: _composer,
            person: person,
            online: link == LinkState.connected,
            removed: data?.removed ?? false,
            jobs: data?.status?.jobs ?? const [],
            onAsk: (text, job) => _session?.askOcto(text, job: job),
            onTell: (text) => _session?.tellMom(text),
            onReply: (todo, text) => _session?.replyToTodo(todo.id, text),
            onSeeScreen: () => _session?.requestScreen(),
          ),
        ],
      ),
    );
  }
}

/// New bubbles slide in with a soft spring (off under reduced motion).
class _SlideIn extends StatefulWidget {
  const _SlideIn({super.key, required this.child, required this.fromRight});

  final Widget child;
  final bool fromRight;

  @override
  State<_SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<_SlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: OctoMotion.medium,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: OctoMotion.bubbleSpring);
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween(
          begin: Offset(widget.fromRight ? 0.15 : -0.15, 0.25),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}
