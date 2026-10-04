import 'package:freezed_annotation/freezed_annotation.dart';

import 'task.dart';

part 'policy.freezed.dart';
part 'policy.g.dart';

/// Her rules (brief §7.2). [never] and [blockedSites] keep their wire
/// strings, so values this app doesn't know survive an edit unchanged.
@freezed
abstract class Policy with _$Policy {
  const Policy._();

  const factory Policy({
    @Default(true) bool askEveryChange,
    @Default(false) bool askBeforeLooking,
    @Default(<String>[]) List<String> never,
    @Default(<String>[]) List<String> blockedSites,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(<String, Object?>{})
    Map<String, Object?> raw,
  }) = _Policy;

  factory Policy.fromJson(Map<String, dynamic> json) =>
      _$PolicyFromJson(json).copyWith(raw: json);

  List<ChangeKind> get neverKinds => [
    for (final n in never) ChangeKind.fromWire(n),
  ];

  /// The policy to send in `policy.set`: the fields as received, with the
  /// known ones overwritten by this value.
  Map<String, Object?> toWire() => {...raw, ...toJson()};
}
