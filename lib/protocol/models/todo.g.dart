// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TodoContext _$TodoContextFromJson(Map<String, dynamic> json) => _TodoContext(
  app: json['app'] as String?,
  window: json['window'] as String?,
  url: json['url'] as String?,
);

Map<String, dynamic> _$TodoContextToJson(_TodoContext instance) =>
    <String, dynamic>{
      'app': ?instance.app,
      'window': ?instance.window,
      'url': ?instance.url,
    };

_Reply _$ReplyFromJson(Map<String, dynamic> json) => _Reply(
  at: (json['at'] as num).toInt(),
  from: json['from'] as String?,
  text: json['text'] as String? ?? '',
);

Map<String, dynamic> _$ReplyToJson(_Reply instance) => <String, dynamic>{
  'at': instance.at,
  'from': ?instance.from,
  'text': instance.text,
};

_Todo _$TodoFromJson(Map<String, dynamic> json) => _Todo(
  id: json['id'] as String,
  at: (json['at'] as num).toInt(),
  text: json['text'] as String? ?? '',
  answer: json['answer'] as String?,
  screenshot: const ScreenshotConverter().fromJson(
    json['screenshot'] as String?,
  ),
  context: json['context'] == null
      ? null
      : TodoContext.fromJson(json['context'] as Map<String, dynamic>),
  done: json['done'] as bool? ?? false,
  replies:
      (json['replies'] as List<dynamic>?)
          ?.map((e) => Reply.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Reply>[],
);

Map<String, dynamic> _$TodoToJson(_Todo instance) => <String, dynamic>{
  'id': instance.id,
  'at': instance.at,
  'text': instance.text,
  'answer': ?instance.answer,
  'screenshot': ?const ScreenshotConverter().toJson(instance.screenshot),
  'context': ?instance.context?.toJson(),
  'done': instance.done,
  'replies': instance.replies.map((e) => e.toJson()).toList(),
};
