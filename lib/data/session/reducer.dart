import '../../protocol/host_message.dart';
import '../../protocol/models/entry.dart';
import '../../protocol/models/policy.dart';
import '../../protocol/models/status.dart';
import '../../protocol/models/task.dart';
import '../../protocol/models/todo.dart';
import '../../transport/octo_link.dart';
import '../ids.dart';
import '../outbox.dart';
import '../policy_edit.dart';
import 'session_data.dart';

/// Something that changes a session. Host messages arrive with their
/// screenshots already normalised to [ShotRef]s.
sealed class SessionEvent {
  const SessionEvent();
}

final class LinkChanged extends SessionEvent {
  const LinkChanged(this.state, this.at);

  final LinkState state;
  final int at;
}

/// A `status`/`todos` refresh is being sent: snapshots that answer it lose to
/// live events received after this point.
final class RefreshStarted extends SessionEvent {
  const RefreshStarted();
}

final class RefreshEnded extends SessionEvent {
  const RefreshEnded();
}

final class TaskReceived extends SessionEvent {
  const TaskReceived(this.task, this.shot);

  final Task task;
  final ShotRef? shot;
}

final class TodoReceived extends SessionEvent {
  const TodoReceived(this.todo, this.shot);

  final Todo todo;
  final ShotRef? shot;
}

final class HelpReceived extends SessionEvent {
  const HelpReceived(this.at, this.text);

  final int at;
  final String? text;
}

final class ScreenReceived extends SessionEvent {
  const ScreenReceived(this.message, this.shot, this.receivedAt);

  final ScreenMessage message;
  final ShotRef? shot;
  final int receivedAt;
}

final class PolicyReceived extends SessionEvent {
  const PolicyReceived(this.policy, {required this.declined, required this.at});

  final Policy policy;
  final bool declined;
  final int at;
}

final class RemovedReceived extends SessionEvent {
  const RemovedReceived();
}

/// A `status` reply (or push). [refreshSeq] is the session's `seq` when the
/// request was sent; null means "now" (an unrequested push).
final class StatusSnapshot extends SessionEvent {
  const StatusSnapshot(
    this.status, {
    this.refreshSeq,
    this.taskShots = const {},
  });

  final ComputerStatus status;
  final int? refreshSeq;
  final Map<String, ShotRef?> taskShots;
}

final class TodosSnapshot extends SessionEvent {
  const TodosSnapshot(this.todos, {this.refreshSeq, this.shots = const {}});

  final List<Todo> todos;
  final int? refreshSeq;
  final Map<String, ShotRef?> shots;
}

/// A page of the activity log. [cursor] and [incomplete] update the sync
/// state together with the rows.
final class LogReceived extends SessionEvent {
  const LogReceived(this.entries, {this.cursor, this.incomplete});

  final List<Entry> entries;
  final int? cursor;
  final bool? incomplete;
}

final class OutboxUpserted extends SessionEvent {
  const OutboxUpserted(this.row);

  final OutboxRow row;
}

final class OutboxRemoved extends SessionEvent {
  const OutboxRemoved(this.id);

  final String id;
}

final class NoteAdded extends SessionEvent {
  const NoteAdded({required this.id, required this.at, required this.text});

  final String id;
  final int at;
  final String text;
}

/// A rules edit was sent; [edit] says what's pending.
final class PolicyEditStarted extends SessionEvent {
  const PolicyEditStarted(this.edit);

  final PolicyEdit edit;
}

/// The rules edit failed or was abandoned; pending labels go away.
final class PolicyEditEnded extends SessionEvent {
  const PolicyEditEnded();
}

/// Someone on this phone acted, so her help request is being handled.
final class HelpHandled extends SessionEvent {
  const HelpHandled();
}

