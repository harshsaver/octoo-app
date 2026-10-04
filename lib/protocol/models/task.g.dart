// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskStep _$TaskStepFromJson(Map<String, dynamic> json) => _TaskStep(
  n: (json['n'] as num).toInt(),
  at: (json['at'] as num?)?.toInt(),
  say: json['say'] as String?,
  did: json['did'] as String?,
  ok: json['ok'] as bool?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$TaskStepToJson(_TaskStep instance) => <String, dynamic>{
  'n': instance.n,
  'at': ?instance.at,
  'say': ?instance.say,
  'did': ?instance.did,
  'ok': ?instance.ok,
  'error': ?instance.error,
};

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  from: json['from'] as String?,
  fromName: json['fromName'] as String?,
  text: json['text'] as String? ?? '',
  job: json['job'] as String?,
  scope: json['scope'] as String?,
  may:
      (json['may'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  status: json['status'] as String? ?? '',
  say: json['say'] as String?,
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => TaskStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <TaskStep>[],
  result: json['result'] as String?,
  resultForHer: json['resultForHer'] as String?,
  screenshot: const ScreenshotConverter().fromJson(
    json['screenshot'] as String?,
  ),
  createdAt: (json['createdAt'] as num?)?.toInt(),
  startedAt: (json['startedAt'] as num?)?.toInt(),
  endedAt: (json['endedAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'from': ?instance.from,
  'fromName': ?instance.fromName,
  'text': instance.text,
  'job': ?instance.job,
  'scope': ?instance.scope,
  'may': instance.may,
  'status': instance.status,
  'say': ?instance.say,
  'steps': instance.steps.map((e) => e.toJson()).toList(),
  'result': ?instance.result,
  'resultForHer': ?instance.resultForHer,
  'screenshot': ?const ScreenshotConverter().toJson(instance.screenshot),
  'createdAt': ?instance.createdAt,
  'startedAt': ?instance.startedAt,
  'endedAt': ?instance.endedAt,
};
