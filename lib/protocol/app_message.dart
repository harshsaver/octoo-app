import 'models/policy.dart';
import 'wire.dart';

/// Longest task or message text her computer accepts.
const int maxMessageTextLength = 2000;

/// What kind of reply a request waits for (see `pending.dart`).
enum ReplyKind {
  result('result'),
  status('status'),
  todos('todos'),
  log('log');

  const ReplyKind(this.type);

  final String type;
}

/// A message from this app to her computer (brief §7.2 "App → her computer").
sealed class AppMessage {
  const AppMessage();

  String get type;

  Map<String, Object?> toJson();

  /// Parses an app message. Used by the simulator, which plays her computer.
  /// Unknown or malformed messages become [UnknownAppMessage]; never throws.
  static AppMessage parse(Map<String, Object?> raw) {
    final type = raw['type'];
    final parse = type is String ? _parsers[type] : null;
    if (parse == null) return UnknownAppMessage(raw);
    try {
      return parse(raw);
    } on FormatException {
      return UnknownAppMessage(raw);
    } on TypeError {
      return UnknownAppMessage(raw);
    }
  }
}

/// A message that carries a `requestId` and waits for a reply.
sealed class AppRequest extends AppMessage {
  const AppRequest();

  String get requestId;

  ReplyKind get expects;
}

final class PairRequest extends AppMessage {
  const PairRequest({
    required this.token,
    required this.name,
    required this.device,
  });

  final String token;
  final String name;
  final String device;

  @override
  String get type => 'pair.request';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'token': token,
    'name': name,
    'device': device,
  };
}

final class PairConfirm extends AppMessage {
  const PairConfirm({required this.code});

  final String code;

  @override
  String get type => 'pair.confirm';

  @override
  Map<String, Object?> toJson() => {'type': type, 'code': code};
}

final class StatusRequest extends AppRequest {
  const StatusRequest({required this.requestId});

  @override
  final String requestId;

  @override
  ReplyKind get expects => ReplyKind.status;

  @override
  String get type => 'status';

  @override
  Map<String, Object?> toJson() => {'type': type, 'requestId': requestId};
}

final class TaskCreate extends AppRequest {
  const TaskCreate({required this.requestId, required this.text, this.job});

  @override
  final String requestId;
  final String text;

  /// A curated job id; without it her computer picks one from the words.
  final String? job;

  @override
  ReplyKind get expects => ReplyKind.result;

  @override
  String get type => 'task.create';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'requestId': requestId,
    'text': text,
    'job': ?job,
  };
}

final class TaskStop extends AppRequest {
  const TaskStop({required this.requestId, required this.taskId});

  @override
  final String requestId;
  final String taskId;

  @override
  ReplyKind get expects => ReplyKind.result;

  @override
  String get type => 'task.stop';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'requestId': requestId,
    'taskId': taskId,
  };
}

final class PolicySet extends AppRequest {
  const PolicySet({required this.requestId, required this.policy});

  @override
  final String requestId;
  final Policy policy;

  @override
  ReplyKind get expects => ReplyKind.result;

  @override
  String get type => 'policy.set';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'requestId': requestId,
    'policy': policy.toWire(),
  };
}

final class ProfileSet extends AppRequest {
  const ProfileSet({
    required this.requestId,
    this.person,
    this.computer,
    this.language,
  });

  @override
  final String requestId;
  final String? person;
  final String? computer;
  final String? language;

  @override
  ReplyKind get expects => ReplyKind.result;

  @override
  String get type => 'profile.set';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'requestId': requestId,
    'person': ?person,
    'computer': ?computer,
    'language': ?language,
  };
}

final class TodosRequest extends AppRequest {
  const TodosRequest({required this.requestId});

  @override
  final String requestId;

  @override
  ReplyKind get expects => ReplyKind.todos;

  @override
  String get type => 'todos';

  @override
  Map<String, Object?> toJson() => {'type': type, 'requestId': requestId};
}

final class TodoReply extends AppMessage {
  const TodoReply({required this.todoId, required this.text});

  final String todoId;
  final String text;

  @override
  String get type => 'todo.reply';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'todoId': todoId,
    'text': text,
  };
}

final class TodoDone extends AppMessage {
  const TodoDone({required this.todoId});

  final String todoId;

  @override
  String get type => 'todo.done';

  @override
  Map<String, Object?> toJson() => {'type': type, 'todoId': todoId};
}

final class LogRequest extends AppRequest {
  const LogRequest({required this.requestId, this.since, this.limit});

  @override
  final String requestId;
  final int? since;
  final int? limit;

  @override
  ReplyKind get expects => ReplyKind.log;

  @override
  String get type => 'log';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'requestId': requestId,
    'since': ?since,
    'limit': ?limit,
  };
}

/// A message to her (shown on her screen). Wire type `message`.
final class ChatMessage extends AppMessage {
  const ChatMessage({required this.text});

  final String text;

  @override
  String get type => 'message';

  @override
  Map<String, Object?> toJson() => {'type': type, 'text': text};
}

final class ScreenRequest extends AppMessage {
  const ScreenRequest();

  @override
  String get type => 'screen.request';

  @override
  Map<String, Object?> toJson() => {'type': type};
}

final class Leave extends AppMessage {
  const Leave();

  @override
  String get type => 'leave';

  @override
  Map<String, Object?> toJson() => {'type': type};
}

/// An app message the simulator doesn't understand.
final class UnknownAppMessage extends AppMessage {
  const UnknownAppMessage(this.raw);

  final Map<String, Object?> raw;

  @override
  String get type => raw['type'] is String ? raw['type']! as String : '';

  @override
  Map<String, Object?> toJson() => raw;
}

final Map<String, AppMessage Function(WireMap)> _parsers = {
  'pair.request': (m) => PairRequest(
    token: readString(m, 'token'),
    name: readString(m, 'name'),
    device: readString(m, 'device'),
  ),
  'pair.confirm': (m) => PairConfirm(code: readString(m, 'code')),
  'status': (m) => StatusRequest(requestId: readString(m, 'requestId')),
  'task.create': (m) => TaskCreate(
    requestId: readString(m, 'requestId'),
    text: readString(m, 'text'),
    job: readOptString(m, 'job'),
  ),
  'task.stop': (m) => TaskStop(
    requestId: readString(m, 'requestId'),
    taskId: readString(m, 'taskId'),
  ),
  'policy.set': (m) => PolicySet(
    requestId: readString(m, 'requestId'),
    policy: Policy.fromJson(readMap(m, 'policy')),
  ),
  'profile.set': (m) => ProfileSet(
    requestId: readString(m, 'requestId'),
    person: readOptString(m, 'person'),
    computer: readOptString(m, 'computer'),
    language: readOptString(m, 'language'),
  ),
  'todos': (m) => TodosRequest(requestId: readString(m, 'requestId')),
  'todo.reply': (m) =>
      TodoReply(todoId: readString(m, 'todoId'), text: readString(m, 'text')),
  'todo.done': (m) => TodoDone(todoId: readString(m, 'todoId')),
  'log': (m) => LogRequest(
    requestId: readString(m, 'requestId'),
    since: readOptInt(m, 'since'),
    limit: readOptInt(m, 'limit'),
  ),
  'message': (m) => ChatMessage(text: readString(m, 'text')),
  'screen.request': (m) => const ScreenRequest(),
  'leave': (m) => const Leave(),
};