/// Applies [event] to [s]. Pure.
///
/// Reconciliation (PLAN §3.3): live events apply in order and a `task`
/// replaces the stored task. A snapshot doesn't overwrite an entity a live
/// event changed after the snapshot's refresh was sent, and a snapshot never
/// turns an ended task back into an active one.
SessionData reduce(SessionData s, SessionEvent event) {
  switch (event) {
    case LinkChanged(:final state, :final at):
      return s.copyWith(
        link: state,
        lastSeenAt:
            state == LinkState.connected || s.link == LinkState.connected
            ? at
            : null,
      );

    case RefreshStarted():
      return s.copyWith(refreshSeq: () => s.seq);

    case RefreshEnded():
      return s.copyWith(refreshSeq: () => null);

    case TaskReceived(:final task, :final shot):
      final seq = s.seq + 1;
      final old = s.tasks[task.id];
      var next = s.copyWith(
        seq: seq,
        nextOrder: old == null ? s.nextOrder + 1 : null,
        tasks: {
          ...s.tasks,
          task.id: TrackedTask(
            task: task,
            shot: shot,
            order: old?.order ?? s.nextOrder,
            liveSeq: seq,
            askedHer:
                (old?.askedHer ?? false) || task.phase == TaskPhase.waitingOk,
          ),
        },
      );
      next = _learnHelperId(next, task);
      return next;

    case TodoReceived(:final todo, :final shot):
      final seq = s.seq + 1;
      final old = s.todos[todo.id];
      return s.copyWith(
        seq: seq,
        nextOrder: old == null ? s.nextOrder + 1 : null,
        todos: {
          ...s.todos,
          todo.id: TrackedTodo(
            todo: todo,
            shot: shot,
            order: old?.order ?? s.nextOrder,
            liveSeq: seq,
          ),
        },
      );

    case HelpReceived(:final at, :final text):
      final seq = s.seq + 1;
      final withEvent = _addHelp(s, at, text);
      return withEvent.copyWith(
        seq: seq,
        activeHelp: () => HelpState(since: at, text: text),
        helpLiveSeq: seq,
      );

    case HelpHandled():
      if (s.activeHelp == null) return s;
      return s.copyWith(
        seq: s.seq + 1,
        activeHelp: () => null,
        helpLiveSeq: s.seq + 1,
      );

    case ScreenReceived(:final message, :final shot, :final receivedAt):
      final at = message.at ?? receivedAt;
      final id = stableId([
        s.computerId,
        'screen',
        at,
        message.ok,
        message.reason,
      ]);
      if (s.screens.containsKey(id)) return s.copyWith(seq: s.seq + 1);
      return s.copyWith(
        seq: s.seq + 1,
        nextOrder: s.nextOrder + 1,
        screens: {
          ...s.screens,
          id: ScreenEvent(
            id: id,
            at: at,
            ok: message.ok,
            shot: shot,
            app: message.app,
            window: message.window,
            reason: message.reason,
            order: s.nextOrder,
          ),
        },
      );

    case PolicyReceived(:final policy, :final declined, :final at):
      final seq = s.seq + 1;
      final edit = s.policyEdit;
      return s.copyWith(
        seq: seq,
        policy: policy,
        policyLiveSeq: seq,
        policyDeclinedAt: () => declined ? at : null,
        policyEdit: () => edit?.after(policy, declined: declined),
      );

    case PolicyEditStarted(:final edit):
      return s.copyWith(policyEdit: () => edit);

    case PolicyEditEnded():
      return s.copyWith(policyEdit: () => null);

    case RemovedReceived():
      return s.copyWith(seq: s.seq + 1, removed: true);

    case StatusSnapshot(:final status, :final taskShots):
      final since = event.refreshSeq ?? s.seq;
      var next = s.copyWith(status: status);
      final snapshotTasks = [?status.task, ...status.queued, ...status.recent];
      var tasks = next.tasks;
      var order = next.nextOrder;
      for (final task in snapshotTasks) {
        final old = tasks[task.id];
        if (old != null && old.liveSeq > since) continue;
        if (old != null && old.task.phase.isEnded && !task.phase.isEnded) {
          continue;
        }
        tasks = {
          ...tasks,
          task.id: TrackedTask(
            task: task,
            shot: taskShots.containsKey(task.id)
                ? taskShots[task.id]
                : old?.shot,
            order: old?.order ?? order++,
            liveSeq: old?.liveSeq ?? 0,
            askedHer:
                (old?.askedHer ?? false) || task.phase == TaskPhase.waitingOk,
          ),
        };
      }
      next = next.copyWith(tasks: tasks, nextOrder: order);
      for (final task in snapshotTasks) {
        next = _learnHelperId(next, task);
      }
      if (next.helpLiveSeq <= since) {
        final help = status.help;
        next = next.copyWith(activeHelp: () => help);
        if (help != null) next = _addHelp(next, help.since, help.text);
      }
      if (next.policyLiveSeq <= since && status.policy != null) {
        final edit = next.policyEdit;
        next = next.copyWith(
          policy: status.policy,
          policyEdit: () => edit?.after(status.policy!, declined: false),
        );
      }
      return next;

    case TodosSnapshot(:final todos, :final shots):
      final since = event.refreshSeq ?? s.seq;
      var map = s.todos;
      var order = s.nextOrder;
      for (final todo in todos) {
        final old = map[todo.id];
        if (old != null && old.liveSeq > since) continue;
        map = {
          ...map,
          todo.id: TrackedTodo(
            todo: todo,
            shot: shots.containsKey(todo.id) ? shots[todo.id] : old?.shot,
            order: old?.order ?? order++,
            liveSeq: old?.liveSeq ?? 0,
          ),
        };
      }
      return s.copyWith(todos: map, nextOrder: order);

    case LogReceived(:final entries, :final cursor, :final incomplete):
      var map = s.entries;
      var order = s.nextOrder;
      for (final e in entries) {
        final id = entryId(s.computerId, e);
        if (map.containsKey(id)) continue;
        map = {...map, id: LogRecord(id: id, entry: e, order: order++)};
      }
      return s.copyWith(
        entries: map,
        nextOrder: order,
        logCursor: cursor,
        logMayBeIncomplete: incomplete,
      );

    case OutboxUpserted(:final row):
      final next = s.copyWith(outbox: {...s.outbox, row.id: row});
      final task = row.taskId == null ? null : next.tasks[row.taskId]?.task;
      return task == null ? next : _learnHelperId(next, task);

    case OutboxRemoved(:final id):
      if (!s.outbox.containsKey(id)) return s;
      return s.copyWith(outbox: {...s.outbox}..remove(id));

    case NoteAdded(:final id, :final at, :final text):
      if (s.notes.containsKey(id)) return s;
      return s.copyWith(
        nextOrder: s.nextOrder + 1,
        notes: {
          ...s.notes,
          id: LocalNote(id: id, at: at, text: text, order: s.nextOrder),
        },
      );
  }
}

