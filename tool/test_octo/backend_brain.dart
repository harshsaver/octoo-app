/// The test Octo's brain: October's backend agent (saturday
/// `POST /api/octo/agent/step`), which holds the model and its key. Each
/// call sends the task, a fresh screenshot and the steps so far, and gets
/// one next step back, which runs here on the laptop, as the Octo engine
/// does (docs/OCTO_BACKEND.md in saturday).
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:octo_family/protocol/models/task.dart';
import 'package:octo_family/transport/simulator/simulated_computer.dart';

import 'laptop.dart';

class BackendException implements Exception {
  const BackendException(this.status, this.code, this.message);

  final int status;
  final String? code;

  /// A sentence the backend means to be shown as is.
  final String message;

  @override
  String toString() => 'BackendException($status, $code): $message';
}

class BackendBrain implements TaskWorker {
  BackendBrain({
    required this.apiBase,
    required this.accessToken,
    required this.capture,
    required this.hands,
    required this.approveStep,
    required this.person,
    this.language,
    this.checkWifi = checkNetwork,
    http.Client? client,
    this.maxSteps = 30,
    this.settle = const Duration(milliseconds: 1500),
    this.log,
  }) : _client = client ?? http.Client();

  /// `https://www.october.dev`.
  final Uri apiBase;

  /// The signed-in October account's token (a user token, which the agent
  /// accepts like a computer's; the account is billed).
  final Future<String?> Function() accessToken;
  final Future<Shot> Function() capture;
  final Hands hands;

  /// Asks the person at the laptop before an `act` step runs.
  final Future<bool> Function(String what) approveStep;
  final String person;
  final String? language;
  final Future<String> Function() checkWifi;
  final int maxSteps;

  /// How long the screen gets to change before the next screenshot.
  final Duration settle;
  final void Function(String line)? log;
  final http.Client _client;

  @override
  Future<WorkScreen?> screen() async {
    final shot = await capture();
    return WorkScreen(dataUri: shot.dataUri);
  }

