import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/protocol/app_message.dart';
import 'package:octo_family/protocol/host_message.dart';
import 'package:octo_family/protocol/models/policy.dart';
import 'package:octo_family/protocol/models/screenshot.dart';
import 'package:octo_family/protocol/models/task.dart';
import 'package:octo_family/transport/octo_link.dart';
import 'package:octo_family/transport/simulator/simulated_computer.dart';
import 'package:octo_family/transport/simulator/simulator_link.dart';

const _helper = 'Harsh';
const _device = "Harsh's iPhone";

/// Pairs one computer and returns it.
PairedComputer _pair(
  SimulatorLink link,
  FakeAsync async, {
  String payload = "octo-sim:Mom's laptop",
}) {
  final events = <PairingProgress>[];
  link
      .pair(payload, helperName: _helper, deviceLabel: _device)
      .listen(events.add);
  async.elapse(const Duration(seconds: 1));
  final compare = events.whereType<PairingCompareCode>().single;
  compare.confirm(true);
  async.elapse(const Duration(seconds: 1));
  link.pairingComputer?.momSaysOk(kind: ConsentKind.pairing);
  async.elapse(const Duration(seconds: 5));
  return events.whereType<PairingPaired>().single.computer;
}

/// One connection to a paired computer, recording what arrives.
class _Conn {
  _Conn(this.link, this.computerId) {
    _subs.add(
      link
          .messages(computerId)
          .listen((m) => received.add(parseHostMessage(m))),
    );
    _subs.add(link.connect(computerId).listen(states.add));
  }

  final SimulatorLink link;
  final String computerId;
  final received = <HostMessage>[];
  final states = <LinkState>[];
  final _subs = <StreamSubscription<Object?>>[];
  var _n = 0;

  SimulatedComputer get computer => link.computer(computerId)!;

  Future<void> send(AppMessage m) => link.send(computerId, m.toJson());

  /// Sends a task and returns its requestId.
  String task(String text, {String? job}) {
    final id = 'r${_n++}';
    send(TaskCreate(requestId: id, text: text, job: job));
    return id;
  }

  ResultMessage result(String requestId) => received
      .whereType<ResultMessage>()
      .singleWhere((r) => r.requestId == requestId);

  List<Task> versions(String taskId) => [
    for (final m in received.whereType<TaskMessage>())
      if (m.task.id == taskId) m.task,
  ];

  List<String> statuses(String taskId) => [
    for (final t in versions(taskId)) t.status,
  ];

  void close() {
    for (final s in _subs) {
      s.cancel();
    }
  }
}

SimulatorLink _link({bool autopilot = true}) => SimulatorLink(
  settings: SimulatorSettings(autopilot: autopilot),
  random: Random(42),
);

