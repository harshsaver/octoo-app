import '../../protocol/models/entry.dart';
import '../../protocol/models/task.dart';
import '../../protocol/models/todo.dart';
import '../outbox.dart';
import '../session/reducer.dart' show helpId;
import '../session/session_data.dart';

/// Who this phone is on that computer.
class MeIdentity {
  const MeIdentity({required this.name, this.helperId});

  /// The helper's own name ("Harsh").
  final String name;

  /// This phone's helper id there, when known (PLAN §3.7 "Me").
  final String? helperId;
}

enum ThreadSide { left, right, center }

/// Who a bubble is from, for grouping: `me`, `octo`, `mom`, `other:<name>`.
typedef SenderKey = String;

/// One thing in a thread. [key] is stable for the life of the thing, so a
/// bubble updates in place and never remounts.
sealed class ThreadItem {
  const ThreadItem({required this.key, required this.at});

  final String key;

  /// Epoch ms, for ordering, timestamps and grouping.
  final int at;

  ThreadSide get side;

  SenderKey get sender;
}

/// What the request bubble's grey line says.
enum RequestLine { waitingTurn, waitingForHer, sheSaidOk }

/// A task request: yours (right, accent) or another helper's (left, named).
final class RequestItem extends ThreadItem {
  const RequestItem({
    required super.key,
    required super.at,
    required this.text,
    required this.mine,
    this.fromName,
    this.job,
    this.outboxId,
    this.delivery,
    this.errorMessage,
    this.taskId,
    this.line,
    this.isRetry = false,
    this.taskActive = false,
  });

  final String text;

  /// True: sent from this phone. False: another helper's. Null: unknown —
  /// rendered on the left with the name, conservatively.
  final bool? mine;
  final String? fromName;
  final String? job;
  final String? outboxId;

  /// Delivery state while this phone's outbox row matters.
  final OutboxState? delivery;
  final String? errorMessage;
  final String? taskId;
  final RequestLine? line;

  /// Sent with "Try again"; it may run twice.
  final bool isRetry;

  /// The task is still going (Stop makes sense).
  final bool taskActive;

  @override
  ThreadSide get side => mine == true ? ThreadSide.right : ThreadSide.left;

  @override
  SenderKey get sender => mine == true ? 'me' : 'other:${fromName ?? ''}';
}

/// Octo's bubble for a task: live while running, then its result. One key
/// for both, so it changes in place.
final class OctoTaskItem extends ThreadItem {
  const OctoTaskItem({
    required super.key,
    required super.at,
    required this.task,
  });

  final Task task;

  TaskPhase get phase => task.phase;

  @override
  ThreadSide get side => ThreadSide.left;

  @override
  SenderKey get sender => 'octo';
}

/// A text bubble from Octo that this app wrote (the welcome).
final class OctoNoteItem extends ThreadItem {
  const OctoNoteItem({
    required super.key,
    required super.at,
    required this.text,
  });

  final String text;

  @override
  ThreadSide get side => ThreadSide.left;

  @override
  SenderKey get sender => 'octo';
}

enum ImageSource { octo, her }

final class ImageItem extends ThreadItem {
  const ImageItem({
    required super.key,
    required super.at,
    required this.shot,
    required this.source,
    this.caption,
  });

  final ShotRef shot;
  final ImageSource source;
  final String? caption;

  @override
  ThreadSide get side => ThreadSide.left;

  @override
  SenderKey get sender => source == ImageSource.octo ? 'octo' : 'mom';
}

/// Something Mom sent ("Send to Harsh"), with Octo's answer to her and the
/// Reply / "Octo, do it" actions.
final class TodoItem extends ThreadItem {
  const TodoItem({
    required super.key,
    required super.at,
    required this.todo,
    required this.otherReplies,
  });

  final Todo todo;

  /// Replies from other helpers (yours are your own bubbles).
  final List<Reply> otherReplies;

  @override
  ThreadSide get side => ThreadSide.left;

  @override
  SenderKey get sender => 'mom';
}

/// Mom asked for help.
final class HelpItem extends ThreadItem {
  const HelpItem({
    required super.key,
    required super.at,
    this.text,
    required this.active,
  });

  final String? text;

  /// Still asking (the newest request, not yet handled).
  final bool active;

  @override
  ThreadSide get side => ThreadSide.left;

  @override
  SenderKey get sender => 'mom';
}

/// A message to Mom: yours (right), or another helper's from the log (left).
final class MessageItem extends ThreadItem {
  const MessageItem({
    required super.key,
    required super.at,
    required this.text,
    required this.mine,
    this.fromName,
    this.outboxId,
    this.delivery,
    this.replyToTodo,
  });

  final String text;
  final bool mine;
  final String? fromName;
  final String? outboxId;
  final OutboxState? delivery;

  /// The to-do this answers, for a small quote.
  final String? replyToTodo;

  @override
  ThreadSide get side => mine ? ThreadSide.right : ThreadSide.left;

  @override
  SenderKey get sender => mine ? 'me' : 'other:${fromName ?? ''}';
}

enum SystemKind {
  /// From a log entry (pairing, rules): the entry's own text.
  log,

