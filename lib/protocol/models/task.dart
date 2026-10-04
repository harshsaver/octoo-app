import 'package:freezed_annotation/freezed_annotation.dart';

import 'screenshot.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// The known values of `Task.status`. The wire string is kept on [Task];
/// anything this app doesn't know maps to [unknown], which never reads as
/// done or failed.
enum TaskPhase {
  queued,
  waitingOk,
  running,
  done,
  gaveUp,
  blocked,
  refused,
  declined,
  noAnswer,
  stopped,
  failed,
  unknown;

  static TaskPhase fromWire(String value) {
    for (final p in values) {
      if (p != unknown && p.name == value) return p;
    }
    return unknown;
  }

  /// Still in progress on her computer.
  bool get isActive => this == queued || this == waitingOk || this == running;

  /// One of the known end statuses. [unknown] is neither active nor ended.
  bool get isEnded => !isActive && this != unknown;
}

/// The known values of `Task.may` and `Policy.never`.
enum ChangeKind {
  open,
  install,
  signIn,
  send,
  delete,
  settings,
  call,
  other,
  unknown;

  static ChangeKind fromWire(String value) {
    for (final k in values) {
      if (k != unknown && k.name == value) return k;
    }
    return unknown;
  }
}

/// The known values of `Task.scope` and `Job.scope`.
enum TaskScope {
  look,
  change,
  unknown;

  static TaskScope fromWire(String? value) => switch (value) {
    'look' => look,
    'change' => change,
    _ => unknown,
  };
}

/// One step of a running task: `{"n","at","say","did","ok","error"}`.
@freezed
abstract class TaskStep with _$TaskStep {
  const factory TaskStep({
    required int n,
    int? at,
    String? say,
    String? did,
    bool? ok,
    String? error,
  }) = _TaskStep;

  factory TaskStep.fromJson(Map<String, dynamic> json) =>
      _$TaskStepFromJson(json);
}

/// A task on her computer (brief §7.2). Open-ended values ([status], [may],
/// [scope]) stay as their wire strings; [raw] is the message as received.
@freezed
abstract class Task with _$Task {
  const Task._();

  const factory Task({
    required String id,
    String? from,
    String? fromName,
    @Default('') String text,
    String? job,
    String? scope,
    @Default(<String>[]) List<String> may,
    @Default('') String status,
    String? say,
    @Default(<TaskStep>[]) List<TaskStep> steps,
    String? result,
    String? resultForHer,
    @ScreenshotConverter() WireScreenshot? screenshot,
    int? createdAt,
    int? startedAt,
    int? endedAt,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(<String, Object?>{})
    Map<String, Object?> raw,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) =>
      _$TaskFromJson(json).copyWith(raw: json);

  TaskPhase get phase => TaskPhase.fromWire(status);

  TaskScope get scopeKind => TaskScope.fromWire(scope);

  List<ChangeKind> get mayKinds => [
    for (final m in may) ChangeKind.fromWire(m),
  ];
}
