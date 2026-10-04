import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/protocol/app_message.dart';
import 'package:octo_family/protocol/host_message.dart';
import 'package:octo_family/protocol/models/status.dart';
import 'package:octo_family/protocol/pending.dart';

const _create = TaskCreate(requestId: 'r1', text: 'Check the Wi-Fi');
const _ok = ResultMessage(requestId: 'r1', ok: true, taskId: 't1');

Future<void> _sent() async {}

/// Collects a request's outcome without leaving errors unhandled.
class _Outcome {
  _Outcome(Future<HostReply> future) {
    future.then<void>(
      (v) => value = v,
      onError: (Object e) {
        error = e;
      },
    );
  }

  HostReply? value;
  Object? error;

  RequestFailureKind? get failure => (error as RequestFailure?)?.kind;
}

void main() {
  test('a reply with the request id and expected type completes it', () {
    fakeAsync((async) {
      final m = RequestMatcher();
      final out = _Outcome(m.request(_create, _sent));
      async.flushMicrotasks();
      expect(m.offer(_ok), isTrue);
      async.flushMicrotasks();
      expect(out.value, same(_ok));
      expect(m.outstanding, 0);
    });
  });

  test('typed replies: status, todos and log', () {
    fakeAsync((async) {
      final m = RequestMatcher();
      final status = _Outcome(
        m.request(const StatusRequest(requestId: 'q1'), _sent),
      );
      final todos = _Outcome(
        m.request(const TodosRequest(requestId: 'd1'), _sent),
      );
      final log = _Outcome(m.request(const LogRequest(requestId: 'l1'), _sent));
      async.flushMicrotasks();

      // A reply of another kind with the same id doesn't match.
      expect(m.offer(const TodosMessage(requestId: 'q1', todos: [])), isFalse);
      expect(
        m.offer(const StatusMessage(requestId: 'q1', status: ComputerStatus())),
        isTrue,
      );
      expect(m.offer(const TodosMessage(requestId: 'd1', todos: [])), isTrue);
      expect(m.offer(const LogMessage(requestId: 'l1', entries: [])), isTrue);
      async.flushMicrotasks();
      expect(status.value, isA<StatusMessage>());
      expect(todos.value, isA<TodosMessage>());
      expect(log.value, isA<LogMessage>());
    });
  });

  test('an error result answers any request kind', () {
    fakeAsync((async) {
      final m = RequestMatcher();
      final out = _Outcome(
        m.request(const StatusRequest(requestId: 'q1'), _sent),
      );
      async.flushMicrotasks();
      expect(
        m.offer(
          const ResultMessage(requestId: 'q1', ok: false, error: 'bad_request'),
        ),
        isTrue,
      );
      async.flushMicrotasks();
      expect((out.value! as ResultMessage).ok, isFalse);
    });
  });

  test('the timeout starts when the request is sent, not when queued', () {
    fakeAsync((async) {
      final m = RequestMatcher();
      final sending = Completer<void>();
      final out = _Outcome(m.request(_create, () => sending.future));
      async.elapse(const Duration(seconds: 30));
      expect(out.error, isNull, reason: 'still being sent');
      sending.complete();
      async.elapse(const Duration(seconds: 19));
      expect(out.error, isNull);
      async.elapse(const Duration(seconds: 1));
      expect(out.failure, RequestFailureKind.timeout);
    });
  });

  test('a custom timeout is honoured', () {
    fakeAsync((async) {
      final m = RequestMatcher();
      final out = _Outcome(
        m.request(_create, _sent, timeout: const Duration(minutes: 2)),
      );
      async.elapse(const Duration(seconds: 119));
      expect(out.error, isNull);
      async.elapse(const Duration(seconds: 1));
      expect(out.failure, RequestFailureKind.timeout);
    });
  });

  test('a late result after the timeout is passed on, not swallowed', () {
    fakeAsync((async) {
      final m = RequestMatcher();
      final out = _Outcome(m.request(_create, _sent));
      async.elapse(const Duration(seconds: 21));
      expect(out.failure, RequestFailureKind.timeout);
      expect(m.offer(_ok), isFalse, reason: 'the caller reconciles it');
    });
  });

  test('a reply that arrives while send is still running still matches', () {
    fakeAsync((async) {
      final m = RequestMatcher();
      final sending = Completer<void>();
      final out = _Outcome(m.request(_create, () => sending.future));
      async.flushMicrotasks();
      expect(m.offer(_ok), isTrue);
      sending.complete();
      async.elapse(const Duration(minutes: 1));
      expect(out.value, same(_ok));
      expect(out.error, isNull, reason: 'no timer was started');
    });
  });

  test('disconnect fails every outstanding request; new ones fail at once', () {
    fakeAsync((async) {
      final m = RequestMatcher();
      final a = _Outcome(m.request(_create, _sent));
      final b = _Outcome(
        m.request(const StatusRequest(requestId: 'q1'), _sent),
      );
      async.flushMicrotasks();
      m.close();
      async.flushMicrotasks();
      expect(a.failure, RequestFailureKind.disconnected);
      expect(b.failure, RequestFailureKind.disconnected);
      expect(m.offer(_ok), isFalse, reason: 'late results are passed on');

      final c = _Outcome(
        m.request(const StatusRequest(requestId: 'q2'), _sent),
      );
      async.flushMicrotasks();
      expect(c.failure, RequestFailureKind.disconnected);
      async.elapse(const Duration(minutes: 1));
    });
  });

  test('send throwing fails as sendFailed with the cause', () {
    fakeAsync((async) {
      final m = RequestMatcher();
      final out = _Outcome(
        m.request(_create, () async => throw StateError('socket')),
      );
      async.flushMicrotasks();
      expect(out.failure, RequestFailureKind.sendFailed);
      expect((out.error! as RequestFailure).cause, isA<StateError>());
      expect(m.outstanding, 0);
    });
  });

  test('a malformed reply to an outstanding request fails it fast', () {
    fakeAsync((async) {
      final m = RequestMatcher();
      final out = _Outcome(m.request(_create, _sent));
      async.flushMicrotasks();
      final malformed = parseHostMessage({
        'type': 'result',
        'requestId': 'r1',
        'ok': 'yes',
      });
      expect(malformed, isA<UnknownHostMessage>());
      expect(m.offer(malformed), isTrue);
      async.flushMicrotasks();
      expect(out.failure, RequestFailureKind.malformedReply);
    });
  });

  test('messages without a matching request are left for the caller', () {
    final m = RequestMatcher();
    expect(m.offer(const RemovedMessage()), isFalse);
    expect(m.offer(const StatusMessage(status: ComputerStatus())), isFalse);
    expect(
      m.offer(parseHostMessage({'type': 'mystery', 'requestId': 'r1'})),
      isFalse,
    );
  });

  test('a duplicate request id is a programming error', () {
    fakeAsync((async) {
      final m = RequestMatcher();
      _Outcome(m.request(_create, _sent));
      expect(() => m.request(_create, _sent), throwsStateError);
      m.close();
      async.flushMicrotasks();
    });
  });
}
