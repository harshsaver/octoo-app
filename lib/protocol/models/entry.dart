import 'package:freezed_annotation/freezed_annotation.dart';

import 'screenshot.dart';

part 'entry.freezed.dart';
part 'entry.g.dart';

/// The known values of `Entry.kind`.
enum EntryKind {
  task,
  step,
  consent,
  limit,
  todo,
  pairing,
  policy,
  screen,
  help,
  message,
  unknown;

  static EntryKind fromWire(String value) {
    for (final k in values) {
      if (k != unknown && k.name == value) return k;
    }
    return unknown;
  }
}

/// One line of the activity log (brief §7.2).
@freezed
abstract class Entry with _$Entry {
  const Entry._();

  const factory Entry({
    required int at,
    required String kind,
    String? by,
    @Default('') String text,
    String? taskId,
    String? job,
    String? outcome,
    @ScreenshotConverter() WireScreenshot? screenshot,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(<String, Object?>{})
    Map<String, Object?> raw,
  }) = _Entry;

  factory Entry.fromJson(Map<String, dynamic> json) =>
      _$EntryFromJson(json).copyWith(raw: json);

  EntryKind get kindValue => EntryKind.fromWire(kind);
}
