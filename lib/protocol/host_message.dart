import 'models/entry.dart';
import 'models/policy.dart';
import 'models/screenshot.dart';
import 'models/status.dart';
import 'models/task.dart';
import 'models/todo.dart';
import 'wire.dart';

/// A message from her computer (brief §7.2 "Her computer → app").
///
/// Parse with [parseHostMessage]; it never throws. Every subclass can write
/// itself back with [toWire], which the simulator uses to play her computer.
sealed class HostMessage {
  const HostMessage();

  String get type;

  Map<String, Object?> toWire();
}

/// A message that answers a request by its `requestId`.
sealed class HostReply extends HostMessage {
  const HostReply();

  String? get requestId;
}

final class PairCodeMessage extends HostMessage {
  const PairCodeMessage({required this.code, this.computer});

  final String code;
  final String? computer;

  @override
  String get type => 'pair.code';

  @override
  Map<String, Object?> toWire() => {
    'type': type,
    'code': code,
    'computer': ?computer,
  };
}

final class PairDoneMessage extends HostMessage {
  const PairDoneMessage({required this.hostId, this.computer, this.person});

  final String hostId;
  final String? computer;
  final String? person;

  @override
  String get type => 'pair.done';

  @override
  Map<String, Object?> toWire() => {
    'type': type,
    'hostId': hostId,
    'computer': ?computer,
    'person': ?person,
  };
}

final class PairFailedMessage extends HostMessage {
  const PairFailedMessage({required this.reason, required this.isFinal});

  final String reason;
  final bool isFinal;

  @override
  String get type => 'pair.failed';

  @override
  Map<String, Object?> toWire() => {
    'type': type,
    'reason': reason,
    'final': isFinal,
  };
}

/// The `result.error` codes from the brief. Unknown codes keep their string
/// on [ResultMessage.error] and map to [unknown].
enum ResultError {
  badRequest('bad_request'),
  unknownJob('unknown_job'),
  busy('busy'),
  notFound('not_found'),
  failed('failed'),
  unknown('');

  const ResultError(this.wire);

  final String wire;

  static ResultError fromWire(String value) {
    for (final e in values) {
      if (e != unknown && e.wire == value) return e;
    }
    return unknown;
  }
}

final class ResultMessage extends HostReply {
  const ResultMessage({
    required this.requestId,
    required this.ok,
    this.taskId,
    this.error,
    this.message,
  });

  @override
  final String requestId;
  final bool ok;
  final String? taskId;
  final String? error;
  final String? message;

  ResultError? get errorCode =>
      error == null ? null : ResultError.fromWire(error!);

  @override
  String get type => 'result';

  @override
  Map<String, Object?> toWire() => {
    'type': type,
    'requestId': requestId,
    'ok': ok,
    'taskId': ?taskId,
    'error': ?error,
    'message': ?message,
  };
}

final class TaskMessage extends HostMessage {
  const TaskMessage(this.task);

  final Task task;

  @override
  String get type => 'task';

  @override
  Map<String, Object?> toWire() => {'type': type, 'task': task.toJson()};
}

final class StatusMessage extends HostReply {
  const StatusMessage({this.requestId, required this.status});

  @override
  final String? requestId;
  final ComputerStatus status;

  @override
  String get type => 'status';

  @override
  Map<String, Object?> toWire() => {
    ...status.toJson(),
    'type': type,
    'requestId': ?requestId,
  };
}

final class TodoMessage extends HostMessage {
  const TodoMessage(this.todo);

  final Todo todo;

  @override
  String get type => 'todo';

  @override
  Map<String, Object?> toWire() => {'type': type, 'todo': todo.toJson()};
}

final class TodosMessage extends HostReply {
  const TodosMessage({this.requestId, required this.todos});

  @override
  final String? requestId;
  final List<Todo> todos;

  @override
  String get type => 'todos';

  @override
  Map<String, Object?> toWire() => {
    'type': type,
    'requestId': ?requestId,
    'todos': [for (final t in todos) t.toJson()],
  };
}

final class LogMessage extends HostReply {
  const LogMessage({this.requestId, required this.entries});

  @override
  final String? requestId;
  final List<Entry> entries;

  @override
  String get type => 'log';

  @override
  Map<String, Object?> toWire() => {
    'type': type,
    'requestId': ?requestId,
    'entries': [for (final e in entries) e.toJson()],
  };
}

final class HelpMessage extends HostMessage {
  const HelpMessage({required this.at, this.text});

  final int at;
  final String? text;

  @override
  String get type => 'help';

  @override
  Map<String, Object?> toWire() => {'type': type, 'at': at, 'text': ?text};
}

final class ScreenMessage extends HostMessage {
  const ScreenMessage({
    required this.ok,
    this.at,
    this.screenshot,
    this.app,
    this.window,
    this.reason,
  });

