// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'policy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Policy _$PolicyFromJson(Map<String, dynamic> json) => _Policy(
  askEveryChange: json['askEveryChange'] as bool? ?? true,
  askBeforeLooking: json['askBeforeLooking'] as bool? ?? false,
  never:
      (json['never'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  blockedSites:
      (json['blockedSites'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$PolicyToJson(_Policy instance) => <String, dynamic>{
  'askEveryChange': instance.askEveryChange,
  'askBeforeLooking': instance.askBeforeLooking,
  'never': instance.never,
  'blockedSites': instance.blockedSites,
};
