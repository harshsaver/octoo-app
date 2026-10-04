import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/outbox.dart';
import '../../data/thread/projection.dart';
import '../../l10n/app_localizations.dart';
import '../../protocol/models/task.dart';
import '../../protocol/models/todo.dart';
import '../../ui/bubble.dart';
import '../../ui/labels.dart';
import '../../ui/theme.dart';
import '../../ui/time_format.dart';
import '../../ui/tokens.dart';
import 'shot_view.dart';

/// What bubbles can ask the thread to do.
class ThreadActions {
  const ThreadActions({
    required this.tryAgain,
    required this.stop,
    required this.details,
    required this.reply,
    required this.doIt,
    required this.seeScreen,
  });

  final void Function(String outboxId) tryAgain;
  final void Function(String taskId) stop;
  final void Function(String taskId) details;
  final void Function(Todo todo) reply;
  final void Function(Todo todo) doIt;
  final VoidCallback seeScreen;
}

/// One thread entry as a widget.
class ThreadEntryView extends StatelessWidget {
  const ThreadEntryView({
    super.key,
    required this.entry,
    required this.person,
    required this.actions,
  });

  final ThreadEntry entry;

  /// Her name ("Mom").
  final String person;
  final ThreadActions actions;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final theme = Theme.of(context);
    final now = clock.now();
    final tail = entry.lastInGroup
        ? (item.side == ThreadSide.right ? TailSide.right : TailSide.left)
        : TailSide.none;
    final spacing = entry.lastInGroup ? OctoSpace.sm : 2.0;
    String when() => agoText(l, item.at, now);

