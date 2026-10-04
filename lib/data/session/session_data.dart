import '../../protocol/models/entry.dart';
import '../../protocol/models/policy.dart';
import '../../protocol/models/status.dart';
import '../../protocol/models/task.dart';
import '../../protocol/models/todo.dart';
import '../../transport/octo_link.dart';
import '../outbox.dart';
import '../policy_edit.dart';

/// Where a screenshot is, from this phone's point of view. Screenshot bytes
/// never live in session state or the database; they're normalised to one of
/// these first.
sealed class ShotRef {
  const ShotRef();

  /// Encoded for the database `shot` column.
  String encode();

  static ShotRef? decode(String? value) => switch (value) {
    null => null,
    'host' => const HostShot(),
    'unavailable' => const UnavailableShot(),
    _ when value.startsWith('local:') => LocalShot(value.substring(6)),
    _ => null,
  };
}

/// In the app-private screenshot store (or being written to it).
final class LocalShot extends ShotRef {
  const LocalShot(this.id);

  final String id;

  @override
  String encode() => 'local:$id';

  @override
  bool operator ==(Object other) => other is LocalShot && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A path on her computer: "Screenshot on her computer".
final class HostShot extends ShotRef {
  const HostShot();

  @override
  String encode() => 'host';
}

/// Too large, not an image, or already expired when it arrived.
final class UnavailableShot extends ShotRef {
  const UnavailableShot();

  @override
  String encode() => 'unavailable';
}

/// Common bookkeeping for anything shown in the thread: [order] is the
/// insert sequence (ties on `at` keep arrival order); [liveSeq] is the live
/// event that last changed it (0 if only snapshots did).
abstract class Tracked {
  const Tracked({required this.order, required this.liveSeq});

  final int order;
  final int liveSeq;
}

class TrackedTask extends Tracked {
  const TrackedTask({
    required this.task,
    required super.order,
    required super.liveSeq,
    this.shot,
    this.askedHer = false,
  });

  final Task task;
  final ShotRef? shot;

  /// She was asked (the task was seen waiting for her OK), so "Mom said OK"
  /// can be shown once it runs.
  final bool askedHer;
}

class TrackedTodo extends Tracked {
  const TrackedTodo({
    required this.todo,
    required super.order,
    required super.liveSeq,
    this.shot,
  });

  final Todo todo;
  final ShotRef? shot;
}

/// Mom asked for help (live `help`, or `status.help`).
class HelpEvent {
  const HelpEvent({
    required this.id,
    required this.at,
    required this.order,
    this.text,
  });

  final String id;
  final int at;
  final String? text;
  final int order;
}

/// One `screen` message: her screenshot, or her no.
class ScreenEvent {
  const ScreenEvent({
    required this.id,
    required this.at,
    required this.ok,
    required this.order,
    this.shot,
    this.app,
    this.window,
    this.reason,
  });

  final String id;
  final int at;
  final bool ok;
  final ShotRef? shot;
  final String? app;
  final String? window;
  final String? reason;
  final int order;
}

class LogRecord {
  const LogRecord({required this.id, required this.entry, required this.order});

  final String id;
  final Entry entry;
  final int order;
}

/// A line this app adds itself (Octo's welcome after adding a computer).
class LocalNote {
  const LocalNote({
    required this.id,
    required this.at,
    required this.text,
    required this.order,
  });

  final String id;
  final int at;
  final String text;
  final int order;
}

/// Everything known about one computer's conversation. Immutable; changed
/// only by `reduce`.
class SessionData {
  const SessionData({
    required this.computerId,
    this.link = LinkState.offline,
    this.lastSeenAt,
    this.seq = 0,
    this.nextOrder = 1,
    this.refreshSeq,
    this.tasks = const {},
    this.todos = const {},
    this.helps = const {},
    this.activeHelp,
    this.helpLiveSeq = 0,
    this.screens = const {},
    this.entries = const {},
    this.outbox = const {},
    this.notes = const {},
    this.policy,
    this.policyLiveSeq = 0,
    this.policyDeclinedAt,
    this.policyEdit,
    this.status,
    this.myHelperId,
    this.removed = false,
    this.logCursor,
    this.logMayBeIncomplete = false,
  });