  /// "Asked Mom to show her screen".
  askedScreen,

  /// "Mom said no to showing her screen".
  screenRefused,
}

/// A centred grey line.
final class SystemItem extends ThreadItem {
  const SystemItem({
    required super.key,
    required super.at,
    required this.kind,
    this.text,
    this.delivery,
  });

  final SystemKind kind;
  final String? text;
  final OutboxState? delivery;

  @override
  ThreadSide get side => ThreadSide.center;

  @override
  SenderKey get sender => 'center';
}

/// A time between groups, as Messages shows.
final class TimestampItem extends ThreadItem {
  const TimestampItem({required super.key, required super.at});

  @override
  ThreadSide get side => ThreadSide.center;

  @override
  SenderKey get sender => 'center';
}

/// An item with its place in a group: the tail goes on the last bubble; the
/// sender's name on the first.
class ThreadEntry {
  const ThreadEntry(
    this.item, {
    required this.firstInGroup,
    required this.lastInGroup,
  });

  final ThreadItem item;
  final bool firstInGroup;
  final bool lastInGroup;
}

/// Gap that starts a new group.
const groupGap = Duration(minutes: 5);

/// Gap that gets a timestamp line.
const timestampGap = Duration(minutes: 15);

/// How close a log `message` must be to a local one to be the same message.
const _sameMessageWindow = Duration(minutes: 2);

