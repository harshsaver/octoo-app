/// The test Octo's brain: Claude, with the laptop's tools, doing each task
/// she approved. Raw HTTP to the Messages API (there is no Dart SDK).
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:octo_family/protocol/models/task.dart';
import 'package:octo_family/transport/simulator/simulated_computer.dart';

import 'laptop_tools.dart';

const octoModel = 'claude-opus-5-5';

class ClaudeException implements Exception {
  const ClaudeException(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => 'Claude API error $status: $message';
}

class OctoBrain implements TaskWorker {
  OctoBrain({
    required this.apiKey,
    required this.tools,
    required this.person,
    required this.computerName,
    required this.screenCapture,
    this.osName = 'Linux',
    http.Client? client,
    this.maxTurns = 25,
    this.log,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final List<OctoTool> tools;
  final String person;
  final String computerName;
  final String osName;
  final int maxTurns;
  final void Function(String line)? log;

  /// Captures the screen for `screen.request`.
  final Future<WorkScreen?> Function() screenCapture;
  final http.Client _client;

  @override
  Future<WorkScreen?> screen() => screenCapture();

  String _system(Task task) =>
      'You are Octo, a calm helper that lives on $person\'s computer ("$computerName", $osName). '
      'Family members text you from their phones to get things checked or done on it, because $person '
      'is not comfortable with computers. ${task.fromName ?? 'A family member'} sent this task, and '
      '$person has already said OK to it.\n\n'
      'Find out with your tools instead of guessing, and do what was asked. Shell commands are shown to '
      '$person first and only run if she agrees, so explain each one in a short plain sentence. Do not '
      'change more than the task needs, never touch passwords, payments or personal files, and stop if '
      'something looks risky.\n\n'
      'When you are finished, call `finish` once: `for_helper` is a short report for '
      '${task.fromName ?? 'the family member'} (facts, numbers, what you changed); `for_her` is one '
      'friendly sentence for $person in simple words. If you could not do it, say why in both.';

  List<Map<String, Object?>> get _toolDefs => [
    for (final t in tools) t.definition,
    {
      'name': 'finish',
      'description': 'End the task with the reports. Call it exactly once, last.',
      'strict': true,
      'input_schema': {
        'type': 'object',
        'properties': {
          'outcome': {
            'type': 'string',
            'enum': ['done', 'gave_up'],
          },
          'for_helper': {'type': 'string'},
          'for_her': {'type': 'string'},
        },
        'required': ['outcome', 'for_helper', 'for_her'],
        'additionalProperties': false,
      },
    },
  ];

  Future<Map<String, Object?>> _call(Task task, List<Map<String, Object?>> messages) async {
    final response = await _client
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'content-type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            // Declined requests are re-run on Anthropic's recommended model.
            'anthropic-beta': 'server-side-fallback-2026-07-01',
          },
          body: jsonEncode({
            'model': octoModel,
            'max_tokens': 16000,
            'thinking': {'type': 'adaptive'},
            'output_config': {'effort': 'medium'},
            'fallbacks': 'default',
            'system': _system(task),
            'tools': _toolDefs,
            'messages': messages,
          }),
        )
        .timeout(const Duration(minutes: 5));
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ClaudeException(response.statusCode, 'unreadable response');
    }
    if (response.statusCode != 200 || json is! Map<String, Object?>) {
      final error = json is Map<String, Object?> ? json['error'] : null;
      throw ClaudeException(
        response.statusCode,
        error is Map<String, Object?> ? '${error['message']}' : 'request failed',
      );
    }
    return json;
  }

  @override
  Future<WorkOutcome> work(
    Task task, {
    required void Function(WorkStep step) step,
    required bool Function() stopped,
  }) async {
    // Append-only: each response goes back exactly as received (its
    // thinking blocks must stay intact).
    final messages = <Map<String, Object?>>[
      {'role': 'user', 'content': task.text},
    ];
    String? lastShot;
    for (var turn = 0; turn < maxTurns; turn++) {
      if (stopped()) return const WorkOutcome(status: 'failed', result: 'Stopped.');
      final reply = await _call(task, messages);
      final content = (reply['content'] as List<Object?>? ?? const []).cast<Map<String, Object?>>();
      final stop = reply['stop_reason'];
      if (stop == 'refusal') {
        return const WorkOutcome(
          status: 'blocked',
          result: "Octo can't help with that request.",
          resultForHer: "I can't help with that one.",
        );
      }
      if (stop == 'max_tokens') {
        // A cut-off turn may hold an incomplete tool call: don't run it.
        return const WorkOutcome(status: 'gaveUp', result: 'Octo ran out of room for its answer.');
      }
      messages.add({'role': 'assistant', 'content': content});
      final calls = content.where((b) => b['type'] == 'tool_use').toList();
      if (calls.isEmpty) {
        // Ended without `finish`: its words are the report.
        final text = content.where((b) => b['type'] == 'text').map((b) => b['text']).join('\n').trim();
        return WorkOutcome(status: 'done', result: text.isEmpty ? 'Done.' : text, screenshot: lastShot);
      }
      final results = <Map<String, Object?>>[];
      for (final call in calls) {
        final name = call['name'];
        final input = (call['input'] as Map<String, Object?>?) ?? const {};
        if (name == 'finish') {
          return WorkOutcome(
            status: input['outcome'] == 'gave_up' ? 'gaveUp' : 'done',
            result: '${input['for_helper'] ?? ''}'.trim(),
            resultForHer: '${input['for_her'] ?? ''}'.trim(),
            screenshot: lastShot,
          );
        }
        final tool = tools.where((t) => t.name == name).firstOrNull;
        if (tool == null || stopped()) {
          results.add({
            'type': 'tool_result',
            'tool_use_id': call['id'],
            'is_error': true,
            'content': tool == null ? 'Unknown tool.' : 'The task was stopped.',
          });
          continue;
        }
        log?.call('Octo → $name ${input.isEmpty ? '' : jsonEncode(input)}');
        ToolOutput out;
        try {
          out = await tool.run(input);
        } on Object catch (e) {
          out = ToolOutput(did: 'Tried $name, but it failed', text: 'Failed: $e', ok: false);
        }
        step(WorkStep(did: out.did, say: out.say, ok: out.ok, error: out.ok ? null : out.text));
        final jpeg = out.jpeg;
        if (jpeg != null) lastShot = jpegDataUri(jpeg);
        results.add({
          'type': 'tool_result',
          'tool_use_id': call['id'],
          if (!out.ok) 'is_error': true,
          'content': [
            {'type': 'text', 'text': out.text},
            if (jpeg != null)
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': jpeg[0] == 0x89 ? 'image/png' : 'image/jpeg',
                  'data': base64Encode(jpeg),
                },
              },
          ],
        });
      }
      // Every result for this turn in one message.
      messages.add({'role': 'user', 'content': results});
    }
    return const WorkOutcome(status: 'gaveUp', result: 'Octo took too many steps and stopped.');
  }

  void close() => _client.close();
}
