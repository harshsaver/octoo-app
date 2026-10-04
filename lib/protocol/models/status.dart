import 'package:freezed_annotation/freezed_annotation.dart';

import 'policy.dart';
import 'task.dart';

part 'status.freezed.dart';
part 'status.g.dart';

/// A curated job her computer offers: `{"id","title","scope","may"}`.
@freezed
abstract class Job with _$Job {
  const Job._();

  const factory Job({
    required String id,
    @Default('') String title,
    String? scope,
    @Default(<String>[]) List<String> may,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);

  TaskScope get scopeKind => TaskScope.fromWire(scope);

  List<ChangeKind> get mayKinds => [
    for (final m in may) ChangeKind.fromWire(m),
  ];
}

/// A helper paired with her computer: `{"name","device"}`.
@freezed
abstract class FamilyMember with _$FamilyMember {
  const factory FamilyMember({@Default('') String name, String? device}) =
      _FamilyMember;

  factory FamilyMember.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberFromJson(json);
}

/// `status.todos`: `{"open": n}`.
@freezed
abstract class TodoCounts with _$TodoCounts {
  const factory TodoCounts({@Default(0) int open}) = _TodoCounts;

  factory TodoCounts.fromJson(Map<String, dynamic> json) =>
      _$TodoCountsFromJson(json);
}

/// `status.help`: present while she's asking for help.
@freezed
abstract class HelpState with _$HelpState {
  const factory HelpState({required int since, String? text}) = _HelpState;

  factory HelpState.fromJson(Map<String, dynamic> json) =>
      _$HelpStateFromJson(json);
}

/// `status.agent`.
@freezed
abstract class AgentState with _$AgentState {
  const factory AgentState({@Default(false) bool connected}) = _AgentState;

  factory AgentState.fromJson(Map<String, dynamic> json) =>
      _$AgentStateFromJson(json);
}

/// The body of a `status` message (brief §7.2), without `type`/`requestId`.
@freezed
abstract class ComputerStatus with _$ComputerStatus {
  const factory ComputerStatus({
    String? computer,
    String? person,
    String? language,
    String? os,
    @Default(false) bool busy,
    Task? task,
    @Default(<Task>[]) List<Task> queued,
    @Default(<Task>[]) List<Task> recent,
    TodoCounts? todos,
    HelpState? help,
    Policy? policy,
    @Default(<FamilyMember>[]) List<FamilyMember> family,
    @Default(<Job>[]) List<Job> jobs,
    AgentState? agent,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(<String, Object?>{})
    Map<String, Object?> raw,
  }) = _ComputerStatus;

  factory ComputerStatus.fromJson(Map<String, dynamic> json) =>
      _$ComputerStatusFromJson(json).copyWith(raw: json);
}
