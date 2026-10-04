import 'package:freezed_annotation/freezed_annotation.dart';

import 'screenshot.dart';

part 'todo.freezed.dart';
part 'todo.g.dart';

/// Where she was when she asked: `{"app","window","url"}`.
@freezed
abstract class TodoContext with _$TodoContext {
  const factory TodoContext({String? app, String? window, String? url}) =
      _TodoContext;

  factory TodoContext.fromJson(Map<String, dynamic> json) =>
      _$TodoContextFromJson(json);
}

/// A reply on a to-do: `{"at","from","text"}`.
@freezed
abstract class Reply with _$Reply {
  const factory Reply({
    required int at,
    String? from,
    @Default('') String text,
  }) = _Reply;

  factory Reply.fromJson(Map<String, dynamic> json) => _$ReplyFromJson(json);
}

/// Something Mom sent to her helpers ("Send to Harsh"), brief §7.2.
@freezed
abstract class Todo with _$Todo {
  const factory Todo({
    required String id,
    required int at,
    @Default('') String text,
    String? answer,
    @ScreenshotConverter() WireScreenshot? screenshot,
    TodoContext? context,
    @Default(false) bool done,
    @Default(<Reply>[]) List<Reply> replies,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(<String, Object?>{})
    Map<String, Object?> raw,
  }) = _Todo;

  factory Todo.fromJson(Map<String, dynamic> json) =>
      _$TodoFromJson(json).copyWith(raw: json);
}