/// Builds a thread from a session (PLAN §3.7). Pure: the same data gives the
/// same items with the same keys.
List<ThreadEntry> projectThread(SessionData data, MeIdentity me) {
  final items = <_Sortable>[];
  final myHelperId = me.helperId ?? data.myHelperId;
  void add(ThreadItem item, int order, [int sub = 0]) =>
      items.add(_Sortable(item, order, sub));

  // Rows this phone sent, by the task they created.
  final rowsByTask = <String, OutboxRow>{};
  final localMessages = <OutboxRow>[];
  for (final row in data.outbox.values) {
    if (row.taskId != null) rowsByTask[row.taskId!] = row;
    if (row.kind == OutboxKind.message || row.kind == OutboxKind.todoReply) {
      localMessages.add(row);
    }
  }
  const outboxOrder = 1 << 40;

  // Tasks and their requests.
  final linkedRows = <String>{};
  for (final tracked in data.tasks.values) {
    final task = tracked.task;
    final row = rowsByTask[task.id];
    if (row != null) linkedRows.add(row.id);
    final phase = task.phase;
    final requestAt = row?.createdAt ?? task.createdAt ?? 0;
    final bool? mine = row != null
        ? true
        : myHelperId == null || task.from == null
        ? null
        : task.from == myHelperId;
    final line = switch (phase) {
      TaskPhase.queued => RequestLine.waitingTurn,
      TaskPhase.waitingOk => RequestLine.waitingForHer,
      TaskPhase.running ||
      TaskPhase.done ||
      TaskPhase.gaveUp ||
      TaskPhase.blocked ||
      TaskPhase.stopped ||
      TaskPhase.failed when tracked.askedHer => RequestLine.sheSaidOk,
      _ => null,
    };
    add(
      RequestItem(
        key: row != null ? 'out:${row.id}' : 'task:${task.id}:request',
        at: requestAt,
        text: task.text.isNotEmpty ? task.text : (row?.text ?? ''),
        mine: mine,
        fromName: task.fromName,
        job: task.job,
        outboxId: row?.id,
        delivery: row != null && row.state != OutboxState.accepted
            ? row.state
            : null,
        errorMessage: row?.errorMessage,
        taskId: task.id,
        line: line,
        isRetry: row?.retryOf != null,
        taskActive: phase.isActive,
      ),
      row != null ? outboxOrder : tracked.order,
    );
    if (phase == TaskPhase.queued || phase == TaskPhase.waitingOk) continue;
    var octoAt = task.startedAt ?? task.createdAt ?? requestAt;
    if (octoAt < requestAt) octoAt = requestAt;
    add(
      OctoTaskItem(key: 'task:${task.id}:octo', at: octoAt, task: task),
      row != null ? outboxOrder : tracked.order,
      1,
    );
    final shot = tracked.shot;
    if (phase.isEnded && shot != null) {
      add(
        ImageItem(
          key: 'task:${task.id}:shot',
          at: octoAt,
          shot: shot,
          source: ImageSource.octo,
        ),
        row != null ? outboxOrder : tracked.order,
        2,
      );
    }
  }

  // This phone's rows that aren't (yet) a known task.
  for (final row in data.outbox.values) {
    if (linkedRows.contains(row.id)) continue;
    switch (row.kind) {
      case OutboxKind.task:
        add(
          RequestItem(
            key: 'out:${row.id}',
            at: row.createdAt,
            text: row.text ?? '',
            mine: true,
            job: row.job,
            outboxId: row.id,
            delivery: row.state,
            errorMessage: row.errorMessage,
            taskId: row.taskId,
            isRetry: row.retryOf != null,
          ),
          outboxOrder,
        );
      case OutboxKind.message || OutboxKind.todoReply:
        add(
          MessageItem(
            key: 'msg:${row.id}',
            at: row.createdAt,
            text: row.text ?? '',
            mine: true,
            outboxId: row.id,
            delivery: row.state,
            replyToTodo: row.todoId == null
                ? null
                : data.todos[row.todoId]?.todo.text,
          ),
          outboxOrder,
        );
      case OutboxKind.screenRequest:
        add(
          SystemItem(
            key: 'out:${row.id}',
            at: row.createdAt,
            kind: SystemKind.askedScreen,
            delivery: row.state,
          ),
          outboxOrder,
        );
      case OutboxKind.todoDone || OutboxKind.leave:
        break;
    }
  }
  // To-dos and their screenshots.
  bool isMyReply(Reply r) => localMessages.any(
    (row) =>
        row.kind == OutboxKind.todoReply &&
        row.text == r.text &&
        (row.createdAt - r.at).abs() <= _sameMessageWindow.inMilliseconds,
  );
  for (final tracked in data.todos.values) {
    final todo = tracked.todo;
    final shot = tracked.shot;
    if (shot != null) {
      add(
        ImageItem(
          key: 'todo:${todo.id}:shot',
          at: todo.at,
          shot: shot,
          source: ImageSource.her,
          caption: todo.context?.app,
        ),
        tracked.order,
        0,
      );
    }
    add(
      TodoItem(
        key: 'todo:${todo.id}',
        at: todo.at,
        todo: todo,
        otherReplies: [
          for (final r in todo.replies)
            if (!isMyReply(r)) r,
        ],
      ),
      tracked.order,
      1,
    );
  }

  // Help.
  final activeHelpId = data.activeHelp == null
      ? null
      : helpId(data.computerId, data.activeHelp!.since);
  for (final help in data.helps.values) {
    add(
      HelpItem(
        key: 'help:${help.id}',
        at: help.at,
        text: help.text,
        active: help.id == activeHelpId,
      ),
      help.order,
    );
  }

  // Screens (never tied to a particular request: contract question 5).
  for (final screen in data.screens.values) {
    if (screen.ok && screen.shot != null) {
      add(
        ImageItem(
          key: 'screen:${screen.id}',
          at: screen.at,
          shot: screen.shot!,
          source: ImageSource.her,
          caption: screen.app,
        ),
        screen.order,
      );
    } else {
      add(
        SystemItem(
          key: 'screen:${screen.id}',
          at: screen.at,
          kind: SystemKind.screenRefused,
        ),
        screen.order,
      );
    }
  }

  // Log: pairing and rule lines; messages from other helpers.
  for (final record in data.entries.values) {
    final e = record.entry;
    switch (e.kindValue) {
      case EntryKind.pairing || EntryKind.policy:
        add(
          SystemItem(
            key: 'sys:${record.id}',
            at: e.at,
            kind: SystemKind.log,
            text: e.text,
          ),
          record.order,
        );
      case EntryKind.message:
        final byMe = e.by == me.name;
        final matchesLocal = localMessages.any(
          (row) =>
              row.text == e.text &&
              (row.createdAt - e.at).abs() <= _sameMessageWindow.inMilliseconds,
        );
        if (byMe && matchesLocal) continue;
        add(
          MessageItem(
            key: 'msg:${record.id}',
            at: e.at,
            text: e.text,
            mine: byMe,
            fromName: e.by,
          ),
          record.order,
        );
      default:
        // task, step, consent, limit, todo, help, screen: Activity only.
        break;
    }
  }

  // Octo's own notes (the welcome).
  for (final note in data.notes.values) {
    add(
      OctoNoteItem(key: 'note:${note.id}', at: note.at, text: note.text),
      note.order,
    );
  }

  items.sort((a, b) {
    final c = a.item.at.compareTo(b.item.at);
    if (c != 0) return c;
    final o = a.order.compareTo(b.order);
    if (o != 0) return o;
    return a.sub.compareTo(b.sub);
  });

  return _group([for (final s in items) s.item]);
}

List<ThreadEntry> _group(List<ThreadItem> items) {
  final out = <ThreadEntry>[];
  ThreadItem? previous;
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (previous == null ||
        item.at - previous.at >= timestampGap.inMilliseconds) {
      out.add(
        ThreadEntry(
          TimestampItem(key: 'ts:${item.key}', at: item.at),
          firstInGroup: true,
          lastInGroup: true,
        ),
      );
      previous = null;
    }
    final first = !_continues(previous, item);
    final next = i + 1 < items.length ? items[i + 1] : null;
    final last =
        next == null ||
        next.at - item.at >= timestampGap.inMilliseconds ||
        !_continues(item, next);
    out.add(ThreadEntry(item, firstInGroup: first, lastInGroup: last));
    previous = item;
  }
  return out;
}

bool _continues(ThreadItem? a, ThreadItem b) =>
    a != null &&
    a.side != ThreadSide.center &&
    b.side != ThreadSide.center &&
    a.sender == b.sender &&
    b.at - a.at < groupGap.inMilliseconds;

class _Sortable {
  _Sortable(this.item, this.order, this.sub);

  final ThreadItem item;
  final int order;
  final int sub;
}
