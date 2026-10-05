import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:octo_family/protocol/models/task.dart';
import 'package:octo_family/transport/simulator/sample_screen.dart';
import 'package:octo_family/transport/simulator/simulated_computer.dart';

import '../../tool/test_octo/laptop_tools.dart';
import '../../tool/test_octo/octo_brain.dart';

/// A scripted Messages API: answers each request with the next reply and
/// records what it was sent.
class FakeClaude {
  FakeClaude(this.replies);

  final List<Map<String, Object?>> replies;
  final List<http.Request> requests = [];

  Map<String, Object?> body(int i) => jsonDecode(requests[i].body) as Map<String, Object?>;

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    return http.Response(jsonEncode(replies.removeAt(0)), 200, headers: {'content-type': 'application/json'});
  }
}

Map<String, Object?> _reply(List<Map<String, Object?>> content, String stop) => {
  'id': 'msg_1',
  'type': 'message',
  'role': 'assistant',
  'model': octoModel,
  'content': content,
  'stop_reason': stop,
};

const _task = Task(id: 't_1', from: 'u_1', fromName: 'Harsh', text: 'Is the Wi-Fi OK?', status: 'running');

void main() {
  final calls = <String>[];
  final tools = [
    OctoTool(
      name: 'check_network',
      description: 'Network health.',
      properties: const {},
      run: (_) async {
        calls.add('check_network');
        return const ToolOutput(did: 'Checked the network', say: 'Checking the Wi-Fi…', text: 'wifi: Home, signal 80');
      },
    ),
    OctoTool(
      name: 'take_screenshot',
      description: 'Screen.',
      properties: const {},
      run: (_) async =>
          ToolOutput(did: 'Looked at the screen', text: 'Screenshot attached.', jpeg: Uint8List.fromList([0xff, 0xd8, 1])),
    ),
  ];

  OctoBrain brain(FakeClaude claude) => OctoBrain(
    apiKey: 'sk-test',
    tools: tools,
    person: 'Mom',
    computerName: "Mom's laptop",
    screenCapture: () async => null,
    client: MockClient(claude.handle),
  );

  setUp(calls.clear);

  test('runs the tools Claude asks for, reports steps, and finishes with both reports', () async {
    final thinking = {'type': 'thinking', 'thinking': '', 'signature': 'sig'};
    final claude = FakeClaude([
      _reply([
        thinking,
        {'type': 'tool_use', 'id': 'tu_1', 'name': 'check_network', 'input': <String, Object?>{}},
        {'type': 'tool_use', 'id': 'tu_2', 'name': 'take_screenshot', 'input': <String, Object?>{}},
      ], 'tool_use'),
      _reply([
        {
          'type': 'tool_use',
          'id': 'tu_3',
          'name': 'finish',
          'input': {'outcome': 'done', 'for_helper': 'Wi-Fi "Home" is fine, signal 80%.', 'for_her': 'Your Wi-Fi is fine!'},
        },
      ], 'tool_use'),
    ]);
    final steps = <WorkStep>[];
    final outcome = await brain(claude).work(_task, step: steps.add, stopped: () => false);

    expect(calls, ['check_network']);
    expect(steps.map((s) => s.did), ['Checked the network', 'Looked at the screen']);
    expect(outcome.status, 'done');
    expect(outcome.result, 'Wi-Fi "Home" is fine, signal 80%.');
    expect(outcome.resultForHer, 'Your Wi-Fi is fine!');
    expect(outcome.screenshot, startsWith('data:image/jpeg;base64,'));

    final first = claude.body(0);
    expect(first['model'], 'claude-opus-5-5');
    expect(first['fallbacks'], 'default');
    expect(first['thinking'], {'type': 'adaptive'});
    expect(claude.requests[0].headers['anthropic-beta'], 'server-side-fallback-2026-07-01');
    expect(claude.requests[0].headers['x-api-key'], 'sk-test');
    expect((first['tools']! as List).map((t) => (t as Map)['name']), containsAll(['check_network', 'finish']));

    // Append-only history: the assistant turn goes back exactly as received,
    // and both tool results travel in one user message.
    final second = claude.body(1)['messages']! as List;
    expect(second, hasLength(3));
    expect((second[1] as Map)['content'], [
      thinking,
      {'type': 'tool_use', 'id': 'tu_1', 'name': 'check_network', 'input': <String, Object?>{}},
      {'type': 'tool_use', 'id': 'tu_2', 'name': 'take_screenshot', 'input': <String, Object?>{}},
    ]);
    final results = (second[2] as Map)['content']! as List;
    expect(results.map((r) => (r as Map)['tool_use_id']), ['tu_1', 'tu_2']);
    final image = ((results[1] as Map)['content']! as List)[1] as Map;
    expect((image['source']! as Map)['media_type'], 'image/jpeg');
  });

  test('a refusal ends the task as blocked, without running anything', () async {
    final claude = FakeClaude([_reply(const [], 'refusal')]);
    final outcome = await brain(claude).work(_task, step: (_) {}, stopped: () => false);
    expect(outcome.status, 'blocked');
    expect(calls, isEmpty);
  });

  test('plain text without finish is the report', () async {
    final claude = FakeClaude([
      _reply([
        {'type': 'text', 'text': 'All good.'},
      ], 'end_turn'),
    ]);
    final outcome = await brain(claude).work(_task, step: (_) {}, stopped: () => false);
    expect((outcome.status, outcome.result), ('done', 'All good.'));
  });

  test('API errors surface as ClaudeException', () async {
    final failing = OctoBrain(
      apiKey: 'bad',
      tools: tools,
      person: 'Mom',
      computerName: 'PC',
      screenCapture: () async => null,
      client: MockClient(
        (_) async => http.Response(jsonEncode({'type': 'error', 'error': {'type': 'authentication_error', 'message': 'invalid x-api-key'}}), 401),
      ),
    );
    await expectLater(
      failing.work(_task, step: (_) {}, stopped: () => false),
      throwsA(isA<ClaudeException>().having((e) => e.status, 'status', 401)),
    );
  });

  group('SimulatedComputer with a worker', () {
    test('an approved task runs on the worker: steps, then its result', () async {
      final worker = _FakeWorker();
      final computer = SimulatedComputer(
        computerId: 'c',
        hostId: 'h',
        computerName: "Mom's laptop",
        settings: SimulatorSettings(autopilot: false),
      )..worker = worker;
      computer.helpers['u_1'] = const SimHelper(id: 'u_1', name: 'Harsh', device: 'phone');
      final out = <Map<String, Object?>>[];
      computer.outbound.listen(out.add);

      computer.receive({'type': 'task.create', 'requestId': 'r1', 'text': 'Install Zoom'}, from: 'u_1');
      if (computer.consents.isNotEmpty) computer.momSaysOk();
      await worker.started.future;
      worker.step!(const WorkStep(did: 'Opened the store', say: 'Opening the store…'));
      worker.finish.complete(const WorkOutcome(status: 'done', result: 'Zoom is installed.', resultForHer: 'Zoom is ready!'));
      await Future<void>.delayed(Duration.zero);

      final last = out.lastWhere((m) => m['type'] == 'task')['task']! as Map;
      expect(last['status'], 'done');
      expect(last['result'], 'Zoom is installed.');
      expect((last['steps']! as List).single, containsPair('did', 'Opened the store'));
      expect(computer.momScreen.last, 'Octo: Zoom is ready!');
      computer.dispose();
    });

    test('screen.request sends the worker\'s real screenshot', () async {
      final computer = SimulatedComputer(
        computerId: 'c',
        hostId: 'h',
        computerName: 'PC',
        settings: SimulatorSettings(autopilot: false),
      )..worker = _FakeWorker();
      computer.helpers['u_1'] = const SimHelper(id: 'u_1', name: 'Harsh', device: 'phone');
      final out = <Map<String, Object?>>[];
      computer.outbound.listen(out.add);
      computer.receive({'type': 'screen.request'}, from: 'u_1');
      computer.momSaysOk();
      await Future<void>.delayed(Duration.zero);
      final screen = out.lastWhere((m) => m['type'] == 'screen');
      expect(screen['ok'], isTrue);
      expect(screen['screenshot'], sampleScreenDataUri);
      computer.dispose();
    });
  });
}

class _FakeWorker implements TaskWorker {
  final started = Completer<void>();
  final finish = Completer<WorkOutcome>();
  void Function(WorkStep)? step;

  @override
  Future<WorkOutcome> work(Task task, {required void Function(WorkStep step) step, required bool Function() stopped}) {
    this.step = step;
    started.complete();
    return finish.future;
  }

  @override
  Future<WorkScreen?> screen() async => const WorkScreen(dataUri: sampleScreenDataUri);
}
