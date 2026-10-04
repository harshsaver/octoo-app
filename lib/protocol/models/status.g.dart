// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Job _$JobFromJson(Map<String, dynamic> json) => _Job(
  id: json['id'] as String,
  title: json['title'] as String? ?? '',
  scope: json['scope'] as String?,
  may:
      (json['may'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$JobToJson(_Job instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'scope': ?instance.scope,
  'may': instance.may,
};

_FamilyMember _$FamilyMemberFromJson(Map<String, dynamic> json) =>
    _FamilyMember(
      name: json['name'] as String? ?? '',
      device: json['device'] as String?,
    );

Map<String, dynamic> _$FamilyMemberToJson(_FamilyMember instance) =>
    <String, dynamic>{'name': instance.name, 'device': ?instance.device};

_TodoCounts _$TodoCountsFromJson(Map<String, dynamic> json) =>
    _TodoCounts(open: (json['open'] as num?)?.toInt() ?? 0);

Map<String, dynamic> _$TodoCountsToJson(_TodoCounts instance) =>
    <String, dynamic>{'open': instance.open};

_HelpState _$HelpStateFromJson(Map<String, dynamic> json) => _HelpState(
  since: (json['since'] as num).toInt(),
  text: json['text'] as String?,
);

Map<String, dynamic> _$HelpStateToJson(_HelpState instance) =>
    <String, dynamic>{'since': instance.since, 'text': ?instance.text};

_AgentState _$AgentStateFromJson(Map<String, dynamic> json) =>
    _AgentState(connected: json['connected'] as bool? ?? false);

Map<String, dynamic> _$AgentStateToJson(_AgentState instance) =>
    <String, dynamic>{'connected': instance.connected};

_ComputerStatus _$ComputerStatusFromJson(Map<String, dynamic> json) =>
    _ComputerStatus(
      computer: json['computer'] as String?,
      person: json['person'] as String?,
      language: json['language'] as String?,
      os: json['os'] as String?,
      busy: json['busy'] as bool? ?? false,
      task: json['task'] == null
          ? null
          : Task.fromJson(json['task'] as Map<String, dynamic>),
      queued:
          (json['queued'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Task>[],
      recent:
          (json['recent'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Task>[],
      todos: json['todos'] == null
          ? null
          : TodoCounts.fromJson(json['todos'] as Map<String, dynamic>),
      help: json['help'] == null
          ? null
          : HelpState.fromJson(json['help'] as Map<String, dynamic>),
      policy: json['policy'] == null
          ? null
          : Policy.fromJson(json['policy'] as Map<String, dynamic>),
      family:
          (json['family'] as List<dynamic>?)
              ?.map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <FamilyMember>[],
      jobs:
          (json['jobs'] as List<dynamic>?)
              ?.map((e) => Job.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Job>[],
      agent: json['agent'] == null
          ? null
          : AgentState.fromJson(json['agent'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ComputerStatusToJson(_ComputerStatus instance) =>
    <String, dynamic>{
      'computer': ?instance.computer,
      'person': ?instance.person,
      'language': ?instance.language,
      'os': ?instance.os,
      'busy': instance.busy,
      'task': ?instance.task?.toJson(),
      'queued': instance.queued.map((e) => e.toJson()).toList(),
      'recent': instance.recent.map((e) => e.toJson()).toList(),
      'todos': ?instance.todos?.toJson(),
      'help': ?instance.help?.toJson(),
      'policy': ?instance.policy?.toJson(),
      'family': instance.family.map((e) => e.toJson()).toList(),
      'jobs': instance.jobs.map((e) => e.toJson()).toList(),
      'agent': ?instance.agent?.toJson(),
    };