  final bool ok;
  final int? at;
  final WireScreenshot? screenshot;
  final String? app;
  final String? window;
  final String? reason;

  @override
  String get type => 'screen';

  @override
  Map<String, Object?> toWire() => {
    'type': type,
    'ok': ok,
    'at': ?at,
    'screenshot': ?screenshot?.toWire(),
    'app': ?app,
    'window': ?window,
    'reason': ?reason,
  };
}

final class PolicyMessage extends HostMessage {
  const PolicyMessage({required this.policy, this.declined = false});

  final Policy policy;
  final bool declined;

  @override
  String get type => 'policy';

  @override
  Map<String, Object?> toWire() => {
    'type': type,
    'policy': policy.toWire(),
    if (declined) 'declined': true,
  };
}

final class RemovedMessage extends HostMessage {
  const RemovedMessage();

  @override
  String get type => 'removed';

  @override
  Map<String, Object?> toWire() => {'type': type};
}

enum UnknownReason { unknownType, malformed }

/// A message this app can't use: an unknown `type`, or a known type whose
/// fields don't parse. It is ignored (and logged without content); [raw] is
/// kept so a matcher can still fail the request it answers.
final class UnknownHostMessage extends HostMessage {
  const UnknownHostMessage(this.raw, this.reason);

  final Map<String, Object?> raw;
  final UnknownReason reason;

  @override
  String get type => raw['type'] is String ? raw['type']! as String : '';

  String? get requestId =>
      raw['requestId'] is String ? raw['requestId']! as String : null;

  @override
  Map<String, Object?> toWire() => raw;
}

/// Parses one message from her computer. Never throws: unknown or malformed
/// messages become [UnknownHostMessage].
HostMessage parseHostMessage(Map<String, Object?> raw) {
  final type = raw['type'];
  if (type is! String) {
    return UnknownHostMessage(raw, UnknownReason.unknownType);
  }
  final parse = _parsers[type];
  if (parse == null) return UnknownHostMessage(raw, UnknownReason.unknownType);
  try {
    return parse(raw);
  } on FormatException {
    return UnknownHostMessage(raw, UnknownReason.malformed);
  } on TypeError {
    // Generated fromJson casts throw TypeError on a wrong field type.
    return UnknownHostMessage(raw, UnknownReason.malformed);
  } on ArgumentError {
    return UnknownHostMessage(raw, UnknownReason.malformed);
  }
}

/// The message types this app understands.
Set<String> get knownHostMessageTypes => _parsers.keys.toSet();

final Map<String, HostMessage Function(WireMap)> _parsers = {
  'pair.code': (m) => PairCodeMessage(
    code: readString(m, 'code'),
    computer: readOptString(m, 'computer'),
  ),
  'pair.done': (m) => PairDoneMessage(
    hostId: readString(m, 'hostId'),
    computer: readOptString(m, 'computer'),
    person: readOptString(m, 'person'),
  ),
  'pair.failed': (m) => PairFailedMessage(
    reason: readOptString(m, 'reason') ?? '',
    isFinal: readOptBool(m, 'final') ?? true,
  ),
  'result': (m) => ResultMessage(
    requestId: readString(m, 'requestId'),
    ok: readBool(m, 'ok'),
    taskId: readOptString(m, 'taskId'),
    error: readOptString(m, 'error'),
    message: readOptString(m, 'message'),
  ),
  'task': (m) => TaskMessage(Task.fromJson(readMap(m, 'task'))),
  'status': (m) => StatusMessage(
    requestId: readOptString(m, 'requestId'),
    status: ComputerStatus.fromJson(m),
  ),
  'todo': (m) => TodoMessage(Todo.fromJson(readMap(m, 'todo'))),
  'todos': (m) => TodosMessage(
    requestId: readOptString(m, 'requestId'),
    todos: [for (final t in readMapList(m, 'todos')) Todo.fromJson(t)],
  ),
  'log': (m) => LogMessage(
    requestId: readOptString(m, 'requestId'),
    entries: [for (final e in readMapList(m, 'entries')) Entry.fromJson(e)],
  ),
  'help': (m) => HelpMessage(
    at: readOptInt(m, 'at') ?? (throw const FormatException('at')),
    text: readOptString(m, 'text'),
  ),
  'screen': (m) => ScreenMessage(
    ok: readBool(m, 'ok'),
    at: readOptInt(m, 'at'),
    screenshot: WireScreenshot.fromWire(readOptString(m, 'screenshot')),
    app: readOptString(m, 'app'),
    window: readOptString(m, 'window'),
    reason: readOptString(m, 'reason'),
  ),
  'policy': (m) => PolicyMessage(
    policy: Policy.fromJson(readMap(m, 'policy')),
    declined: readOptBool(m, 'declined') ?? false,
  ),
  'removed': (m) => const RemovedMessage(),
};
