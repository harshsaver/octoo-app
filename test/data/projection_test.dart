import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/data/outbox.dart';
import 'package:octo_family/data/session/reducer.dart';
import 'package:octo_family/data/session/session_data.dart';
import 'package:octo_family/data/thread/projection.dart';
import 'package:octo_family/protocol/host_message.dart';
import 'package:octo_family/protocol/models/entry.dart';
import 'package:octo_family/protocol/models/task.dart';
import 'package:octo_family/protocol/models/todo.dart';

const _me = MeIdentity(name: 'Harsh');
const _min = 60 * 1000;

OutboxRow _row(
  String id,
  OutboxKind kind,
  String text, {
  OutboxState state = OutboxState.pending,
  String? taskId,
  int at = 1000,
  String? todoId,
}) => OutboxRow(
  id: id,
  computerId: 'c1',
  kind: kind,
  payload: {'text': text, 'todoId': ?todoId},
  state: state,
  taskId: taskId,
  createdAt: at,
  updatedAt: at,
);

Task _task(
  String id,
  String status, {
  String? from,
  String? fromName,
  int at = 1000,
  String? result,
}) => Task(
  id: id,
  text: 'Install Zoom',
  status: status,
  from: from,
  fromName: fromName,
  createdAt: at,
  startedAt: status == 'queued' || status == 'waitingOk' ? null : at + 10,
  result: result,
);

List<ThreadItem> _items(SessionData s, [MeIdentity me = _me]) => [
  for (final e in projectThread(s, me))
    if (e.item is! TimestampItem) e.item,
];

SessionData _run(List<SessionEvent> events) =>
    events.fold(const SessionData(computerId: 'c1'), reduce);