    Widget center(String text, {Widget? leading}) => Padding(
      padding: const EdgeInsets.symmetric(
        vertical: OctoSpace.sm,
        horizontal: OctoSpace.xl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ?leading,
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );

    Widget side({
      required Widget child,
      String? label,
      String? semantics,
      List<Widget> below = const [],
    }) {
      final right = item.side == ThreadSide.right;
      return Padding(
        padding: EdgeInsets.only(
          left: right ? OctoSpace.xxl : OctoSpace.md,
          right: right ? OctoSpace.md : OctoSpace.xxl,
          bottom: spacing,
        ),
        child: Column(
          crossAxisAlignment: right
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (label != null && entry.firstInGroup)
              Padding(
                padding: const EdgeInsets.only(left: OctoSpace.md, bottom: 2),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.secondaryLabel,
                  ),
                ),
              ),
            if (semantics == null)
              child
            else
              Semantics(label: semantics, excludeSemantics: true, child: child),
            for (final b in below)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 6, right: 6),
                child: b,
              ),
          ],
        ),
      );
    }

    Widget small(String text, {Color? color, IconData? icon}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color ?? colors.secondaryLabel),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color ?? colors.secondaryLabel,
            ),
          ),
        ),
      ],
    );

    List<Widget> delivery(
      OutboxState? state,
      String? errorMessage, {
      String? outboxId,
      bool isTask = false,
    }) => switch (state) {
      OutboxState.pending => [small(l.deliveryPending, icon: Icons.schedule)],
      OutboxState.attempting => [
        small(l.deliverySending, icon: Icons.schedule),
      ],
      OutboxState.uncertain => [
        small(
          l.deliveryUncertain(person),
          color: colors.needsYou,
          icon: Icons.error_outline,
        ),
        if (isTask && outboxId != null)
          TextButton(
            onPressed: () => actions.tryAgain(outboxId),
            child: Text(l.tryAgain),
          ),
      ],
      OutboxState.rejected => [
        small(
          errorMessage == null || errorMessage.isEmpty
              ? l.deliveryRejectedPlain
              : l.deliveryRejected(errorMessage),
          color: colors.needsYou,
          icon: Icons.error_outline,
        ),
        if (isTask && outboxId != null)
          TextButton(
            onPressed: () => actions.tryAgain(outboxId),
            child: Text(l.tryAgain),
          ),
      ],
      _ => const [],
    };

    Widget body(String value, Color color) =>
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(color: color));

    switch (item) {
      case TimestampItem():
        return center(threadStamp(l, item.at, now));

      case SystemItem(:final kind):
        final value = switch (kind) {
          SystemKind.log => item.text ?? '',
          SystemKind.askedScreen => l.askedScreen(person),
          SystemKind.screenRefused => l.screenRefused(person),
        };
        final pending =
            item.delivery == OutboxState.pending ||
            item.delivery == OutboxState.attempting;
        return center(
          value,
          leading: pending
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.schedule,
                    size: 13,
                    color: colors.secondaryLabel,
                  ),
                )
              : null,
        );

      case RequestItem(:final mine):
        final isMine = mine == true;
        final bubble = Bubble(
          color: isMine ? colors.myBubble : colors.otherBubble,
          tail: tail,
          child: body(
            item.text,
            isMine ? colors.onMyBubble : colors.onOtherBubble,
          ),
        );
        final line = switch (item.line) {
          RequestLine.waitingTurn => l.lineWaitingTurn,
          RequestLine.waitingForHer => l.lineWaitingForHer(person),
          RequestLine.sheSaidOk => l.lineSheSaidOk(person),
          null => null,
        };
        return _LongPress(
          copyText: item.text,
          onTryAgain: isMine && item.outboxId != null
              ? () => actions.tryAgain(item.outboxId!)
              : null,
          onStop: item.taskActive && item.taskId != null
              ? () => actions.stop(item.taskId!)
              : null,
          onDetails: item.taskId != null
              ? () => actions.details(item.taskId!)
              : null,
          child: side(
            semantics: l.bubbleLabel(
              isMine ? l.youName : (item.fromName ?? ''),
              when(),
              item.text,
            ),
            label: isMine ? null : l.fromName(item.fromName ?? ''),
            child: bubble,
            below: [
              ...delivery(
                item.delivery,
                item.errorMessage,
                outboxId: item.outboxId,
                isTask: true,
              ),
              if (line != null) small(line),
              if (item.isRetry && item.delivery != null) small(l.retryNote),
            ],
          ),
        );

      case OctoTaskItem(:final task):
        final running = task.phase == TaskPhase.running;
        final sentence = running
            ? (task.say ?? l.liveStarting)
            : task.phase.isEnded
            ? (task.result ?? taskResultFallback(l, task.phase, person))
            : l.taskUnknown;
        return _LongPress(
          copyText: sentence,
          onStop: running ? () => actions.stop(task.id) : null,
          onDetails: () => actions.details(task.id),
          child: side(
            semantics: l.bubbleLabel(l.octoName, when(), sentence),
            child: GestureDetector(
              onTap: () => actions.details(task.id),
              child: Bubble(
                color: colors.otherBubble,
                tail: tail,
                child: running
                    ? _LiveTask(task: task, onStop: () => actions.stop(task.id))
                    : body(sentence, colors.onOtherBubble),
              ),
            ),
          ),
        );

      case OctoNoteItem(:final text):
        return _LongPress(
          copyText: text,
          child: side(
            semantics: l.bubbleLabel(l.octoName, when(), text),
            child: Bubble(
              color: colors.otherBubble,
              tail: tail,
              child: body(text, colors.onOtherBubble),
            ),
          ),
        );

      case ImageItem(:final shot, :final source, :final caption):
        final label = source == ImageSource.octo
            ? l.imageFromOcto
            : l.imageFromHer(person);
        return side(
          label: source == ImageSource.her ? person : null,
          child: ShotView(shot: shot, semanticLabel: label, caption: caption),
          below: [if (caption != null) small(caption)],
        );

      case TodoItem(:final todo, :final otherReplies):
        return _LongPress(
          copyText: todo.text,
          child: side(
            semantics: l.bubbleLabel(person, when(), todo.text),
            label: person,
            child: Bubble(
              color: colors.otherBubble,
              tail: tail,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  body(todo.text, colors.onOtherBubble),
                  if (todo.answer != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.octoToldHer(todo.answer!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondaryLabel,
                      ),
                    ),
                  ],
                  for (final r in otherReplies) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${r.from ?? ''}: ${r.text}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onOtherBubble,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            below: [
              Wrap(
                spacing: OctoSpace.xs,
                children: [
                  TextButton(
                    onPressed: () => actions.reply(todo),
                    child: Text(l.reply),
                  ),
                  TextButton(
                    onPressed: () => actions.doIt(todo),
                    child: Text(l.doIt),
                  ),
                ],
              ),
            ],
          ),
        );

      case HelpItem(:final text, :final active):
        final message = text == null ? l.helpAsk : '${l.helpAsk}\n$text';
        return _LongPress(
          copyText: message,
          child: side(
            semantics: l.bubbleLabel(person, when(), message),
            label: person,
            child: Bubble(
              color: colors.helpTint,
              tail: tail,
              child: body(message, colors.label),
            ),
            below: [
              if (active)
                TextButton(
                  onPressed: actions.seeScreen,
                  child: Text(l.seeHerScreen),
                ),
            ],
          ),
        );

      case MessageItem(:final mine, :final text):
        return _LongPress(
          copyText: text,
          child: side(
            semantics: l.bubbleLabel(
              mine ? l.youName : (item.fromName ?? ''),
              when(),
              text,
            ),
            label: mine ? null : item.fromName,
            child: Bubble(
              color: mine ? colors.tellBubble : colors.otherBubble,
              tail: tail,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.replyToTodo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        l.replyingTo(item.replyToTodo!),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: (mine ? Colors.white : colors.onOtherBubble)
                              .withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  body(text, mine ? Colors.white : colors.onOtherBubble),
                ],
              ),
            ),
            below: delivery(item.delivery, null),
          ),
        );
    }
  }
}

