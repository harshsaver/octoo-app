import '../protocol/app_message.dart';
import '../protocol/host_message.dart';
import '../protocol/pending.dart';
import '../transport/octo_link.dart';

/// What an outbox row sends.
enum OutboxKind {
  /// `task.create` (Ask Octo). Waits for a `result`.
  task('task.create'),

  /// `message` (Tell Mom).
  message('message'),
  todoReply('todo.reply'),
  todoDone('todo.done'),
  screenRequest('screen.request'),
  leave('leave');

  const OutboxKind(this.wire);

  final String wire;

  static OutboxKind? fromWire(String value) {
    for (final k in values) {
      if (k.wire == value) return k;
    }
    return null;
  }

  bool get waitsForResult => this == task;
}

/// The delivery state of one row (PLAN §3.5). The app never claims
/// "delivered": the best a fire-and-forget message gets is [sent].
enum OutboxState {
  /// Waiting to go out (offline, or behind another row).
  pending,

  /// Written with its requestId and exact payload, then handed to the link.
  /// A row still here after a restart becomes [uncertain].
  attempting,

  /// Her computer accepted the task (`result ok:true`).
  accepted,

  /// Her computer refused it (`result ok:false`); [OutboxRow.errorMessage]
  /// says why.
  rejected,

  /// It may or may not have reached her computer.
  uncertain,

  /// A fire-and-forget message left the phone.
  sent;

  bool get isFinal => this == accepted || this == rejected || this == sent;
}

/// One thing typed on this phone for one computer: a task, a message to
/// her, a to-do reply, a screen request. Bound to the pairing ([bind]) it
/// was written under; a re-paired computer drops older rows.
class OutboxRow {
  const OutboxRow({
    required this.id,
    required this.computerId,
    required this.kind,
    required this.payload,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.bind,
    this.requestId,
    this.taskId,
    this.error,
    this.errorMessage,
    this.retryOf,
  });

  /// Local UUID; also the bubble's id.
  final String id;
  final String computerId;
  final String? bind;
  final OutboxKind kind;

  /// The message without `requestId` (added when attempted).
  final Map<String, Object?> payload;
  final OutboxState state;
  final String? requestId;
  final String? taskId;
  final String? error;
  final String? errorMessage;

  /// The row this one retries ("Try again" may run the task twice).
  final String? retryOf;
  final int createdAt;
  final int updatedAt;

  String? get text =>
      payload['text'] is String ? payload['text']! as String : null;
  String? get todoId =>
      payload['todoId'] is String ? payload['todoId']! as String : null;
  String? get job =>
      payload['job'] is String ? payload['job']! as String : null;

  /// The exact message sent for this row.
  Map<String, Object?> get wireMessage => {
    'type': kind.wire,
    ...payload,
    'requestId': ?requestId,
  };

  OutboxRow copyWith({
    OutboxState? state,
    String? requestId,
    String? taskId,
    String? error,
    String? errorMessage,
    required int at,
  }) => OutboxRow(
    id: id,
    computerId: computerId,
    bind: bind,
    kind: kind,
    payload: payload,
    state: state ?? this.state,
    requestId: requestId ?? this.requestId,
    taskId: taskId ?? this.taskId,
    error: error ?? this.error,
    errorMessage: errorMessage ?? this.errorMessage,
    retryOf: retryOf,
    createdAt: createdAt,
    updatedAt: at,
  );
}

/// Pure transitions of the outbox state machine.
abstract final class OutboxTransitions {
  /// pending → attempting, with the requestId it will be sent under.
  static OutboxRow attempt(
    OutboxRow row, {
    String? requestId,
    required int at,
  }) {
    assert(row.state == OutboxState.pending, 'only pending rows are attempted');
    return row.copyWith(
      state: OutboxState.attempting,
      requestId: row.kind.waitsForResult ? requestId : null,
      at: at,
    );
  }

  /// The correlated reply to a task, on time or late, in any state.
  static OutboxRow result(
    OutboxRow row,
    ResultMessage result, {
    required int at,
  }) => result.ok
      ? row.copyWith(state: OutboxState.accepted, taskId: result.taskId, at: at)
      : row.copyWith(
          state: OutboxState.rejected,
          error: result.error ?? '',
          errorMessage: result.message,
          at: at,
        );

  /// A request that failed without a reply.
  static OutboxRow requestFailed(
    OutboxRow row,
    RequestFailure failure, {
    required int at,
  }) {
    if (failure.kind == RequestFailureKind.sendFailed &&
        failure.cause is LinkUnavailableException) {
      // Definitely not sent: try again on the next connection.
      return row.copyWith(state: OutboxState.pending, at: at);
    }
    return row.copyWith(state: OutboxState.uncertain, at: at);
  }

  /// A fire-and-forget send finished ([error] null) or threw.
  static OutboxRow sendFinished(
    OutboxRow row,
    Object? error, {
    required int at,
  }) {
    if (error == null) return row.copyWith(state: OutboxState.sent, at: at);
    if (error is LinkUnavailableException) {
      return row.copyWith(state: OutboxState.pending, at: at);
    }
    return row.copyWith(state: OutboxState.uncertain, at: at);
  }

  /// At startup: anything caught mid-send can't be confirmed.
  static OutboxRow recover(OutboxRow row, {required int at}) =>
      row.state == OutboxState.attempting
      ? row.copyWith(state: OutboxState.uncertain, at: at)
      : row;
}

/// Builds the payload for a new row. Text is trimmed and limited by the
/// composer; this only shapes the message.
Map<String, Object?> outboxPayload(AppMessage message) {
  final json = Map<String, Object?>.of(message.toJson())
    ..remove('type')
    ..remove('requestId');
  return json;
}
