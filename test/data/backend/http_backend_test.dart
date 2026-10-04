import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:octo_family/data/backend/http_backend.dart';
import 'package:octo_family/data/backend/octo_backend.dart';
import 'package:octo_family/data/enrollment/enrollment_repository.dart';

/// The saturday contract (docs/OCTO_BACKEND.md), as recorded requests and
/// canned replies.
class _Server {
  final requests = <http.Request>[];
  http.Response Function(http.Request request) reply = (_) =>
      http.Response('', 204);

  MockClient get client => MockClient((request) async {
    requests.add(request);
    return reply(request);
  });

  Map<String, Object?> body(int i) =>
      jsonDecode(requests[i].body) as Map<String, Object?>;
}

http.Response _json(
  Object body, [
  int status = 200,
  Map<String, String> headers = const {},
]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json', ...headers},
);

void main() {
  late _Server server;
  late HttpBackend backend;
  String? token = 'user-token';

  setUp(() {
    server = _Server();
    token = 'user-token';
    backend = HttpBackend(
      baseUrl: Uri.parse('https://www.october.dev'),
      accessToken: () async => token,
      client: server.client,
    );
  });

  test('lists computers with their look, role, last seen and mute', () async {
    server.reply = (_) => _json({
      'computers': [
        {
          'id': 'cmp_${'a' * 24}',
          'hostId': 'h_1',
          'name': "Mom's laptop",
          'person': 'Mom',
          'language': 'hi',
          'os': 'windows',
          'octo': 'ocean-glasses',
          'role': 'owner',
          'createdAt': '2026-10-04T12:00:00Z',
          'lastSeenAt': '2026-10-04T12:30:00Z',
          'muted': true,
        },
        {'name': 'no id: skipped as malformed'},
      ],
    });
    await expectLater(
      backend.listComputers(),
      throwsA(isA<BackendException>()),
    );
    server.reply = (_) => _json({
      'computers': [
        {
          'id': 'cmp_${'a' * 24}',
          'name': "Mom's laptop",
          'person': 'Mom',
          'role': 'member',
          'lastSeenAt': '2026-10-04T12:30:00Z',
        },
      ],
    });
    final list = await backend.listComputers();
    final req = server.requests.last;
    expect(req.method, 'GET');
    expect(req.url.toString(), 'https://www.october.dev/api/octo/computers');
    expect(req.headers['authorization'], 'Bearer user-token');
    expect(list.single.role, 'member');
    expect(
      list.single.lastSeenAt,
      DateTime.parse('2026-10-04T12:30:00Z').millisecondsSinceEpoch,
    );
    expect(list.single.muted, isFalse);
  });

  test('claims from the QR or a typed code, with the profile', () async {
    server.reply = (_) => _json({
      'computerId': 'cmp_${'b' * 24}',
      'hostId': 'h_2',
      'name': "Mom's laptop",
    });
    final link = await LinkEnrollment().resolve(
      'https://www.october.dev/octo/add#en_${'0' * 24}.${'s' * 43}',
    );
    final result = await backend.claim(
      link.credentials,
      person: 'Mom',
      language: 'hi',
    );
    expect(result.computerId, 'cmp_${'b' * 24}');
    expect(result.hostId, 'h_2');
    expect(server.body(0), {
      'enrollId': 'en_${'0' * 24}',
      'claimSecret': 's' * 43,
      'person': 'Mom',
      'language': 'hi',
    });

    final typed = await LinkEnrollment().resolve('7k4q-mx2d');
    await backend.claim(typed.credentials);
    expect(server.body(1), {'claimCode': '7K4QMX2D'});
    expect(
      typed.credentials.toString(),
      isNot(contains('7K4Q')),
      reason: 'codes and secrets stay out of logs',
    );
  });

  test('PATCH, DELETE, usage, push and notification choices use the documented shapes', () async {
    server.reply = (request) => switch ((request.method, request.url.path)) {
      ('PATCH', _) => _json({
        'id': 'cmp_${'c' * 24}',
        'name': 'Laptop',
        'person': 'Ma',
        'octo': 'mint-headphones',
        'role': 'owner',
      }),
      ('GET', '/api/octo/usage') => _json({
        'month': '2026-10',
        'tasks': 3,
        'steps': 20,
        'questions': 5,
        'cost': {'amount': 0.42, 'currency': 'USD'},
        'byJob': {},
      }),
      ('GET', '/api/octo/push/preferences') => _json({
        'off': ['taskEnded'],
      }),
      ('PUT', '/api/octo/push/preferences') => _json({
        'off': ['taskEnded'],
      }),
      ('PUT', _) => _json({'computerId': 'cmp_${'c' * 24}', 'muted': true}),
      _ => http.Response('', 204),
    };
    final id = 'cmp_${'c' * 24}';
    final patched = await backend.patchComputer(
      id,
      person: 'Ma',
      octo: 'mint-headphones',
    );
    expect(patched.person, 'Ma');
    expect(server.body(0), {'person': 'Ma', 'octo': 'mint-headphones'});

    await backend.deleteComputer(id);
    expect(server.requests[1].method, 'DELETE');
    expect(server.requests[1].url.path, '/api/octo/computers/$id');

    final usage = await backend.usage(id, '2026-10');
    expect(server.requests[2].url.queryParameters, {
      'computerId': id,
      'month': '2026-10',
    });
    expect(
      (usage.tasks, usage.questions, usage.costAmount, usage.currency),
      (3, 5, 0.42, 'USD'),
    );

    await backend.registerPush(
      token: 'fcm-token',
      platform: 'android',
      deviceLabel: "Harsh's Pixel",
      appVersion: '1.0.0',
    );
    expect(server.body(3), {
      'token': 'fcm-token',
      'platform': 'android',
      'deviceLabel': "Harsh's Pixel",
      'appVersion': '1.0.0',
    });
    await backend.unregisterPush('fcm-token');
    expect(server.requests[4].method, 'DELETE');
    expect(server.body(4), {'token': 'fcm-token'});

    await backend.setMuted(id, true);
    expect(server.requests[5].method, 'PUT');
    expect(server.requests[5].url.path, '/api/octo/computers/$id/mute');
    expect(server.body(5), {'muted': true});
    expect(await backend.notifyPreferences(), {'taskEnded'});
    await backend.setNotifyPreferences({'taskEnded'});
    expect(server.body(7), {
      'off': ['taskEnded'],
    });
  });

  test('errors carry the server message and code; plan errors link to the plan page', () async {
    server.reply = (_) => _json({
      'error': {
        'code': 'plan_required',
        'message': 'Octo tasks need October Pro.',
      },
    }, 403);
    final e = await backend.listComputers().then<BackendException?>(
      (_) => null,
      onError: (Object e) => e as BackendException,
    );
    expect(
      (e!.code, e.message, e.needsPlan),
      ('plan_required', 'Octo tasks need October Pro.', true),
    );

    server.reply = (_) => _json(
      {
        'error': {'code': 'rate_limited', 'message': 'Too many wrong codes.'},
      },
      429,
      {'retry-after': '600'},
    );
    final limited = await backend
        .claim(const ClaimByCode('7K4QMX2D'))
        .then<BackendException?>(
          (_) => null,
          onError: (Object e) => e as BackendException,
        );
    expect(limited!.retryAfter, const Duration(minutes: 10));

    // Not the contract: a plain sentence, never the raw body or status.
    server.reply = (_) => http.Response('<html>Bad gateway</html>', 502);
    final odd = await backend.listComputers().then<BackendException?>(
      (_) => null,
      onError: (Object e) => e as BackendException,
    );
    expect(odd!.code, 'unavailable');
    expect(odd.message, isNot(contains('html')));

    server.reply = (_) => throw http.ClientException('offline');
    await expectLater(
      backend.listComputers(),
      throwsA(
        isA<BackendException>().having((e) => e.code, 'code', 'unavailable'),
      ),
    );

    token = null;
    await expectLater(
      backend.listComputers(),
      throwsA(
        isA<BackendException>().having((e) => e.code, 'code', 'unauthorized'),
      ),
    );
  });

  group('codes', () {
    test('typed codes are forgiving like the backend: case, dashes, O→0, I/L→1, no U', () {
      expect(normaliseTypedCode('7k4q-mx2d'), '7K4QMX2D');
      expect(normaliseTypedCode('O1IL ABCD'), '0111ABCD');
      expect(normaliseTypedCode('UUUUUUUU'), isNull);
      expect(normaliseTypedCode('7K4QMX2'), isNull);
    });

    test('only the backend link format is an enrollment link', () {
      expect(
        parseEnrollmentLink(
          'https://www.october.dev/octo/add#en_${'0' * 24}.${'s' * 43}',
        ),
        isNotNull,
      );
      expect(
        parseEnrollmentLink(
          'https://october.dev/octo/add#en_${'0' * 24}.${'s' * 43}',
        ),
        isNotNull,
      );
      expect(
        parseEnrollmentLink(
          'http://www.october.dev/octo/add#en_${'0' * 24}.${'s' * 43}',
        ),
        isNull,
      );
      expect(
        parseEnrollmentLink(
          'https://evil.dev/octo/add#en_${'0' * 24}.${'s' * 43}',
        ),
        isNull,
      );
      expect(
        parseEnrollmentLink('https://www.october.dev/octo/add#en_x.short'),
        isNull,
      );
      expect(
        parseEnrollmentLink(
          'https://www.october.dev/octo/add?x=1#en_${'0' * 24}.${'s' * 43}',
        ),
        isNull,
      );
    });
  });
}
