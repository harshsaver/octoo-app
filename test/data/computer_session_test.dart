import 'dart:io';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/data/outbox.dart';
import 'package:octo_family/data/screenshot_store.dart';
import 'package:octo_family/data/session/computer_session.dart';
import 'package:octo_family/data/session/session_data.dart';
import 'package:octo_family/data/session/session_store.dart';
import 'package:octo_family/data/thread/projection.dart';
import 'package:octo_family/protocol/models/task.dart';
import 'package:octo_family/transport/octo_link.dart';
import 'package:octo_family/transport/simulator/simulated_computer.dart';
import 'package:octo_family/transport/simulator/simulator_link.dart';

import '../support/scripted_link.dart';

final _shots = ScreenshotStore(
  Directory.systemTemp.createTempSync('octo-shots-'),
);

PairedComputer _pair(SimulatorLink link, FakeAsync async) {
  final events = <PairingProgress>[];
  link
      .pair(
        "octo-sim:Mom's laptop",
        helperName: 'Harsh',
        deviceLabel: "Harsh's phone",
      )
      .listen(events.add);
  async.elapse(const Duration(seconds: 1));
  events.whereType<PairingCompareCode>().single.confirm(true);
  async.elapse(const Duration(seconds: 6));
  return events.whereType<PairingPaired>().single.computer;
}

ComputerSession _session(
  OctoLink link,
  String id,
  SessionStore store, {
  String? bind,
}) => ComputerSession(
  computerId: id,
  link: link,
  store: store,
  shots: _shots,
  bind: bind,
);

