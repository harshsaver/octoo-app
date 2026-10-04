import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/protocol/host_message.dart';
import 'package:octo_family/protocol/models/screenshot.dart';
import 'package:octo_family/protocol/models/task.dart';

import 'brief_examples.dart';

void main() {
  group('brief §7.2 examples', () {
    test('every example parses to its typed message', () {
      for (final MapEntry(:key, :value) in hostExamples.entries) {
        final message = parseHostMessage(decode(value));
        expect(message, isNot(isA<UnknownHostMessage>()), reason: key);
        expect(message.type, decode(value)['type'], reason: key);
      }
      expect(knownHostMessageTypes, {
        for (final json in hostExamples.values) decode(json)['type'],
      });
    });

    test('pair messages', () {
      final code = parseHostMessage(
        decode(hostExamples['pair.code']!),
      ) as PairCodeMessage;
      expect(code.code, '482913');
      expect(code.computer, "Mom's laptop");

      final done = parseHostMessage(
        decode(hostExamples['pair.done']!),
      ) as PairDoneMessage;
      expect(done.hostId, 'h_…');
      expect(done.person, 'Mom');

      final failed = parseHostMessage(
        decode(hostExamples['pair.failed']!),
      ) as PairFailedMessage;
      expect(failed.reason, "That code doesn't match.");
      expect(failed.isFinal, isFalse);
    });

    test('results', () {
      final ok =
          parseHostMessage(decode(hostExamples['result ok']!)) as ResultMessage;
      expect(ok.ok, isTrue);
      expect(ok.taskId, 't_…');
      expect(ok.errorCode, isNull);

      final err = parseHostMessage(
        decode(hostExamples['result error']!),
      ) as ResultMessage;
      expect(err.ok, isFalse);
      expect(err.errorCode, ResultError.unknownJob);
      expect(err.message, "Octo doesn't know the job “x”.");
    });

    test('task keeps every field and its raw JSON', () {
      final m = parseHostMessage(decode(hostExamples['task']!)) as TaskMessage;
      final t = m.task;
      expect(t.id, 't_3f9a1c2b7d4e');
      expect(t.fromName, 'Harsh');
      expect(t.phase, TaskPhase.running);
      expect(t.scopeKind, TaskScope.change);
      expect(t.mayKinds, [ChangeKind.open, ChangeKind.call]);
      expect(t.steps.single.did, 'Opened discord.gg');
      expect(t.steps.single.ok, isTrue);
      expect(t.createdAt, 1790000000000);
      expect(t.endedAt, isNull);
      expect(t.raw, decode(taskJson));
    });

    test('status with nested task, policy, family, jobs, help and agent', () {
      final m =
          parseHostMessage(decode(hostExamples['status']!)) as StatusMessage;
      expect(m.requestId, 'q1');
      final s = m.status;
      expect(s.computer, "Mom's laptop");
      expect(s.language, 'hi');
      expect(s.busy, isTrue);
      expect(s.task!.id, 't_3f9a1c2b7d4e');
      expect(s.task!.raw, isNotEmpty, reason: 'nested models keep raw too');
      expect(s.todos!.open, 1);
      expect(s.help!.since, 1790000000000);
      expect(s.policy!.never, ['install']);
      expect(s.policy!.raw, isNotEmpty);
      expect(s.family.single.device, "Harsh's iPhone");
      expect(s.jobs.single.id, 'wifi.check');
      expect(s.jobs.single.scopeKind, TaskScope.look);
      expect(s.agent!.connected, isTrue);
    });

    test('to-dos, log, help, screen, policy, removed', () {
      final todo =
          (parseHostMessage(decode(hostExamples['todo']!)) as TodoMessage).todo;
      expect(todo.context!.app, 'Google Chrome');
      expect(todo.replies.single.text, 'Close it!');
      expect(todo.done, isFalse);

      final todos =
          parseHostMessage(decode(hostExamples['todos']!)) as TodosMessage;
      expect(todos.requestId, 'd1');
      expect(todos.todos.single.id, 'd_8a1f');

      final log = parseHostMessage(decode(hostExamples['log']!)) as LogMessage;
      expect(log.entries.single.outcome, 'done');

      final help =
          parseHostMessage(decode(hostExamples['help']!)) as HelpMessage;
      expect(help.at, 1790000000000);

      final screen =
          parseHostMessage(decode(hostExamples['screen ok']!)) as ScreenMessage;
      expect(screen.ok, isTrue);
      expect(screen.screenshot, isA<InlineScreenshot>());
      expect(screen.app, 'Microsoft Edge');

      final no =
          parseHostMessage(decode(hostExamples['screen no']!)) as ScreenMessage;
      expect(no.ok, isFalse);
      expect(no.reason, 'She said no.');

      final policy =
          parseHostMessage(decode(hostExamples['policy']!)) as PolicyMessage;
      expect(policy.declined, isTrue);
      expect(policy.policy.blockedSites, ['facebook.com']);

      expect(
        parseHostMessage(decode(hostExamples['removed']!)),
        isA<RemovedMessage>(),
      );
    });
  });

  group('forward compatibility', () {
    test('unknown types are ignored, not thrown', () {
      final m = parseHostMessage({'type': 'video.start', 'x': 1});
      expect(m, isA<UnknownHostMessage>());
      expect((m as UnknownHostMessage).reason, UnknownReason.unknownType);
      expect(parseHostMessage({}), isA<UnknownHostMessage>());
      expect(parseHostMessage({'type': 7}), isA<UnknownHostMessage>());
    });

    test('unknown fields are ignored and kept in raw', () {
      final json = decode(hostExamples['task']!);
      (json['task']! as Map<String, Object?>)['mood'] = 'happy';
      json['extra'] = true;
      final m = parseHostMessage(json) as TaskMessage;
      expect(m.task.raw['mood'], 'happy');
    });

    test('unknown status and may values keep their strings', () {
      final task = Task.fromJson(
        decode(
          '{"id":"t1","status":"paused","may":["teleport","open"],"scope":"dream"}',
        ),
      );
      expect(task.phase, TaskPhase.unknown);
      expect(task.phase.isActive, isFalse);
      expect(
        task.phase.isEnded,
        isFalse,
        reason: 'never reads as done or failed',
      );
      expect(task.status, 'paused');
      expect(task.mayKinds, [ChangeKind.unknown, ChangeKind.open]);
      expect(task.may, ['teleport', 'open']);
      expect(task.scopeKind, TaskScope.unknown);
      expect(task.toJson()['status'], 'paused');
    });

    test('unknown result error codes keep their string', () {
      final m = parseHostMessage({
        'type': 'result',
        'requestId': 'r',
        'ok': false,
        'error': 'melted',
      }) as ResultMessage;
      expect(m.errorCode, ResultError.unknown);
      expect(m.error, 'melted');
    });

    test('a malformed known message becomes Unknown(malformed)', () {
      const cases = <Map<String, Object?>>[
        {'type': 'pair.code', 'code': 482913},
        {'type': 'result', 'ok': true},
        {'type': 'task', 'task': 'nope'},
        {
          'type': 'task',
          'task': {'status': 'running'},
        },
        {
          'type': 'task',
          'task': {
            'id': 't',
            'may': [1],
          },
        },
        {
          'type': 'todos',
          'requestId': 'd1',
          'todos': [
            {'id': 'x'},
          ],
        },
        {'type': 'log', 'requestId': 'l1'},
        {'type': 'help', 'text': 'no time'},
        {'type': 'status', 'requestId': 'q1', 'busy': 'yes'},
        {'type': 'screen', 'ok': 'true'},
        {
          'type': 'policy',
          'policy': {'never': 'install'},
        },
      ];
      for (final raw in cases) {
        final m = parseHostMessage(raw);
        expect(m, isA<UnknownHostMessage>(), reason: '$raw');
        expect(
          (m as UnknownHostMessage).reason,
          UnknownReason.malformed,
          reason: '$raw',
        );
      }
    });

    test('random garbage never throws', () {
      final random = Random(7);
      Object? value(int depth) => switch (random.nextInt(depth > 2 ? 5 : 7)) {
        0 => null,
        1 => random.nextBool(),
        2 => random.nextInt(1 << 31),
        3 => random.nextDouble(),
        4 => ['x', 't_1', '', 'running'][random.nextInt(4)],
        5 => [for (var i = 0; i < random.nextInt(3); i++) value(depth + 1)],
        _ => {
          for (final k in [
            'id',
            'at',
            'status',
            'task',
            'todos',
            'entries',
            'policy',
          ])
            if (random.nextBool()) k: value(depth + 1),
        },
      };
      final types = [...knownHostMessageTypes, 'nope'];
      for (var i = 0; i < 2000; i++) {
        final raw = <String, Object?>{
          'type': types[random.nextInt(types.length)],
          for (final k in [
            'requestId',
            'ok',
            'task',
            'todo',
            'todos',
            'entries',
            'policy',
            'at',
            'code',
            'hostId',
          ])
            if (random.nextBool()) k: value(0),
        };
        // Round-trip through JSON so the shapes are what a wire delivers.
        final wire = jsonDecode(jsonEncode(raw)) as Map<String, Object?>;
        expect(() => parseHostMessage(wire), returnsNormally);
      }
    });
  });

  test('toWire round-trips through the parser', () {
    for (final MapEntry(:key, :value) in hostExamples.entries) {
      final first = parseHostMessage(decode(value));
      final again = parseHostMessage(
        jsonDecode(jsonEncode(first.toWire())) as Map<String, Object?>,
      );
      expect(again.runtimeType, first.runtimeType, reason: key);
      expect(again.toWire(), first.toWire(), reason: key);
    }
  });
}
