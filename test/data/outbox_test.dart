import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/data/outbox.dart';
import 'package:octo_family/protocol/app_message.dart';
import 'package:octo_family/protocol/host_message.dart';
import 'package:octo_family/protocol/pending.dart';
import 'package:octo_family/transport/octo_link.dart';

OutboxRow _row(
  OutboxKind kind,
  Map<String, Object?> payload, [
  OutboxState state = OutboxState.pending,
]) => OutboxRow(
  id: 'o1',
  computerId: 'c1',
  kind: kind,
  payload: payload,
  state: state,
  createdAt: 1,
  updatedAt: 1,
);

void main() {
  test('every kind sends a message the protocol understands', () {
    final rows = {
      OutboxKind.task: _row(OutboxKind.task, {
        'text': 'Install Zoom',
        'job': 'app.install',
      }),
      OutboxKind.message: _row(OutboxKind.message, {'text': 'Hi'}),
      OutboxKind.todoReply: _row(OutboxKind.todoReply, {
        'todoId': 'd1',
        'text': 'Close it',
      }),
      OutboxKind.todoDone: _row(OutboxKind.todoDone, {'todoId': 'd1'}),
      OutboxKind.screenRequest: _row(OutboxKind.screenRequest, {}),
      OutboxKind.leave: _row(OutboxKind.leave, {}),
    };
    expect(rows.keys.toSet(), OutboxKind.values.toSet());
    for (final MapEntry(:key, :value) in rows.entries) {
      final attempted = OutboxTransitions.attempt(
        value,
        requestId: 'r1',
        at: 2,
      );
      final parsed = AppMessage.parse(attempted.wireMessage);
      expect(parsed, isNot(isA<UnknownAppMessage>()), reason: key.name);
      if (key.waitsForResult) {
        expect((parsed as AppRequest).requestId, 'r1');
      }
    }
    expect(
      outboxPayload(
        const TaskCreate(requestId: 'x', text: 'Hi', job: 'wifi.check'),
      ),
      {'text': 'Hi', 'job': 'wifi.check'},
    );
  });

  test('attempting carries the requestId; fire-and-forget rows carry none', () {
    final task = OutboxTransitions.attempt(
      _row(OutboxKind.task, {'text': 'x'}),
      requestId: 'r1',
      at: 2,
    );
    expect(task.state, OutboxState.attempting);
    expect(task.wireMessage['requestId'], 'r1');
    final msg = OutboxTransitions.attempt(
      _row(OutboxKind.message, {'text': 'x'}),
      requestId: 'r1',
      at: 2,
    );
    expect(msg.wireMessage.containsKey('requestId'), isFalse);
  });

  test('results settle a row in any state, on time or late', () {
    final row = _row(OutboxKind.task, {'text': 'x'}, OutboxState.uncertain);
    final ok = OutboxTransitions.result(
      row,
      const ResultMessage(requestId: 'r', ok: true, taskId: 't1'),
      at: 3,
    );
    expect((ok.state, ok.taskId), (OutboxState.accepted, 't1'));
    final no = OutboxTransitions.result(
      row,
      const ResultMessage(
        requestId: 'r',
        ok: false,
        error: 'busy',
        message: 'Octo already has 10 things waiting.',
      ),
      at: 3,
    );
    expect(
      (no.state, no.error, no.errorMessage),
      (OutboxState.rejected, 'busy', 'Octo already has 10 things waiting.'),
    );
  });

  test(
    'failures: not sent goes back to pending; anything ambiguous is uncertain',
    () {
      final row = _row(OutboxKind.task, {'text': 'x'}, OutboxState.attempting);
      OutboxState after(RequestFailure f) =>
          OutboxTransitions.requestFailed(row, f, at: 3).state;
      expect(
        after(
          const RequestFailure(
            RequestFailureKind.sendFailed,
            'r',
            LinkUnavailableException('c1'),
          ),
        ),
        OutboxState.pending,
      );
      expect(
        after(
          RequestFailure(
            RequestFailureKind.sendFailed,
            'r',
            StateError('socket'),
          ),
        ),
        OutboxState.uncertain,
      );
      expect(
        after(const RequestFailure(RequestFailureKind.timeout, 'r')),
        OutboxState.uncertain,
      );
      expect(
        after(const RequestFailure(RequestFailureKind.disconnected, 'r')),
        OutboxState.uncertain,
      );

      final msg = _row(OutboxKind.message, {
        'text': 'x',
      }, OutboxState.attempting);
      expect(
        OutboxTransitions.sendFinished(msg, null, at: 3).state,
        OutboxState.sent,
      );
      expect(
        OutboxTransitions.sendFinished(
          msg,
          const LinkUnavailableException('c1'),
          at: 3,
        ).state,
        OutboxState.pending,
      );
      expect(
        OutboxTransitions.sendFinished(msg, StateError('x'), at: 3).state,
        OutboxState.uncertain,
      );
    },
  );

  test('after a crash, attempting becomes uncertain; nothing else changes', () {
    for (final state in OutboxState.values) {
      final recovered = OutboxTransitions.recover(
        _row(OutboxKind.task, {'text': 'x'}, state),
        at: 9,
      );
      expect(
        recovered.state,
        state == OutboxState.attempting ? OutboxState.uncertain : state,
      );
    }
  });
}