void main() {
  test(
    'an optimistic request keeps its key once the task is known; no duplicate',
    () {
      final pending = _run([
        OutboxUpserted(_row('o1', OutboxKind.task, 'Install Zoom')),
      ]);
      final before = _items(pending);
      expect(before.single.key, 'out:o1');
      expect((before.single as RequestItem).delivery, OutboxState.pending);

      final accepted = _run([
        OutboxUpserted(
          _row(
            'o1',
            OutboxKind.task,
            'Install Zoom',
            state: OutboxState.accepted,
            taskId: 't1',
          ),
        ),
        TaskReceived(_task('t1', 'waitingOk'), null),
      ]);
      final after = _items(accepted);
      expect(after.whereType<RequestItem>().single.key, 'out:o1');
      expect(
        after.whereType<RequestItem>().single.line,
        RequestLine.waitingForHer,
      );
      expect(after.whereType<RequestItem>().single.delivery, isNull);
      expect(after.whereType<RequestItem>().single.mine, isTrue);
    },
  );

  test('the live bubble becomes the result in place, then the screenshot', () {
    final running = _run([
      TaskReceived(
        _task('t1', 'running', from: 'u_x', fromName: 'Priya'),
        null,
      ),
    ]);
    final r = _items(running);
    expect(r.map((i) => i.key), ['task:t1:request', 'task:t1:octo']);
    final done = _run([
      TaskReceived(
        _task('t1', 'running', from: 'u_x', fromName: 'Priya'),
        null,
      ),
      TaskReceived(
        _task(
          't1',
          'done',
          from: 'u_x',
          fromName: 'Priya',
          result: 'Installed.',
        ),
        const LocalShot('abc'),
      ),
    ]);
    final d = _items(done);
    expect(d.map((i) => i.key), [
      'task:t1:request',
      'task:t1:octo',
      'task:t1:shot',
    ]);
    expect((d[1] as OctoTaskItem).phase, TaskPhase.done);
  });

  test('ownership: mine, another helper\'s, and unknown (left, named)', () {
    final s = _run([
      TaskReceived(
        _task('t1', 'running', from: 'u_me', fromName: 'Harsh'),
        null,
      ),
      TaskReceived(
        _task('t2', 'running', from: 'u_priya', fromName: 'Priya', at: 2000),
        null,
      ),
    ]);
    final unknown = _items(s).whereType<RequestItem>().toList();
    expect(unknown.map((r) => r.mine), [null, null]);
    expect(unknown.map((r) => r.side), [ThreadSide.left, ThreadSide.left]);

    final known = _items(
      s,
      const MeIdentity(name: 'Harsh', helperId: 'u_me'),
    ).whereType<RequestItem>().toList();
    expect(known.map((r) => r.mine), [true, false]);
    expect(known[1].fromName, 'Priya');
  });

  test('queued and waiting tasks have no Octo bubble yet', () {
    final s = _run([TaskReceived(_task('t1', 'queued'), null)]);
    expect(_items(s).single, isA<RequestItem>());
    expect((_items(s).single as RequestItem).line, RequestLine.waitingTurn);
  });

  test('screens are separate items, never answers to a request', () {
    final s = _run([
      OutboxUpserted(_row('o1', OutboxKind.screenRequest, '')),
      ScreenReceived(
        const ScreenMessage(ok: true, at: 2000),
        const LocalShot('s1'),
        2000,
      ),
      ScreenReceived(
        const ScreenMessage(ok: false, at: 3000, reason: 'She said no.'),
        null,
        3000,
      ),
    ]);
    final items = _items(s);
    expect((items[0] as SystemItem).kind, SystemKind.askedScreen);
    expect(items[1], isA<ImageItem>());
    expect((items[2] as SystemItem).kind, SystemKind.screenRefused);
  });

  test('log: pairing and rules become system lines; task/step lines stay in Activity', () {
    final s = _run([
      const LogReceived([
        Entry(
          at: 1,
          kind: 'pairing',
          by: 'Mom',
          text: "Harsh's iPhone was added",
        ),
        Entry(
          at: 2,
          kind: 'policy',
          by: 'Mom',
          text: 'Octo will now ask before every change',
        ),
        Entry(at: 3, kind: 'task', by: 'Harsh', text: 'Install Zoom'),
        Entry(at: 4, kind: 'step', by: 'Octo', text: 'Opened the store'),
      ]),
    ]);
    final items = _items(s);
    expect(items.map((i) => (i as SystemItem).text), [
      "Harsh's iPhone was added",
      'Octo will now ask before every change',
    ]);
  });

  test('a logged message of mine matching a local one is not shown twice', () {
    final s = _run([
      OutboxUpserted(
        _row(
          'o1',
          OutboxKind.message,
          'Calling you soon',
          state: OutboxState.sent,
          at: 10 * _min,
        ),
      ),
      const LogReceived([
        Entry(
          at: 10 * _min + 3000,
          kind: 'message',
          by: 'Harsh',
          text: 'Calling you soon',
        ),
        Entry(
          at: 11 * _min,
          kind: 'message',
          by: 'Priya',
          text: "I'll call too",
        ),
      ]),
    ]);
    final messages = _items(s).whereType<MessageItem>().toList();
    expect(messages.map((m) => (m.text, m.mine)), [
      ('Calling you soon', true),
      ("I'll call too", false),
    ]);
  });

  test(
    'to-dos: her screenshot, then her bubble; my replies are my bubbles',
    () {
      const todo = Todo(
        id: 'd1',
        at: 5000,
        text: 'Is this safe?',
        replies: [
          Reply(at: 6000, from: 'Harsh', text: 'Close it'),
          Reply(at: 6500, from: 'Priya', text: 'Yes close it'),
        ],
      );
      final s = _run([
        const TodoReceived(todo, LocalShot('x')),
        OutboxUpserted(
          _row(
            'o1',
            OutboxKind.todoReply,
            'Close it',
            state: OutboxState.sent,
            at: 6000,
            todoId: 'd1',
          ),
        ),
      ]);
      final items = _items(s);
      expect(items[0], isA<ImageItem>());
      final bubble = items[1] as TodoItem;
      expect(bubble.otherReplies.map((r) => r.from), ['Priya']);
      final mine = items[2] as MessageItem;
      expect(mine.replyToTodo, 'Is this safe?');
    },
  );

  test('grouping: consecutive bubbles from one sender share a group; gaps get timestamps', () {
    final s = _run([
      OutboxUpserted(_row('a', OutboxKind.message, 'one', at: 0)),
      OutboxUpserted(_row('b', OutboxKind.message, 'two', at: 1 * _min)),
      OutboxUpserted(_row('c', OutboxKind.message, 'three', at: 30 * _min)),
    ]);
    final entries = projectThread(s, _me);
    expect(entries.map((e) => e.item.runtimeType), [
      TimestampItem,
      MessageItem,
      MessageItem,
      TimestampItem,
      MessageItem,
    ]);
    expect(
      [
        for (final e in entries)
          if (e.item is MessageItem) (e.firstInGroup, e.lastInGroup),
      ],
      [(true, false), (false, true), (true, true)],
    );
  });

  test('same data, same output', () {
    final s = _run([
      TaskReceived(_task('t1', 'done', result: 'ok'), null),
      const HelpReceived(500, 'Printer'),
    ]);
    expect(
      projectThread(s, _me).map((e) => e.item.key),
      projectThread(s, _me).map((e) => e.item.key),
    );
    final help = _items(s).whereType<HelpItem>().single;
    expect(help.active, isTrue);
  });
}
