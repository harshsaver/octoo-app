import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/data/outbox.dart';
import 'package:octo_family/data/session/reducer.dart';
import 'package:octo_family/data/session/session_data.dart';
import 'package:octo_family/protocol/models/entry.dart';
import 'package:octo_family/protocol/models/policy.dart';
import 'package:octo_family/protocol/models/status.dart';
import 'package:octo_family/protocol/models/task.dart';
import 'package:octo_family/protocol/models/todo.dart';

Task _task(
  String status, {
  String id = 't1',
  int steps = 0,
  String? result,
  String? from,
}) => Task(
  id: id,
  text: 'Check the Wi-Fi',
  status: status,
  from: from,
  steps: [for (var i = 1; i <= steps; i++) TaskStep(n: i)],
  result: result,
  createdAt: 1000,
);

SessionData _run(List<SessionEvent> events, [SessionData? start]) =>
    events.fold(start ?? const SessionData(computerId: 'c1'), reduce);

void main() {
  group('live events', () {
    test('a task message fully replaces the stored task', () {
      final s = _run([
        TaskReceived(_task('running', steps: 2), null),
        TaskReceived(_task('running', steps: 3), null),
      ]);
      expect(s.tasks['t1']!.task.steps, hasLength(3));
      expect(s.tasks.length, 1);
    });

    test('a later end status replaces an earlier one, with its result', () {
      final s = _run([
        TaskReceived(_task('stopped', result: 'Stopped by Priya.'), null),
        TaskReceived(_task('done', result: 'Done: text is bigger now.'), null),
      ]);
      expect(s.tasks['t1']!.task.phase, TaskPhase.done);
      expect(s.tasks['t1']!.task.result, 'Done: text is bigger now.');
    });

    test('waiting for her is remembered so "Mom said OK" can show', () {
      final s = _run([
        TaskReceived(_task('waitingOk'), null),
        TaskReceived(_task('running'), null),
      ]);
      expect(s.tasks['t1']!.askedHer, isTrue);
    });

    test('order is kept across updates', () {
      final s = _run([
        TaskReceived(_task('queued', id: 'a'), null),
        TaskReceived(_task('queued', id: 'b'), null),
        TaskReceived(_task('running', id: 'a'), null),
      ]);
      expect(s.tasks['a']!.order, lessThan(s.tasks['b']!.order));
    });
  });

  group('snapshots (source-aware)', () {
    test('a live event after the refresh was sent beats the snapshot', () {
      final s = _run([
        const RefreshStarted(),
        TaskReceived(_task('running', steps: 2), null),
        StatusSnapshot(
          ComputerStatus(task: _task('running', steps: 1)),
          refreshSeq: 0,
        ),
      ]);
      expect(s.tasks['t1']!.task.steps, hasLength(2));
    });

    test('a snapshot updates what no live event touched since', () {
      final s = _run([
        TaskReceived(_task('running', steps: 1), null),
        const RefreshStarted(),
        StatusSnapshot(
          ComputerStatus(recent: [_task('done', result: 'Done.')]),
          refreshSeq: 1,
        ),
      ]);
      expect(s.tasks['t1']!.task.phase, TaskPhase.done);
    });

    test('a snapshot never turns an ended task back into an active one', () {
      final stored = SessionData(
        computerId: 'c1',
        tasks: {'t1': TrackedTask(task: _task('done'), order: 1, liveSeq: 0)},
      );
      final s = _run([
        StatusSnapshot(ComputerStatus(task: _task('running')), refreshSeq: 5),
      ], stored);
      expect(s.tasks['t1']!.task.phase, TaskPhase.done);
    });

    test('a snapshot never deletes history it no longer lists', () {
      final s = _run([
        TaskReceived(_task('done', id: 'old'), null),
        const StatusSnapshot(ComputerStatus(), refreshSeq: 1),
      ]);
      expect(s.tasks.containsKey('old'), isTrue);
    });

    test('to-dos follow the same rule', () {
      const todo = Todo(id: 'd1', at: 1, text: 'Is this safe?');
      final s = _run([
        const RefreshStarted(),
        TodoReceived(todo.copyWith(done: true), null),
        const TodosSnapshot([todo], refreshSeq: 0),
      ]);
      expect(s.todos['d1']!.todo.done, isTrue);
      final fresh = _run([
        const TodosSnapshot([todo], refreshSeq: 0),
      ]);
      expect(fresh.todos['d1']!.todo.text, 'Is this safe?');
    });

    test('help: a live help after the refresh beats status.help == null', () {
      final s = _run([
        const RefreshStarted(),
        const HelpReceived(5000, "The printer isn't working"),
        const StatusSnapshot(ComputerStatus(), refreshSeq: 0),
      ]);
      expect(s.activeHelp?.since, 5000);
      final cleared = _run([
        const HelpReceived(5000, 'x'),
        const RefreshStarted(),
        const StatusSnapshot(ComputerStatus(), refreshSeq: 1),
      ]);
      expect(cleared.activeHelp, isNull);
      expect(
        cleared.helps,
        hasLength(1),
        reason: 'the bubble stays in history',
      );
    });

    test('help from status and from a live event are one bubble', () {
      final s = _run([
        const HelpReceived(5000, 'Printer'),
        const StatusSnapshot(
          ComputerStatus(help: HelpState(since: 5000)),
          refreshSeq: 1,
        ),
      ]);
      expect(s.helps, hasLength(1));
      expect(s.helps.values.single.text, 'Printer');
    });

    test('policy: a live policy after the refresh beats status.policy', () {
      final s = _run([
        const RefreshStarted(),
        const PolicyReceived(
          Policy(askBeforeLooking: true),
          declined: false,
          at: 1,
        ),
        const StatusSnapshot(ComputerStatus(policy: Policy()), refreshSeq: 0),
      ]);
      expect(s.policy!.askBeforeLooking, isTrue);
    });
  });

  test('this phone learns its helper id from a task it created', () {
    final row = OutboxRow(
      id: 'o1',
      computerId: 'c1',
      kind: OutboxKind.task,
      payload: const {'text': 'x'},
      state: OutboxState.accepted,
      taskId: 't1',
      createdAt: 1,
      updatedAt: 1,
    );
    final s = _run([
      OutboxUpserted(row),
      TaskReceived(_task('queued', from: 'u_me'), null),
      TaskReceived(_task('queued', id: 't2', from: 'u_priya'), null),
    ]);
    expect(s.myHelperId, 'u_me');

    // Also when the result arrives after the task.
    final late = _run([
      TaskReceived(_task('queued', from: 'u_me'), null),
      OutboxUpserted(row),
    ]);
    expect(late.myHelperId, 'u_me');
  });

  test(
    'log entries are deduplicated by stable id; the cursor moves with them',
    () {
      const e = Entry(
        at: 10,
        kind: 'pairing',
        by: 'Mom',
        text: "Harsh's iPhone was added",
      );
      final s = _run([
        const LogReceived([e], cursor: 10),
        const LogReceived([e], cursor: 10),
      ]);
      expect(s.entries, hasLength(1));
      expect(s.logCursor, 10);
    },
  );

  test('screens are kept one per message; removed is remembered', () {
    final s = _run([const RemovedReceived()]);
    expect(s.removed, isTrue);
  });
}
