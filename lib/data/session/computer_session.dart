import 'dart:async';

import 'package:clock/clock.dart';
import 'package:uuid/uuid.dart';

import '../../protocol/app_message.dart';
import '../../protocol/host_message.dart';
import '../../protocol/models/policy.dart';
import '../../protocol/models/status.dart';
import '../../protocol/models/todo.dart';
import '../../protocol/pending.dart';
import '../../transport/octo_link.dart';
import '../outbox.dart';
import '../policy_edit.dart';
import '../screenshot_store.dart';
import 'reducer.dart';
import 'session_data.dart';
import 'session_store.dart';

/// The outcome of asking her computer to stop a task.
enum StopOutcome { stopped, offline, refused, noReply }

/// The outcome of sending a rules edit. [sent] means only that her computer
/// accepted the request; labels change when the policy itself arrives.
sealed class PolicySetOutcome {
  const PolicySetOutcome();
}

final class PolicySent extends PolicySetOutcome {
  const PolicySent();
}

/// Another edit is still in flight, or nothing changed.
final class PolicyNotSent extends PolicySetOutcome {
  const PolicyNotSent();
}

final class PolicyOffline extends PolicySetOutcome {
  const PolicyOffline();
}

/// Her computer refused it; show [message].
final class PolicyRefused extends PolicySetOutcome {
  const PolicyRefused(this.message);

  final String? message;
}

final class PolicyNoReply extends PolicySetOutcome {
  const PolicyNoReply();
}