/// The stable id of a log entry (PLAN §3.4).
String entryId(String computerId, Entry e) =>
    stableId([computerId, e.kind, e.at, e.by, e.text, e.taskId]);

String helpId(String computerId, int at) => stableId([computerId, 'help', at]);

SessionData _addHelp(SessionData s, int at, String? text) {
  final id = helpId(s.computerId, at);
  final old = s.helps[id];
  if (old != null && (text == null || old.text == text)) return s;
  return s.copyWith(
    nextOrder: old == null ? s.nextOrder + 1 : null,
    helps: {
      ...s.helps,
      id: HelpEvent(
        id: id,
        at: at,
        text: text ?? old?.text,
        order: old?.order ?? s.nextOrder,
      ),
    },
  );
}

/// Fallback for knowing which tasks are this phone's (PLAN §3.7): a task
/// this phone created (its `result.taskId`) tells us our helper id.
SessionData _learnHelperId(SessionData s, Task task) {
  if (s.myHelperId != null || task.from == null) return s;
  if (s.outboxForTask(task.id) == null) return s;
  return s.copyWith(myHelperId: task.from);
}

/// Helpers for callers that build events from rows.
extension OutboxLookup on SessionData {
  OutboxRow? outboxByRequestId(String requestId) {
    for (final row in outbox.values) {
      if (row.requestId == requestId) return row;
    }
    return null;
  }

  List<OutboxRow> get pendingOutbox =>
      outbox.values.where((r) => r.state == OutboxState.pending).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}