  Future<Map<String, Object?>> _step(Task task, Shot shot, List<Map<String, Object?>> history) async {
    final token = await accessToken();
    if (token == null) throw const BackendException(401, 'unauthorized', 'Sign in to October first.');
    final http.Response response;
    try {
      response = await _client
          .post(
            apiBase.replace(path: '/api/octo/agent/step'),
            headers: {
              'authorization': 'Bearer $token',
              'content-type': 'application/json',
              'x-octo-request-id': task.id,
            },
            body: jsonEncode({
              'task': {'id': task.id, 'text': task.text, 'job': task.job ?? 'general', 'fromName': ?task.fromName},
              'person': person,
              'language': ?language,
              'screen': {'width': shot.width, 'height': shot.height},
              'screenshot': base64Encode(shot.png),
              'history': history,
            }),
          )
          .timeout(const Duration(seconds: 120));
    } on TimeoutException {
      throw const BackendException(0, null, "October's agent didn't answer in time.");
    }
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw BackendException(response.statusCode, null, "October's agent sent something unreadable.");
    }
    if (response.statusCode != 200 || json is! Map<String, Object?>) {
      final error = json is Map<String, Object?> ? json['error'] : null;
      final e = error is Map<String, Object?> ? error : const <String, Object?>{};
      throw BackendException(
        response.statusCode,
        e['code'] as String?,
        e['message'] as String? ?? "October's agent couldn't take this step (${response.statusCode}).",
      );
    }
    return json;
  }

  static String describe(Map<String, Object?> act) => switch (act['op']) {
    'click' => '${act['double'] == true ? 'Double-click' : 'Click'} ${act['target'] == null ? 'at (${act['x']}, ${act['y']})' : '“${act['target']}”'}',
    'type' => 'Type “${act['text']}”',
    'keys' => 'Press ${(act['keys'] as List?)?.join(', ')}',
    'scroll' => 'Scroll',
    'openUrl' => 'Open ${act['url']}',
    'openApp' => 'Open the app ${act['name']}',
    _ => 'Do “${act['op']}”',
  };

  Future<void> _run(Map<String, Object?> act, Shot shot) async {
    int n(String key) => (act[key] as num?)?.toInt() ?? 0;
    switch (act['op']) {
      case 'click':
        await hands.click(n('x'), n('y'), on: shot, double: act['double'] == true);
      case 'type':
        await hands.type('${act['text']}');
      case 'keys':
        await hands.keys([for (final k in act['keys'] as List? ?? const []) '$k']);
      case 'scroll':
        await hands.scroll(n('dx'), n('dy'));
      case 'openUrl':
        await hands.openUrl('${act['url']}');
      case 'openApp':
        await hands.openApp('${act['name']}');
      default:
        throw StateError('Octo has no hands for “${act['op']}”.');
    }
  }

  @override
  Future<WorkOutcome> work(
    Task task, {
    required void Function(WorkStep step) step,
    required bool Function() stopped,
  }) async {
    final history = <Map<String, Object?>>[];
    Shot? last;
    for (var i = 0; i < maxSteps; i++) {
      if (stopped()) return const WorkOutcome(status: 'failed', result: 'Stopped.');
      final shot = last = await capture();
      final Map<String, Object?> next;
      try {
        next = await _step(task, shot, history);
      } on BackendException catch (e) {
        log?.call('agent: ${e.status} ${e.code ?? ''} ${e.message}');
        final blocked = e.code == 'declined' || e.code == 'plan_required' || e.code == 'credit_exhausted' || e.code == 'free_limit';
        return WorkOutcome(status: blocked ? 'blocked' : 'failed', result: e.message, resultForHer: e.message);
      }
      final say = next['say'] as String?;
      log?.call('agent → ${jsonEncode(next)}');
      switch (next['step']) {
        case 'done':
          final summary = '${next['summary'] ?? 'Done.'}';
          return WorkOutcome(status: 'done', result: summary, resultForHer: say ?? summary, screenshot: shot.dataUri);
        case 'giveUp':
          final reason = '${next['reason'] ?? "Octo couldn't see how to do it."}';
          return WorkOutcome(status: 'gaveUp', result: reason, resultForHer: 'I need help with this one.', screenshot: shot.dataUri);
        case 'check':
          final what = '${next['check']}';
          final String note;
          if (what == 'wifi') {
            note = await checkWifi();
          } else {
            note = 'This computer has no "$what" check.';
          }
          step(WorkStep(did: 'Checked $what: $note', say: say));
          history.add({'step': next, 'ok': true, 'note': _short(note)});
        case 'act':
          final act = (next['act'] as Map?)?.cast<String, Object?>() ?? const {};
          final what = describe(act);
          if (!await approveStep(say == null || say.isEmpty ? what : '$what  ($say)')) {
            history.add({'step': next, 'ok': false, 'note': 'The person at the computer said no.'});
            step(WorkStep(did: '$what — she said no', say: say, ok: false));
            return WorkOutcome(
              status: 'gaveUp',
              result: '$person didn’t allow: $what.',
              resultForHer: 'OK, I stopped.',
              screenshot: shot.dataUri,
            );
          }
          try {
            await _run(act, shot);
            history.add({'step': next, 'ok': true});
            step(WorkStep(did: what, say: say));
          } on Object catch (e) {
            history.add({'step': next, 'ok': false, 'note': _short('$e')});
            step(WorkStep(did: what, say: say, ok: false, error: '$e'));
          }
          await Future<void>.delayed(settle);
        default:
          return WorkOutcome(status: 'failed', result: "October's agent sent a step this Octo doesn't know.", screenshot: last.dataUri);
      }
      // The backend takes at most 40 steps of history.
      if (history.length > 40) history.removeAt(0);
    }
    return WorkOutcome(status: 'gaveUp', result: 'Octo took too many steps and stopped.', screenshot: last?.dataUri);
  }

  static String _short(String s) => s.length <= 300 ? s : '${s.substring(0, 297)}…';

  Future<void> close() async {
    _client.close();
    await hands.close();
  }
}
