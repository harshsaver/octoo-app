import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/protocol/app_message.dart';
import 'package:octo_family/protocol/models/policy.dart';

import 'brief_examples.dart';

void main() {
  test('every brief example parses and serialises back byte for byte', () {
    for (final json in appExamples) {
      final message = AppMessage.parse(decode(json));
      expect(message, isNot(isA<UnknownAppMessage>()), reason: json);
      expect(jsonEncode(message.toJson()), json, reason: json);
    }
  });

  test('typed constructors produce the brief JSON', () {
    expect(
      const TaskCreate(
        requestId: 'r1',
        text: "Join the Discord server from Priya's invite and start the call",
        job: 'call.join',
      ).toJson(),
      decode(appExamples[3]),
    );
    expect(const TaskCreate(requestId: 'r', text: 'hi').toJson(), {
      'type': 'task.create',
      'requestId': 'r',
      'text': 'hi',
    }, reason: 'job is optional and omitted');
    expect(const LogRequest(requestId: 'l').toJson(), {
      'type': 'log',
      'requestId': 'l',
    });
    expect(const ScreenRequest().toJson(), {'type': 'screen.request'});
  });

  test('requests say which reply they wait for', () {
    expect(const StatusRequest(requestId: 'q').expects, ReplyKind.status);
    expect(const TodosRequest(requestId: 'd').expects, ReplyKind.todos);
    expect(const LogRequest(requestId: 'l').expects, ReplyKind.log);
    expect(
      const TaskCreate(requestId: 'r', text: 't').expects,
      ReplyKind.result,
    );
    expect(
      const TaskStop(requestId: 'r', taskId: 't').expects,
      ReplyKind.result,
    );
    expect(
      const PolicySet(requestId: 'p', policy: Policy()).expects,
      ReplyKind.result,
    );
    expect(const ProfileSet(requestId: 'p').expects, ReplyKind.result);
  });

  test('policy.set keeps values and fields this app does not know', () {
    final received = Policy.fromJson(
      decode(
        '{"askEveryChange":true,"askBeforeLooking":false,"never":["install","teleport"],'
        '"blockedSites":["facebook.com"],"quietHours":{"from":22,"to":7}}',
      ),
    );
    final edited = received.copyWith(askBeforeLooking: true);
    final wire = PolicySet(requestId: 'p1', policy: edited).toJson();
    expect(wire['policy'], {
      'askEveryChange': true,
      'askBeforeLooking': true,
      'never': ['install', 'teleport'],
      'blockedSites': ['facebook.com'],
      'quietHours': {'from': 22, 'to': 7},
    });
  });

  test('unknown and malformed app messages parse to Unknown', () {
    expect(AppMessage.parse({'type': 'dance'}), isA<UnknownAppMessage>());
    expect(
      AppMessage.parse({'type': 'task.create', 'requestId': 'r'}),
      isA<UnknownAppMessage>(),
    );
    expect(AppMessage.parse({}), isA<UnknownAppMessage>());
  });
}
