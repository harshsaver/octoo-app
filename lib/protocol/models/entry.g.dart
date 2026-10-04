// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Entry _$EntryFromJson(Map<String, dynamic> json) => _Entry(
  at: (json['at'] as num).toInt(),
  kind: json['kind'] as String,
  by: json['by'] as String?,
  text: json['text'] as String? ?? '',
  taskId: json['taskId'] as String?,
  job: json['job'] as String?,
  outcome: json['outcome'] as String?,
  screenshot: const ScreenshotConverter().fromJson(
    json['screenshot'] as String?,
  ),
);

Map<String, dynamic> _$EntryToJson(_Entry instance) => <String, dynamic>{
  'at': instance.at,
  'kind': instance.kind,
  'by': ?instance.by,
  'text': instance.text,
  'taskId': ?instance.taskId,
  'job': ?instance.job,
  'outcome': ?instance.outcome,
  'screenshot': ?const ScreenshotConverter().toJson(instance.screenshot),
};