void main() {
  group('against the simulator', () {
    test('connect refreshes, a task goes out through the outbox and comes back done', () {
      fakeAsync((async) {
        final link = SimulatorLink(random: Random(1));
        final id = _pair(link, async).computerId;
        final store = MemorySessionStore();
        final s = _session(link, id, store);
        s.open();
        async.flushMicrotasks();
        s.connect();
        async.elapse(const Duration(seconds: 2));
        expect(s.data.link, LinkState.connected);
        expect(s.data.status?.computer, "Mom's laptop");
        expect(s.data.entries, isNotEmpty, reason: 'log synced (pairing line)');

        s.askOcto("Join the Discord call from Priya's invite");
        async.elapse(const Duration(seconds: 1));
        final row = s.data.outbox.values.single;
        expect(row.state, OutboxState.accepted);
        expect(row.taskId, isNotNull);

        async.elapse(const Duration(seconds: 15));
        final task = s.data.tasks[row.taskId]!;
        expect(task.task.phase, TaskPhase.done);
        expect(task.shot, isA<LocalShot>());
        expect(s.data.myHelperId, link.helperIdFor(id));

        final items = [
          for (final e in projectThread(
            s.data,
            const MeIdentity(name: 'Harsh'),
          ))
            e.item,
        ];
        final request = items.whereType<RequestItem>().single;
        expect(request.key, 'out:${row.id}');
        expect(request.mine, isTrue);
        expect(request.line, RequestLine.sheSaidOk);
        expect(items.whereType<OctoTaskItem>().single.phase, TaskPhase.done);
        expect(
          items.whereType<SystemItem>().map((i) => i.text),
          contains("Harsh's phone was added"),
        );

        // Nothing stored carries screenshot bytes.
        s.flush();
        async.flushMicrotasks();
        expect(store.allJson().where((j) => j.contains('base64')), isEmpty);
        s.dispose();
        async.flushMicrotasks();
      });
    });

    test('typed while offline: pending, then sent on reconnect', () {
      fakeAsync((async) {
        final link = SimulatorLink(random: Random(2));
        final id = _pair(link, async).computerId;
        final s = _session(link, id, MemorySessionStore());
        s.open();
        async.flushMicrotasks();
        link.computer(id)!.goOffline();
        s.connect();
        async.elapse(const Duration(seconds: 1));
        expect(s.data.link, LinkState.offline);

        s.tellMom('Calling you in 5 minutes!');
        s.askOcto('Check the Wi-Fi');
        async.elapse(const Duration(seconds: 1));
        expect(
          s.data.outbox.values.map((r) => r.state),
          everyElement(OutboxState.pending),
        );

        link.computer(id)!.goOnline();
        async.elapse(const Duration(seconds: 5));
        final states = {for (final r in s.data.outbox.values) r.kind: r.state};
        expect(states[OutboxKind.message], OutboxState.sent);
        expect(states[OutboxKind.task], OutboxState.accepted);
        expect(
          link.computer(id)!.momScreen,
          contains('Harsh: Calling you in 5 minutes!'),
        );
        s.dispose();
        async.flushMicrotasks();
      });
    });

    test('her help request is active until someone here acts', () {
      fakeAsync((async) {
        final link = SimulatorLink(random: Random(3));
        final id = _pair(link, async).computerId;
        final s = _session(link, id, MemorySessionStore());
        s.open();
        s.connect();
        async.elapse(const Duration(seconds: 2));
        link.computer(id)!.askForHelp();
        async.elapse(const Duration(seconds: 1));
        expect(s.data.activeHelp, isNotNull);
        s.requestScreen();
        async.elapse(const Duration(seconds: 1));
        expect(s.data.activeHelp, isNull);
        async.elapse(const Duration(seconds: 5));
        expect(s.data.screens.values.single.ok, isTrue);
        s.dispose();
        async.flushMicrotasks();
      });
    });

    test('stop a running task', () {
      fakeAsync((async) {
        final link = SimulatorLink(random: Random(4));
        final id = _pair(link, async).computerId;
        final s = _session(link, id, MemorySessionStore());
        s.open();
        s.connect();
        async.elapse(const Duration(seconds: 2));
        s.askOcto('Check the Wi-Fi', job: 'wifi.check');
        async.elapse(const Duration(seconds: 2));
        final taskId = s.data.outbox.values.single.taskId!;
        StopOutcome? outcome;
        s.stopTask(taskId).then((o) => outcome = o);
        async.elapse(const Duration(seconds: 1));
        expect(outcome, StopOutcome.stopped);
        expect(s.data.tasks[taskId]!.task.phase, TaskPhase.stopped);
        s.dispose();
        async.flushMicrotasks();
      });
    });

    test('a restart shows the stored thread before connecting', () {
      fakeAsync((async) {
        final link = SimulatorLink(random: Random(5));
        final id = _pair(link, async).computerId;
        final store = MemorySessionStore();
        final first = _session(link, id, store);
        first.open();
        first.connect();
        async.elapse(const Duration(seconds: 2));
        first.askOcto('Check the Wi-Fi', job: 'wifi.check');
        async.elapse(const Duration(seconds: 10));
        first.dispose();
        async.flushMicrotasks();

        final second = _session(link, id, store);
        second.open();
        async.flushMicrotasks();
        expect(second.data.link, LinkState.offline);
        expect(second.data.tasks.values.single.task.phase, TaskPhase.done);
        expect(second.data.outbox.values.single.state, OutboxState.accepted);
        expect(second.data.myHelperId, isNotNull);
        second.dispose();
        async.flushMicrotasks();
      });
    });
  });

  group('against a scripted computer', () {
    test('a crash while attempting leaves the row uncertain', () {
      fakeAsync((async) {
        final link = ScriptedLink();
        final store = MemorySessionStore();
        store.write(
          const SessionWrite(
            outbox: [
              OutboxRow(
                id: 'o1',
                computerId: 'c1',
                kind: OutboxKind.task,
                payload: {'text': 'Install Zoom'},
                state: OutboxState.attempting,
                requestId: 'r1',
                createdAt: 1,
                updatedAt: 1,
              ),
            ],
          ),
        );
        final s = _session(link, 'c1', store);
        s.open();
        async.flushMicrotasks();
        expect(s.data.outbox['o1']!.state, OutboxState.uncertain);

        // Never re-sent automatically; a late result still settles it.
        link.goOnline();
        link.onSend = (m) {
          final type = m['type'];
          if (type == 'status' || type == 'todos' || type == 'log') {
            link.push({
              'type': type,
              'requestId': m['requestId'],
              if (type == 'todos') 'todos': [],
              if (type == 'log') 'entries': [],
            });
          }
        };
        s.connect();
        async.elapse(const Duration(seconds: 1));
        expect(link.sentOfType('task.create'), isEmpty);
        link.push({
          'type': 'result',
          'requestId': 'r1',
          'ok': true,
          'taskId': 't9',
        });
        expect(s.data.outbox['o1']!.state, OutboxState.accepted);
        expect(s.data.outbox['o1']!.taskId, 't9');
        s.dispose();
        async.flushMicrotasks();
      });
    });

    test('no reply in time: uncertain, then a late result is applied', () {
      fakeAsync((async) {
        final link = ScriptedLink()..goOnline();
        link.onSend = (m) {
          final type = m['type'];
          if (type == 'status' || type == 'todos' || type == 'log') {
            link.push({
              'type': type,
              'requestId': m['requestId'],
              if (type == 'todos') 'todos': [],
              if (type == 'log') 'entries': [],
            });
          }
        };
        final s = _session(link, 'c1', MemorySessionStore());
        s.open();
        s.connect();
        async.elapse(const Duration(seconds: 1));
        s.askOcto('Install Zoom');
        async.elapse(const Duration(seconds: 25));
        final row = s.data.outbox.values.single;
        expect(row.state, OutboxState.uncertain);
        link.push({
          'type': 'result',
          'requestId': row.requestId,
          'ok': false,
          'error': 'busy',
          'message': 'Busy.',
        });
        expect(s.data.outbox.values.single.state, OutboxState.rejected);
        expect(s.data.outbox.values.single.errorMessage, 'Busy.');
        s.dispose();
        async.flushMicrotasks();
      });
    });

    test('log paging stops when a full page brings nothing new', () {
      fakeAsync((async) {
        final link = ScriptedLink()..goOnline();
        var logRequests = 0;
        link.onSend = (m) {
          final type = m['type'];
          if (type == 'status') {
            link.push({'type': 'status', 'requestId': m['requestId']});
          }
          if (type == 'todos') {
            link.push({
              'type': 'todos',
              'requestId': m['requestId'],
              'todos': [],
            });
          }
          if (type == 'log') {
            logRequests++;
            // Always the same full page: every entry at the same time.
            link.push({
              'type': 'log',
              'requestId': m['requestId'],
              'entries': [
                for (var i = 0; i < 3; i++)
                  {'at': 100, 'kind': 'step', 'by': 'Octo', 'text': 'step $i'},
              ],
            });
          }
        };
        final s = ComputerSession(
          computerId: 'c1',
          link: link,
          store: MemorySessionStore(),
          shots: _shots,
          logPageSize: 3,
        );
        s.open();
        s.connect();
        async.elapse(const Duration(seconds: 1));
        expect(
          logRequests,
          2,
          reason: 'one page of news, then one with nothing new',
        );
        expect(s.data.entries, hasLength(3));
        expect(s.data.logMayBeIncomplete, isTrue);
        expect(s.data.logCursor, 100);
        s.dispose();
        async.flushMicrotasks();
      });
    });

    test('rows from an older pairing are dropped, never sent', () {
      fakeAsync((async) {
        final store = MemorySessionStore();
        store.write(
          const SessionWrite(
            outbox: [
              OutboxRow(
                id: 'old',
                computerId: 'c1',
                bind: 'b1',
                kind: OutboxKind.message,
                payload: {'text': 'hi'},
                state: OutboxState.pending,
                createdAt: 1,
                updatedAt: 1,
              ),
            ],
          ),
        );
        final s = _session(ScriptedLink(), 'c1', store, bind: 'b2');
        s.open();
        async.flushMicrotasks();
        expect(s.data.outbox, isEmpty);
        s.dispose();
        async.flushMicrotasks();
      });
    });

    test('unreadable messages are ignored and counted, never thrown', () {
      fakeAsync((async) {
        final link = ScriptedLink();
        final s = _session(link, 'c1', MemorySessionStore());
        s.open();
        async.flushMicrotasks();
        link.push({'type': 'hologram'});
        link.push({'type': 'task', 'task': 'nope'});
        expect(s.ignoredMessages, 2);
        s.dispose();
        async.flushMicrotasks();
      });
    });
  });

  test('the simulated computer setting up autopilot is the default', () {
    expect(SimulatorSettings().autopilot, isTrue);
  });
}