/// Octo's live bubble: the current step in plain words, a thin progress
/// line, and a small Stop. Updates in place.
class _LiveTask extends StatelessWidget {
  const _LiveTask({required this.task, required this.onStop});

  final Task task;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : OctoMotion.short,
          child: Text(
            task.say ?? l.liveStarting,
            key: ValueKey(task.say),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onOtherBubble,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: reduceMotion
                    ? const SizedBox.shrink()
                    : LinearProgressIndicator(
                        minHeight: 3,
                        color: colors.working,
                        backgroundColor: colors.working.withValues(alpha: 0.15),
                      ),
              ),
            ),
            const SizedBox(width: OctoSpace.sm),
            Text(
              l.liveStep(task.steps.length + 1),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.secondaryLabel,
              ),
            ),
            TextButton(
              onPressed: onStop,
              style: TextButton.styleFrom(foregroundColor: colors.needsYou),
              child: Text(l.stop),
            ),
          ],
        ),
      ],
    );
  }
}

/// Long-press menu: Copy, Try again, Stop, Details.
class _LongPress extends StatelessWidget {
  const _LongPress({
    required this.child,
    this.copyText,
    this.onTryAgain,
    this.onStop,
    this.onDetails,
  });

  final Widget child;
  final String? copyText;
  final VoidCallback? onTryAgain;
  final VoidCallback? onStop;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Future<void> menu() async {
      unawaited(HapticFeedback.mediumImpact());
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (copyText != null)
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: Text(l.copy),
                  onTap: () {
                    unawaited(
                      Clipboard.setData(ClipboardData(text: copyText!)),
                    );
                    Navigator.pop(sheet);
                  },
                ),
              if (onTryAgain != null)
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: Text(l.tryAgain),
                  onTap: () {
                    Navigator.pop(sheet);
                    onTryAgain!();
                  },
                ),
              if (onStop != null)
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: Text(l.stop),
                  onTap: () {
                    Navigator.pop(sheet);
                    onStop!();
                  },
                ),
              if (onDetails != null)
                ListTile(
                  leading: const Icon(Icons.timeline),
                  title: Text(l.details),
                  onTap: () {
                    Navigator.pop(sheet);
                    onDetails!();
                  },
                ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      onLongPressHint: l.details,
      child: GestureDetector(onLongPress: menu, child: child),
    );
  }
}