/// One paired computer's conversation: the link, request matching, the
/// reducer and write-through storage (PLAN §3.3).
///
/// Connect sequence, once per connection: subscribe to messages → send
/// `status`, `todos` and `log` and apply the replies as snapshots → drain the
/// outbox.
class ComputerSession {
  ComputerSession({
    required this.computerId,
    required this.link,
    required this.store,
    required this.shots,
    this.bind,
    this.requestTimeout = const Duration(seconds: 20),
    this.logPageSize = 100,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid(),
       _data = SessionData(computerId: computerId);

  final String computerId;
  final OctoLink link;
  final SessionStore store;
  final ScreenshotStore shots;

  /// The pairing this phone holds; outbox rows from another pairing are
  /// dropped, never sent.
  final String? bind;
  final Duration requestTimeout;
  final int logPageSize;
  final Uuid _uuid;

  SessionData _data;
  final _changes = StreamController<SessionData>.broadcast(sync: true);
  StreamSubscription<Map<String, Object?>>? _messagesSub;
  StreamSubscription<LinkState>? _linkSub;
  RequestMatcher? _matcher;
  Future<void> _writes = Future.value();
  int _epoch = 0;
  bool _draining = false;
  bool _drainAgain = false;
  bool _disposed = false;

  /// Messages ignored because this version can't read them.
  int ignoredMessages = 0;

  SessionData get data => _data;

  /// Every new state, synchronously after it's applied.
  Stream<SessionData> get changes => _changes.stream;

  bool get isConnected => _data.link == LinkState.connected && _matcher != null;

  /// Loads stored state. Rows caught mid-send by a crash become uncertain;
  /// rows from an older pairing are dropped.
  Future<void> open() async {
    final stored = await store.load(computerId);
    var data = hydrate(computerId, stored);
    final now = _now();
    final recovered = <String, OutboxRow>{};
    final dropped = <String>[];
    for (final row in data.outbox.values) {
      if (row.bind != bind) {
        dropped.add(row.id);
        continue;
      }
      recovered[row.id] = OutboxTransitions.recover(row, at: now);
    }
    final before = data;
    data = data.copyWith(outbox: recovered);
    _data = data;
    final write = diffSession(before, data);
    if (!write.isEmpty || dropped.isNotEmpty) {
      await store.write(
        SessionWrite(outbox: write.outbox, outboxDeletes: dropped),
      );
    }
    _messagesSub = link.messages(computerId).listen(_onRaw);
    _emit();
  }

  /// Starts (or keeps) the connection. Reconnects are the link's job.
  void connect() {
    if (_disposed || _linkSub != null || _data.removed) return;
    _linkSub = link.connect(computerId).listen(_onLinkState);
  }

  /// Ends the connection (app in the background).
  Future<void> disconnect() async {
    final sub = _linkSub;
    _linkSub = null;
    await sub?.cancel();
    _endEpoch();
    if (_data.link != LinkState.offline) {
      _apply(LinkChanged(LinkState.offline, _now()));
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _linkSub?.cancel();
    await _messagesSub?.cancel();
    _endEpoch();
    await _writes;
    await _changes.close();
  }

  /// Waits until every change so far is stored.
  Future<void> flush() => _writes;

  // ---------------------------------------------------------------------
  // Actions (everything typed goes through the outbox)

  Future<OutboxRow> askOcto(String text, {String? job, String? retryOf}) {
    _apply(const HelpHandled());
    return _enqueue(OutboxKind.task, {
      'text': text,
      'job': ?job,
    }, retryOf: retryOf);
  }

  Future<OutboxRow> tellMom(String text) {
    _apply(const HelpHandled());
    return _enqueue(OutboxKind.message, {'text': text});
  }

  Future<OutboxRow> replyToTodo(String todoId, String text) =>
      _enqueue(OutboxKind.todoReply, {'todoId': todoId, 'text': text});

  Future<OutboxRow> markTodoDone(String todoId) =>
      _enqueue(OutboxKind.todoDone, {'todoId': todoId});

  Future<OutboxRow> requestScreen() {
    _apply(const HelpHandled());
    return _enqueue(OutboxKind.screenRequest, const {});
  }

  /// "Try again" on a task: a new task (it may run twice).
  Future<OutboxRow?> tryAgain(String outboxId) async {
    final row = _data.outbox[outboxId];
    final text = row?.text;
    if (row == null || text == null || row.kind != OutboxKind.task) return null;
    return askOcto(text, job: row.job, retryOf: row.id);
  }

  /// Removes a row that won't be sent (pending, uncertain or rejected).
  Future<void> discard(String outboxId) async {
    final row = _data.outbox[outboxId];
    if (row == null || row.state == OutboxState.attempting) return;
    _apply(OutboxRemoved(outboxId));
    await _writes;
  }

  /// Stop works on anyone's task. Not queued: a stop only makes sense now.
  Future<StopOutcome> stopTask(String taskId) async {
    final matcher = _matcher;
    if (matcher == null || !isConnected) return StopOutcome.offline;
    final request = TaskStop(requestId: _uuid.v4(), taskId: taskId);
    try {
      final reply = await matcher.request(
        request,
        () => link.send(computerId, request.toJson()),
      );
      return reply is ResultMessage && reply.ok
          ? StopOutcome.stopped
          : StopOutcome.refused;
    } on RequestFailure catch (f) {
      return f.kind == RequestFailureKind.sendFailed
          ? StopOutcome.offline
          : StopOutcome.noReply;
    }
  }

  /// Adds a line written by this app (Octo's welcome).
  Future<void> addNote(String id, String text) async {
    _apply(NoteAdded(id: id, at: _now(), text: text));
    await _writes;
  }

  /// Sends the whole proposed policy in one `policy.set` (PLAN §3.8 Rules).
  /// Only one edit is in flight per computer. On an error or no reply the
  /// pending labels go away (the switches never moved).
  Future<PolicySetOutcome> setPolicy(Policy proposed) async {
    final active = _data.policy ?? _data.status?.policy ?? const Policy();
    if (_data.policyEdit != null) return const PolicyNotSent();
    final pending = diffPolicy(active, proposed);
    if (pending.isEmpty) return const PolicyNotSent();
    final matcher = _matcher;
    if (matcher == null || !isConnected) return const PolicyOffline();
    _apply(
      PolicyEditStarted(
        PolicyEdit(proposed: proposed, pending: pending, startedAt: _now()),
      ),
    );
    final request = PolicySet(requestId: _uuid.v4(), policy: proposed);
    try {
      final reply = await matcher.request(
        request,
        () => link.send(computerId, request.toJson()),
      );
      if (reply is ResultMessage && !reply.ok) {
        _apply(const PolicyEditEnded());
        return PolicyRefused(reply.message);
      }
      return const PolicySent();
    } on RequestFailure catch (f) {
      _apply(const PolicyEditEnded());
      return f.kind == RequestFailureKind.sendFailed
          ? const PolicyOffline()
          : const PolicyNoReply();
    }
  }

  /// Sends `profile.set` and waits for the result. Stage 2 sends it once at
  /// setup; the full PATCH-then-sync loop comes with Details (stage 3).
  Future<bool> sendProfile({
    String? person,
    String? computer,
    String? language,
  }) async {
    final matcher = _matcher;
    if (matcher == null) return false;
    final request = ProfileSet(
      requestId: _uuid.v4(),
      person: person,
      computer: computer,
      language: language,
    );
    try {
      final reply = await matcher.request(
        request,
        () => link.send(computerId, request.toJson()),
      );
      return reply is ResultMessage && reply.ok;
    } on RequestFailure {
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Incoming

  void _onRaw(Map<String, Object?> raw) {
    if (_disposed) return;
    final message = parseHostMessage(raw);
    if (_matcher?.offer(message) ?? false) return;
    final now = _now();
    switch (message) {
      case TaskMessage(:final task):
        final shot = shots.accept(
          task.screenshot,
          at: task.endedAt ?? task.createdAt ?? now,
          computerId: computerId,
        );
        _apply(TaskReceived(task, shot));
      case TodoMessage(:final todo):
        _apply(
          TodoReceived(
            todo,
            shots.accept(todo.screenshot, at: todo.at, computerId: computerId),
          ),
        );
      case HelpMessage(:final at, :final text):
        _apply(HelpReceived(at, text));
      case ScreenMessage():
        final shot = shots.accept(
          message.screenshot,
          at: message.at ?? now,
          computerId: computerId,
        );
        _apply(ScreenReceived(message, shot, now));
      case PolicyMessage(:final policy, :final declined):
        _apply(PolicyReceived(policy, declined: declined, at: now));
      case RemovedMessage():
        _apply(const RemovedReceived());
        unawaited(disconnect());
      case StatusMessage(:final status):
        _applyStatus(status, refreshSeq: null);
      case TodosMessage(:final todos):
        _applyTodos(todos, refreshSeq: null);
      case LogMessage(:final entries):
        _apply(LogReceived(entries));
      case ResultMessage():
        // A late result (after its timeout, or from an earlier connection).
        final row = _data.outboxByRequestId(message.requestId);
        if (row != null) {
          _apply(
            OutboxUpserted(OutboxTransitions.result(row, message, at: now)),
          );
        }
      case UnknownHostMessage():
        // Ignored, and never logged with its content.
        ignoredMessages++;
      case PairCodeMessage() || PairDoneMessage() || PairFailedMessage():
        break;
    }
  }

  void _onLinkState(LinkState state) {
    if (_disposed) return;
    if (state == LinkState.connected) {
      _endEpoch();
      _matcher = RequestMatcher(defaultTimeout: requestTimeout);
      _apply(LinkChanged(state, _now()));
      unawaited(_onConnected(++_epoch));
    } else {
      _endEpoch();
      _apply(LinkChanged(state, _now()));
    }
  }

  void _endEpoch() {
    _matcher?.close();
    _matcher = null;
    _epoch++;
  }

  Future<void> _onConnected(int epoch) async {
    // 1. Snapshots, recorded against the live sequence at send time.
    _apply(const RefreshStarted());
    final since = _data.seq;
    try {
      final status = await _request(StatusRequest(requestId: _uuid.v4()));
      if (epoch != _epoch) return;
      if (status is StatusMessage) {
        _applyStatus(status.status, refreshSeq: since);
      }
      final todos = await _request(TodosRequest(requestId: _uuid.v4()));
      if (epoch != _epoch) return;
      if (todos is TodosMessage) _applyTodos(todos.todos, refreshSeq: since);
    } on RequestFailure {
      if (epoch != _epoch) return;
    } finally {
      if (epoch == _epoch) _apply(const RefreshEnded());
    }
    // 2. The activity log.
    try {
      await _syncLog(epoch);
    } on RequestFailure {
      if (epoch != _epoch) return;
    }
    // 3. Anything typed while offline.
    if (epoch == _epoch) await _drain();
  }

  Future<HostReply> _request(AppRequest request) {
    final matcher = _matcher;
    if (matcher == null) {
      return Future.error(
        RequestFailure(RequestFailureKind.disconnected, request.requestId),
      );
    }
    return matcher.request(
      request,
      () => link.send(computerId, request.toJson()),
    );
  }

  void _applyStatus(ComputerStatus status, {required int? refreshSeq}) {
    final now = _now();
    final shotsByTask = <String, ShotRef?>{
      for (final t in [?status.task, ...status.queued, ...status.recent])
        if (t.screenshot != null)
          t.id: shots.accept(
            t.screenshot,
            at: t.endedAt ?? t.createdAt ?? now,
            computerId: computerId,
          ),
    };
    _apply(
      StatusSnapshot(status, refreshSeq: refreshSeq, taskShots: shotsByTask),
    );
  }

  void _applyTodos(List<Todo> todos, {required int? refreshSeq}) {
    _apply(
      TodosSnapshot(
        todos,
        refreshSeq: refreshSeq,
        shots: {
          for (final t in todos)
            if (t.screenshot != null)
              t.id: shots.accept(
                t.screenshot,
                at: t.at,
                computerId: computerId,
              ),
        },
      ),
    );
  }

  /// Pages the activity log from the stored cursor (PLAN §3.4). Stops when a
  /// page is short, or when a full page brings nothing new (then older
  /// activity may be missing; the cursor never skips unseen entries).
  Future<void> _syncLog(int epoch) async {
    for (var page = 0; page < 50; page++) {
      final since = _data.logCursor;
      final reply = await _request(
        LogRequest(requestId: _uuid.v4(), since: since, limit: logPageSize),
      );
      if (epoch != _epoch || reply is! LogMessage) return;
      final entries = reply.entries;
      final fresh = entries
          .where((e) => !_data.entries.containsKey(entryId(computerId, e)))
          .length;
      var cursor = since;
      for (final e in entries) {
        if (cursor == null || e.at > cursor) cursor = e.at;
      }
      final full = entries.length >= logPageSize;
      final stuck = full && fresh == 0;
      _apply(
        LogReceived(entries, cursor: cursor, incomplete: stuck ? true : null),
      );
      if (!full || stuck) return;
    }
  }

  // ---------------------------------------------------------------------
  // Outbox

  Future<OutboxRow> _enqueue(
    OutboxKind kind,
    Map<String, Object?> payload, {
    String? retryOf,
  }) async {
    final now = _now();
    final row = OutboxRow(
      id: _uuid.v4(),
      computerId: computerId,
      bind: bind,
      kind: kind,
      payload: payload,
      state: OutboxState.pending,
      createdAt: now,
      updatedAt: now,
      retryOf: retryOf,
    );
    _apply(OutboxUpserted(row));
    await _writes;
    unawaited(_drain());
    return row;
  }

  /// Sends pending rows in order, one at a time. `attempting` (with the
  /// requestId and exact payload) is stored before each send.
  Future<void> _drain() async {
    if (_draining) {
      _drainAgain = true;
      return;
    }
    _draining = true;
    try {
      do {
        _drainAgain = false;
        for (final row in _data.pendingOutbox) {
          final matcher = _matcher;
          if (matcher == null || _disposed) return;
          final attempt = OutboxTransitions.attempt(
            row,
            requestId: row.kind.waitsForResult ? _uuid.v4() : null,
            at: _now(),
          );
          _apply(OutboxUpserted(attempt));
          await _writes;
          if (row.kind.waitsForResult) {
            final request = TaskCreate(
              requestId: attempt.requestId!,
              text: attempt.text ?? '',
              job: attempt.job,
            );
            try {
              final reply = await matcher.request(
                request,
                () => link.send(computerId, attempt.wireMessage),
              );
              final current = _data.outbox[row.id];
              if (current != null && reply is ResultMessage) {
                _apply(
                  OutboxUpserted(
                    OutboxTransitions.result(current, reply, at: _now()),
                  ),
                );
              }
            } on RequestFailure catch (failure) {
              final current = _data.outbox[row.id];
              if (current == null) continue;
              final next = OutboxTransitions.requestFailed(
                current,
                failure,
                at: _now(),
              );
              _apply(OutboxUpserted(next));
              if (next.state == OutboxState.pending) return; // the link is down
            }
          } else {
            Object? error;
            try {
              await link.send(computerId, attempt.wireMessage);
            } on Object catch (e) {
              error = e;
            }
            final current = _data.outbox[row.id];
            if (current == null) continue;
            final next = OutboxTransitions.sendFinished(
              current,
              error,
              at: _now(),
            );
            _apply(OutboxUpserted(next));
            if (next.state == OutboxState.pending) return;
          }
          await _writes;
        }
      } while (_drainAgain);
    } finally {
      _draining = false;
    }
  }

  // ---------------------------------------------------------------------

  void _apply(SessionEvent event) {
    if (_disposed) return;
    final before = _data;
    final after = reduce(before, event);
    if (identical(before, after)) return;
    _data = after;
    final write = diffSession(before, after);
    if (!write.isEmpty) {
      _writes = _writes.then((_) => store.write(write)).catchError((Object _) {
        // Storage failures don't stop the conversation; the state stays in
        // memory and the next change writes again.
      });
    }
    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(_data);
  }

  int _now() => clock.now().millisecondsSinceEpoch;
}
