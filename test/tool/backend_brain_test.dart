import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:octo_family/protocol/models/task.dart';
import 'package:octo_family/transport/simulator/sample_screen.dart';
import 'package:octo_family/transport/simulator/simulated_computer.dart';

import '../../tool/test_octo/backend_brain.dart';
import '../../tool/test_octo/laptop.dart';

/// October's agent, scripted: answers each step request with the next
/// reply and records the requests.
class FakeAgent {
  FakeAgent(this.replies);

  final List<http.Response> replies;
  final List<http.Request> requests = [];

  Map<String, Object?> body(int i) => jsonDecode(requests[i].body) as Map<String, Object?>;

  Future<http.Response> handle(http.Request r) async {
    requests.add(r);
    return replies.removeAt(0);
  }
}

http.Response _step(Map<String, Object?> step) => http.Response(jsonEncode(step), 200);

class FakeHands implements Hands {
  final done = <String>[];

  @override
  Future<void> click(int x, int y, {required Shot on, bool double = false}) async =>
      done.add('click $x,$y of ${on.width}x${on.height}');

  @override
  Future<void> type(String text) async => done.add('type $text');

  @override
  Future<void> keys(List<String> keys) async => done.add('keys ${keys.join('+')}');

  @override
  Future<void> scroll(int dx, int dy) async => done.add('scroll $dx,$dy');

  @override
  Future<void> openUrl(String url) async => done.add('open $url');

  @override
  Future<void> openApp(String name) async => throw StateError('no app called "$name" is installed');

  @override
  Future<void> close() async {}
}

// A 1×1 PNG.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

const _task = Task(id: 't_1', from: 'u_1', fromName: 'Harsh', text: 'Join the Zoom call', job: 'join-call', status: 'running');

void main() {
  late FakeHands hands;
  final asked = <String>[];
  var allow = true;

  BackendBrain brain(FakeAgent agent) => BackendBrain(
    apiBase: Uri.parse('https://www.october.dev'),
    accessToken: () async => 'user-jwt',
    capture: () async => Shot(Uint8List.fromList(_png), 1600, 900),
    hands: hands,
    approveStep: (what) async {
      asked.add(what);
      return allow;
    },
    person: 'Mom',
    checkWifi: () async => 'Wi-Fi: Home signal 80%; internet reachable',
    settle: Duration.zero,
    client: MockClient(agent.handle),
  );

  setUp(() {
    hands = FakeHands();
    asked.clear();
    allow = true;
  });

  test('runs the agent step by step: act, check, act, done', () async {
    final agent = FakeAgent([
      _step({'step': 'act', 'say': 'Opening the invite link', 'act': {'op': 'openUrl', 'url': 'https://zoom.us/j/1'}, 'may': ['open']}),
      _step({'step': 'check', 'check': 'wifi', 'say': 'Checking the Wi-Fi'}),
      _step({'step': 'act', 'say': 'Joining', 'act': {'op': 'click', 'x': 800, 'y': 450, 'target': 'Join'}}),
      _step({'step': 'done', 'summary': 'She is in the call.'}),
    ]);
    final steps = <WorkStep>[];
    final outcome = await brain(agent).work(_task, step: steps.add, stopped: () => false);

    expect(hands.done, ['open https://zoom.us/j/1', 'click 800,450 of 1600x900']);
    expect(asked, ['Open https://zoom.us/j/1  (Opening the invite link)', 'Click “Join”  (Joining)']);
    expect(steps.map((s) => s.did), [
      'Open https://zoom.us/j/1',
      'Checked wifi: Wi-Fi: Home signal 80%; internet reachable',
      'Click “Join”',
    ]);
    expect(outcome.status, 'done');
    expect(outcome.result, 'She is in the call.');
    expect(outcome.screenshot, startsWith('data:image/png;base64,'));

    // The request the backend validates: the user's token, the task, the
    // screen and a base64 PNG without a data: prefix.
    final r = agent.requests.first;
    expect(r.url.toString(), 'https://www.october.dev/api/octo/agent/step');
    expect(r.headers['authorization'], 'Bearer user-jwt');
    final first = agent.body(0);
    expect(first['task'], {'id': 't_1', 'text': 'Join the Zoom call', 'job': 'join-call', 'fromName': 'Harsh'});
    expect(first['screen'], {'width': 1600, 'height': 900});
    expect(first['screenshot'], base64Encode(_png));
    expect(first['history'], isEmpty);

    // Each step goes back in the history with how it went.
    final history = agent.body(3)['history']! as List;
    expect(history.map((h) => ((h as Map)['step'] as Map)['step']), ['act', 'check', 'act']);
    expect((history[1] as Map)['note'], contains('internet reachable'));
    expect(history.every((h) => (h as Map)['ok'] == true), isTrue);
  });

  test('a step that fails goes back as not ok, with the reason', () async {
    final agent = FakeAgent([
      _step({'step': 'act', 'say': 'Opening Zoom', 'act': {'op': 'openApp', 'name': 'Zoom'}}),
      _step({'step': 'giveUp', 'reason': 'Zoom is not installed.'}),
    ]);
    final outcome = await brain(agent).work(_task, step: (_) {}, stopped: () => false);
    final turn = (agent.body(1)['history']! as List).single as Map;
    expect(turn['ok'], isFalse);
    expect(turn['note'], contains('no app called "Zoom"'));
    expect((outcome.status, outcome.result), ('gaveUp', 'Zoom is not installed.'));
  });

  test('the person at the laptop says no: nothing runs and the task stops', () async {
    allow = false;
    final agent = FakeAgent([
      _step({'step': 'act', 'say': 'Typing', 'act': {'op': 'type', 'text': 'hello'}}),
    ]);
    final outcome = await brain(agent).work(_task, step: (_) {}, stopped: () => false);
    expect(hands.done, isEmpty);
    expect(outcome.status, 'gaveUp');
    expect(agent.requests, hasLength(1));
  });

  test("the backend's own error sentence reaches the helper", () async {
    final agent = FakeAgent([
      http.Response(jsonEncode({'error': {'code': 'plan_required', 'message': 'Octo needs a paid October plan.'}}), 403),
    ]);
    final outcome = await brain(agent).work(_task, step: (_) {}, stopped: () => false);
    expect((outcome.status, outcome.result), ('blocked', 'Octo needs a paid October plan.'));
  });

  test('scroll, keys and double-click reach the hands', () async {
    final agent = FakeAgent([
      _step({'step': 'act', 'say': '', 'act': {'op': 'scroll', 'dx': 0, 'dy': 300}}),
      _step({'step': 'act', 'say': '', 'act': {'op': 'keys', 'keys': ['Ctrl+L']}}),
      _step({'step': 'act', 'say': '', 'act': {'op': 'click', 'x': 1, 'y': 2, 'double': true}}),
      _step({'step': 'done', 'summary': 'ok'}),
    ]);
    await brain(agent).work(_task, step: (_) {}, stopped: () => false);
    expect(hands.done, ['scroll 0,300', 'keys Ctrl+L', 'click 1,2 of 1600x900']);
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

    test("screen.request sends the worker's real screenshot", () async {
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