void main() {
  group('pairing', () {
    test('scanned → compare code → waiting → paired', () {
      fakeAsync((async) {
        final link = _link();
        final events = <PairingProgress>[];
        link
            .pair(
              "octo-sim:Dad's PC",
              helperName: _helper,
              deviceLabel: _device,
            )
            .listen(events.add);
        async.flushMicrotasks();
        expect((events.single as PairingScanned).computerName, "Dad's PC");
        expect(link.pairingComputer, isNotNull);

        async.elapse(const Duration(seconds: 1));
        final compare = events.last as PairingCompareCode;
        expect(compare.code, matches(RegExp(r'^\d{6}$')));
        expect(
          link.pairingComputer!.momScreen.last,
          contains(compare.code.substring(3)),
        );

        compare.confirm(true);
        async.flushMicrotasks();
        expect(events.last, isA<PairingWaitingForHer>());
        async.elapse(const Duration(seconds: 5));

        final paired = (events.last as PairingPaired).computer;
        expect(paired.computerName, "Dad's PC");
        expect(paired.person, 'Dad');
        expect(paired.hostId, startsWith('h_'));
        expect(link.computers.single.computerId, paired.computerId);
        expect(link.computers.single.helpers.values.single.device, _device);
        expect(link.pairingComputer, isNull);
      });
    });

    test("they don't match ends the pairing", () {
      fakeAsync((async) {
        final link = _link();
        final events = <PairingProgress>[];
        var done = false;
        link
            .pair('octo-sim:x', helperName: _helper, deviceLabel: _device)
            .listen(events.add, onDone: () => done = true);
        async.elapse(const Duration(seconds: 1));
        (events.last as PairingCompareCode).confirm(false);
        async.flushMicrotasks();
        final failed = events.last as PairingFailed;
        expect(failed.kind, PairingFailureKind.codeMismatch);
        expect(failed.isFinal, isTrue);
        expect(done, isTrue);
        expect(link.pairingComputer, isNull);
        expect(link.computers, isEmpty);
      });
    });

    PairingFailed runFailing(
      FakeAsync async,
      SimulatorLink link, {
      void Function(SimulatorLink)? whileWaiting,
      Duration wait = const Duration(seconds: 10),
    }) {
      final events = <PairingProgress>[];
      link
          .pair('octo-sim:x', helperName: _helper, deviceLabel: _device)
          .listen(events.add);
      async.elapse(const Duration(seconds: 1));
      (events.last as PairingCompareCode).confirm(true);
      async.elapse(const Duration(seconds: 1));
      whileWaiting?.call(link);
      async.elapse(wait);
      return events.last as PairingFailed;
    }

    test('Mom says no', () {
      fakeAsync((async) {
        final failed = runFailing(
          async,
          _link(autopilot: false),
          whileWaiting: (l) => l.pairingComputer!.momSaysNo(),
        );
        expect(failed.kind, PairingFailureKind.reportedByComputer);
        expect(failed.reason, 'Mom said no.');
        expect(failed.isFinal, isTrue);
      });
    });

    test('the code expires', () {
      fakeAsync((async) {
        final link = _link(autopilot: false)
          ..settings.pairingScript = SimPairingScript.codeExpires;
        final failed = runFailing(async, link);
        expect(failed.reason, contains('expired'));
        expect(failed.isFinal, isTrue);
      });
    });

    test('wrong code: the third try is final', () {
      fakeAsync((async) {
        final link = _link()
          ..settings.pairingScript = SimPairingScript.wrongCode;
        final first = runFailing(async, link);
        expect(first.reason, "That code doesn't match.");
        expect(first.isFinal, isFalse);
        expect(runFailing(async, link).isFinal, isFalse);
        final third = runFailing(async, link);
        expect(third.isFinal, isTrue);
        expect(third.reason, contains('Too many wrong tries'));
      });
    });

    test('her computer going offline ends the pairing', () {
      fakeAsync((async) {
        final failed = runFailing(
          async,
          _link(autopilot: false),
          whileWaiting: (l) => l.pairingComputer!.goOffline(),
        );
        expect(failed.kind, PairingFailureKind.offline);
      });
    });

    test('cancelling the subscription cancels the handshake', () {
      fakeAsync((async) {
        final link = _link(autopilot: false);
        final sub = link
            .pair('octo-sim:x', helperName: _helper, deviceLabel: _device)
            .listen((_) {});
        async.elapse(const Duration(seconds: 1));
        expect(link.pairingComputer, isNotNull);
        sub.cancel();
        async.flushMicrotasks();
        expect(link.pairingComputer, isNull);
        async.elapse(const Duration(minutes: 10));
        expect(link.computers, isEmpty);
      });
    });

    test(
      'accepted codes: enrollment link and typed code; others are invalid',
      () {
        fakeAsync((async) {
          final link = _link();
          _pair(
            link,
            async,
            payload: 'https://www.october.dev/octo/add#enr_1.s3cret',
          );
          _pair(link, async, payload: 'AB12CD34');
          expect(link.computers.map((c) => c.computerName), [
            "Mom's laptop",
            "Dad's PC",
          ]);

          final events = <PairingProgress>[];
          link
              .pair('hello', helperName: _helper, deviceLabel: _device)
              .listen(events.add);
          async.flushMicrotasks();
          expect(
            (events.single as PairingFailed).kind,
            PairingFailureKind.invalidCode,
          );
        });
      },
    );
  });

  group('tasks', () {
    late SimulatorLink link;
    late _Conn conn;

    void setUpConn(FakeAsync async, {bool autopilot = true}) {
      link = _link(autopilot: autopilot);
      conn = _Conn(link, _pair(link, async).computerId);
      async.elapse(const Duration(seconds: 1));
      expect(conn.states.last, LinkState.connected);
    }

    test('a change task: waiting for her OK → running with steps → done', () {
      fakeAsync((async) {
        setUpConn(async);
        final r = conn.task(
          "Join the Discord server from Priya's invite and start the call",
        );
        async.elapse(const Duration(seconds: 1));
        final result = conn.result(r);
        expect(result.ok, isTrue);
        final taskId = result.taskId!;

        async.elapse(const Duration(seconds: 30));
        expect(conn.statuses(taskId).toSet().toList(), [
          'queued',
          'waitingOk',
          'running',
          'done',
        ]);
        final done = conn.versions(taskId).last;
        expect(done.job, 'call.join');
        expect(done.from, link.helperIdFor(conn.computerId));
        expect(done.fromName, _helper);
        expect(done.steps.map((s) => s.n), [1, 2, 3]);
        expect(done.result, "Joined. She's in the call.");
        expect(done.screenshot, isA<InlineScreenshot>());
        expect(done.startedAt, isNotNull);
        expect(done.endedAt, isNotNull);
        final running = conn
            .versions(taskId)
            .where((t) => t.phase == TaskPhase.running);
        expect(
          running.map((t) => t.steps.length),
          containsAllInOrder([0, 1, 2]),
        );
        expect(running.first.say, isNotNull);
      });
    });

    test('a look task runs without asking', () {
      fakeAsync((async) {
        setUpConn(async, autopilot: false);
        final r = conn.task('Check the Wi-Fi', job: 'wifi.check');
        async.elapse(const Duration(seconds: 30));
        final taskId = conn.result(r).taskId!;
        expect(conn.statuses(taskId), isNot(contains('waitingOk')));
        expect(conn.versions(taskId).last.phase, TaskPhase.done);
      });
    });

    test('Mom says no, or doesn\'t answer', () {
      fakeAsync((async) {
        setUpConn(async, autopilot: false);
        final a = conn.task('Install Zoom');
        async.elapse(const Duration(seconds: 1));
        conn.computer.momSaysNo();
        async.elapse(const Duration(seconds: 1));
        final declined = conn.versions(conn.result(a).taskId!).last;
        expect(declined.phase, TaskPhase.declined);
        expect(declined.result, 'Mom said no.');

        final b = conn.task('Install Zoom');
        async.elapse(const Duration(minutes: 3));
        expect(
          conn.versions(conn.result(b).taskId!).last.phase,
          TaskPhase.noAnswer,
        );
      });
    });

    test('her rules refuse a task; a safety limit blocks one', () {
      fakeAsync((async) {
        setUpConn(async);
        conn.computer.policy = const Policy(
          never: ['install'],
          blockedSites: ['facebook.com'],
        );
        final a = conn.task('Install Zoom');
        final b = conn.task('Open facebook.com for her');
        final c = conn.task('Type her password into the bank site');
        async.elapse(const Duration(seconds: 30));
        final refused = conn.versions(conn.result(a).taskId!).last;
        expect(refused.phase, TaskPhase.refused);
        expect(
          refused.result,
          "Your rules say Octo can't install apps on Mom's computer.",
        );
        expect(
          conn.versions(conn.result(b).taskId!).last.result,
          'Your rules keep Octo off facebook.com.',
        );
        final blocked = conn.versions(conn.result(c).taskId!).last;
        expect(blocked.phase, TaskPhase.blocked);
        expect(blocked.result, contains('I never type passwords'));
        expect(blocked.steps, hasLength(1));
      });
    });

    test('at most 10 tasks wait; the 11th is busy', () {
      fakeAsync((async) {
        setUpConn(async, autopilot: false);
        final ids = [
          for (var i = 0; i < 11; i++) conn.task('Make the text bigger'),
        ];
        async.elapse(const Duration(seconds: 1));
        expect(
          ids.take(10).map((r) => conn.result(r).ok),
          everyElement(isTrue),
        );
        final busy = conn.result(ids.last);
        expect(busy.errorCode, ResultError.busy);
        expect(busy.message, contains('10 things waiting'));
      });
    });

    test('bad requests and unknown jobs', () {
      fakeAsync((async) {
        setUpConn(async);
        final empty = conn.task('   ');
        final long = conn.task('x' * 2001);
        final unknown = conn.task('Dance', job: 'dance.party');
        final edge = conn.task('x' * 2000);
        async.elapse(const Duration(seconds: 1));
        expect(conn.result(empty).errorCode, ResultError.badRequest);
        expect(conn.result(long).errorCode, ResultError.badRequest);
        expect(conn.result(unknown).errorCode, ResultError.unknownJob);
        expect(
          conn.result(unknown).message,
          'Octo doesn\'t know the job “dance.party”.',
        );
        expect(conn.result(edge).ok, isTrue);
      });
    });

    test('stop a running task; stop an unknown one', () {
      fakeAsync((async) {
        setUpConn(async);
        final r = conn.task('Check the Wi-Fi');
        async.elapse(const Duration(seconds: 2));
        final taskId = conn.result(r).taskId!;
        expect(conn.versions(taskId).last.phase, TaskPhase.running);
        conn.send(TaskStop(requestId: 's1', taskId: taskId));
        conn.send(const TaskStop(requestId: 's2', taskId: 't_nope'));
        async.elapse(const Duration(seconds: 1));
        expect(conn.result('s1').ok, isTrue);
        expect(conn.result('s2').errorCode, ResultError.notFound);
        final stopped = conn.versions(taskId).last;
        expect(stopped.phase, TaskPhase.stopped);
        expect(stopped.result, 'Stopped by Harsh.');
        final steps = stopped.steps.length;
        async.elapse(const Duration(seconds: 30));
        expect(
          conn.versions(taskId).last.steps.length,
          steps,
          reason: 'no more steps',
        );
      });
    });

    test('another helper\'s task shows who asked', () {
      fakeAsync((async) {
        setUpConn(async);
        conn.computer.otherHelperAsks();
        async.elapse(const Duration(seconds: 30));
        final t = conn.received.whereType<TaskMessage>().last.task;
        expect(t.fromName, 'Priya');
        expect(t.job, 'app.install');
      });
    });
  });

  group('connection', () {
    test(
      'offline: link drops, send throws, messages are lost; online reconnects',
      () {
        fakeAsync((async) {
          final link = _link();
          final conn = _Conn(link, _pair(link, async).computerId);
          async.elapse(const Duration(seconds: 1));
          final r = conn.task('Check the Wi-Fi');
          async.elapse(const Duration(seconds: 1));
          final taskId = conn.result(r).taskId!;

          conn.computer.goOffline();
          async.flushMicrotasks();
          expect(conn.states.last, LinkState.offline);
          expect(
            conn.send(const StatusRequest(requestId: 'q')),
            throwsA(isA<LinkUnavailableException>()),
          );
          final before = conn.received.length;
          async.elapse(const Duration(seconds: 30));
          expect(conn.received.length, before, reason: 'lost while offline');
          expect(
            conn.computer.tasks[taskId]!.phase,
            TaskPhase.done,
            reason: 'her computer kept working',
          );

          conn.computer.goOnline();
          async.elapse(const Duration(seconds: 2));
          expect(conn.states.reversed.take(2).toList().reversed, [
            LinkState.connecting,
            LinkState.connected,
          ]);
          conn.send(const StatusRequest(requestId: 'q1'));
          async.elapse(const Duration(seconds: 1));
          final status = conn.received.whereType<StatusMessage>().single.status;
          expect(status.recent.single.id, taskId);
          expect(status.recent.single.phase, TaskPhase.done);
        });
      },
    );

    test('a computer the simulator forgot is recreated on connect', () {
      fakeAsync((async) {
        final link = _link();
        final conn = _Conn(link, 'c_from_last_run');
        async.elapse(const Duration(seconds: 1));
        expect(conn.states.last, LinkState.connected);
        conn.task('Check the Wi-Fi');
        async.elapse(const Duration(seconds: 1));
        expect(conn.received.whereType<ResultMessage>().single.ok, isTrue);
      });
    });

    test('removed: the link goes offline for good', () {
      fakeAsync((async) {
        final link = _link();
        final conn = _Conn(link, _pair(link, async).computerId);
        async.elapse(const Duration(seconds: 1));
        link.removeMe(conn.computerId);
        async.elapse(const Duration(seconds: 1));
        expect(conn.received.last, isA<RemovedMessage>());
        expect(conn.states.last, LinkState.offline);
        final again = _Conn(link, conn.computerId);
        async.elapse(const Duration(seconds: 5));
        expect(again.states.last, LinkState.offline);
      });
    });

    test('leave and unpair', () {
      fakeAsync((async) {
        final link = _link();
        final conn = _Conn(link, _pair(link, async).computerId);
        async.elapse(const Duration(seconds: 1));
        conn.send(const Leave());
        async.elapse(const Duration(seconds: 1));
        expect(conn.states.last, LinkState.offline);
        expect(conn.computer.helpers, isEmpty);
        conn.close();
        link.unpair(conn.computerId);
        async.flushMicrotasks();
        expect(link.computers, isEmpty);
      });
    });
  });

  group('status, to-dos, log, rules, screen, help', () {
    late SimulatorLink link;
    late _Conn conn;

    void setUpConn(FakeAsync async, {bool autopilot = true}) {
      link = _link(autopilot: autopilot);
      conn = _Conn(link, _pair(link, async).computerId);
      async.elapse(const Duration(seconds: 1));
    }

    test('status reply', () {
      fakeAsync((async) {
        setUpConn(async);
        conn.send(const StatusRequest(requestId: 'q1'));
        async.elapse(const Duration(seconds: 1));
        final m = conn.received.whereType<StatusMessage>().single;
        expect(m.requestId, 'q1');
        expect(m.status.computer, "Mom's laptop");
        expect(m.status.person, 'Mom');
        expect(m.status.family.single.name, _helper);
        expect(m.status.jobs.map((j) => j.id), contains('call.join'));
        expect(m.status.policy!.toJson(), const Policy().toJson());
        expect(m.status.agent!.connected, isTrue);
      });
    });

    test('to-dos: sent by Mom, replied to, marked done', () {
      fakeAsync((async) {
        setUpConn(async);
        conn.computer.sendTodo();
        async.elapse(const Duration(seconds: 1));
        final todo = conn.received.whereType<TodoMessage>().single.todo;
        expect(todo.text, 'Is this email real?');
        expect(todo.screenshot, isA<InlineScreenshot>());
        expect(todo.context!.app, isNotNull);

        conn.send(TodoReply(todoId: todo.id, text: "Yes, it's a scam."));
        conn.send(TodoDone(todoId: todo.id));
        conn.send(const TodosRequest(requestId: 'd1'));
        async.elapse(const Duration(seconds: 1));
        final latest = conn.received.whereType<TodoMessage>().last.todo;
        expect(latest.done, isTrue);
        expect(latest.replies.single.from, _helper);
        final list = conn.received.whereType<TodosMessage>().single;
        expect(list.requestId, 'd1');
        expect(list.todos.single.done, isTrue);
      });
    });

    test('log: since is inclusive, limit applies, oldest first', () {
      fakeAsync((async) {
        setUpConn(async);
        conn.task('Check the Wi-Fi');
        async.elapse(const Duration(seconds: 30));
        final all = conn.computer.log;
        expect(all.length, greaterThan(3));
        final since = all[1].at;
        conn.send(LogRequest(requestId: 'l1', since: since, limit: 2));
        async.elapse(const Duration(seconds: 1));
        final page = conn.received.whereType<LogMessage>().single.entries;
        expect(page, hasLength(2));
        expect(page.first.at, greaterThanOrEqualTo(since));
        expect(page.first.at, lessThanOrEqualTo(page.last.at));
      });
    });

    test('rules: tightening applies at once; loosening waits for her', () {
      fakeAsync((async) {
        setUpConn(async, autopilot: false);
        conn.computer.policy = const Policy(never: ['install']);
        // Tighten (ask before looking, block a site) and loosen (allow installs).
        conn.send(
          const PolicySet(
            requestId: 'p1',
            policy: Policy(
              askBeforeLooking: true,
              blockedSites: ['facebook.com'],
            ),
          ),
        );
        async.elapse(const Duration(seconds: 1));
        expect(conn.result('p1').ok, isTrue);
        final applied = conn.received.whereType<PolicyMessage>().single.policy;
        expect(applied.askBeforeLooking, isTrue);
        expect(applied.blockedSites, ['facebook.com']);
        expect(applied.never, ['install'], reason: 'loosening waits');
        expect(conn.computer.consents.single.kind, ConsentKind.policy);

        conn.computer.momSaysOk(kind: ConsentKind.policy);
        async.elapse(const Duration(seconds: 1));
        final approved = conn.received.whereType<PolicyMessage>().last;
        expect(approved.declined, isFalse);
        expect(approved.policy.never, isEmpty);

        conn.send(
          const PolicySet(
            requestId: 'p2',
            policy: Policy(askEveryChange: false),
          ),
        );
        async.elapse(const Duration(seconds: 1));
        conn.computer.momSaysNo();
        async.elapse(const Duration(seconds: 1));
        final declined = conn.received.whereType<PolicyMessage>().last;
        expect(declined.declined, isTrue);
        expect(declined.policy.askEveryChange, isTrue);
      });
    });

    test('screen: she shares, or says no', () {
      fakeAsync((async) {
        setUpConn(async, autopilot: false);
        conn.send(const ScreenRequest());
        async.elapse(const Duration(seconds: 1));
        conn.computer.momSaysOk();
        async.elapse(const Duration(seconds: 1));
        conn.send(const ScreenRequest());
        async.elapse(const Duration(seconds: 1));
        conn.computer.momSaysNo();
        async.elapse(const Duration(seconds: 1));
        final screens = conn.received.whereType<ScreenMessage>().toList();
        expect(screens[0].ok, isTrue);
        expect(screens[0].screenshot, isA<InlineScreenshot>());
        expect(screens[1].ok, isFalse);
        expect(screens[1].reason, 'She said no.');
      });
    });

    test('help: arrives live, shows in status, clears when someone acts', () {
      fakeAsync((async) {
        setUpConn(async);
        conn.computer.askForHelp();
        conn.send(const StatusRequest(requestId: 'q1'));
        async.elapse(const Duration(seconds: 1));
        final help = conn.received.whereType<HelpMessage>().single;
        expect(help.text, "The printer isn't working");
        expect(
          conn.received.whereType<StatusMessage>().single.status.help!.since,
          help.at,
        );
        conn.task('Check the printer');
        conn.send(const StatusRequest(requestId: 'q2'));
        async.elapse(const Duration(seconds: 1));
        expect(
          conn.received.whereType<StatusMessage>().last.status.help,
          isNull,
        );
      });
    });

    test('a message to Mom shows on her screen', () {
      fakeAsync((async) {
        setUpConn(async);
        conn.send(const ChatMessage(text: 'Calling you in 5 minutes!'));
        async.elapse(const Duration(seconds: 1));
        expect(
          conn.computer.momScreen.last,
          'Harsh: Calling you in 5 minutes!',
        );
      });
    });
  });
}