  final String computerId;
  final LinkState link;

  /// When her computer was last reachable (epoch ms).
  final int? lastSeenAt;

  /// Count of live events applied; snapshots compare against it.
  final int seq;
  final int nextOrder;

  /// [seq] when the refresh in flight was sent, if any.
  final int? refreshSeq;

  final Map<String, TrackedTask> tasks;
  final Map<String, TrackedTodo> todos;
  final Map<String, HelpEvent> helps;

  /// She's asking for help right now.
  final HelpState? activeHelp;
  final int helpLiveSeq;
  final Map<String, ScreenEvent> screens;
  final Map<String, LogRecord> entries;
  final Map<String, OutboxRow> outbox;
  final Map<String, LocalNote> notes;

  /// The rules her computer last reported.
  final Policy? policy;
  final int policyLiveSeq;

  /// When she last kept the old rule (`policy{declined:true}`).
  final int? policyDeclinedAt;

  /// The rules edit in flight, if any (one per computer).
  final PolicyEdit? policyEdit;

  /// The last `status` snapshot (jobs, helpers, busy…).
  final ComputerStatus? status;

  /// This phone's helper id on her computer, once known.
  final String? myHelperId;

  /// Her computer removed this phone.
  final bool removed;

  /// Largest `at` of the stored log; the next `log` request starts here.
  final int? logCursor;

  /// Paging stopped without progress; older activity may be missing.
  final bool logMayBeIncomplete;

  SessionData copyWith({
    LinkState? link,
    int? lastSeenAt,
    int? seq,
    int? nextOrder,
    int? Function()? refreshSeq,
    Map<String, TrackedTask>? tasks,
    Map<String, TrackedTodo>? todos,
    Map<String, HelpEvent>? helps,
    HelpState? Function()? activeHelp,
    int? helpLiveSeq,
    Map<String, ScreenEvent>? screens,
    Map<String, LogRecord>? entries,
    Map<String, OutboxRow>? outbox,
    Map<String, LocalNote>? notes,
    Policy? policy,
    int? policyLiveSeq,
    int? Function()? policyDeclinedAt,
    PolicyEdit? Function()? policyEdit,
    ComputerStatus? status,
    String? myHelperId,
    bool? removed,
    int? logCursor,
    bool? logMayBeIncomplete,
  }) => SessionData(
    computerId: computerId,
    link: link ?? this.link,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    seq: seq ?? this.seq,
    nextOrder: nextOrder ?? this.nextOrder,
    refreshSeq: refreshSeq == null ? this.refreshSeq : refreshSeq(),
    tasks: tasks ?? this.tasks,
    todos: todos ?? this.todos,
    helps: helps ?? this.helps,
    activeHelp: activeHelp == null ? this.activeHelp : activeHelp(),
    helpLiveSeq: helpLiveSeq ?? this.helpLiveSeq,
    screens: screens ?? this.screens,
    entries: entries ?? this.entries,
    outbox: outbox ?? this.outbox,
    notes: notes ?? this.notes,
    policy: policy ?? this.policy,
    policyLiveSeq: policyLiveSeq ?? this.policyLiveSeq,
    policyDeclinedAt: policyDeclinedAt == null
        ? this.policyDeclinedAt
        : policyDeclinedAt(),
    policyEdit: policyEdit == null ? this.policyEdit : policyEdit(),
    status: status ?? this.status,
    myHelperId: myHelperId ?? this.myHelperId,
    removed: removed ?? this.removed,
    logCursor: logCursor ?? this.logCursor,
    logMayBeIncomplete: logMayBeIncomplete ?? this.logMayBeIncomplete,
  );

  /// The outbox row that created [taskId], if this phone sent it.
  OutboxRow? outboxForTask(String taskId) {
    for (final row in outbox.values) {
      if (row.taskId == taskId) return row;
    }
    return null;
  }
}
