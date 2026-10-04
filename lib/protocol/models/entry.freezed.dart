// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Entry {

 int get at; String get kind; String? get by; String get text; String? get taskId; String? get job; String? get outcome;@ScreenshotConverter() WireScreenshot? get screenshot;@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> get raw;
/// Create a copy of Entry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryCopyWith<Entry> get copyWith => _$EntryCopyWithImpl<Entry>(this as Entry, _$identity);

  /// Serializes this Entry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Entry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Entry&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.by, _this.by) || other.by == _this.by)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.taskId, _this.taskId) || other.taskId == _this.taskId)&&(identical(other.job, _this.job) || other.job == _this.job)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome)&&(identical(other.screenshot, _this.screenshot) || other.screenshot == _this.screenshot)&&const DeepCollectionEquality().equals(other.raw, _this.raw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Entry;
  return Object.hash(runtimeType,_this.at,_this.kind,_this.by,_this.text,_this.taskId,_this.job,_this.outcome,_this.screenshot,const DeepCollectionEquality().hash(_this.raw));
}

@override
String toString() {
  final _this = this as Entry;
  return 'Entry(at: ${_this.at}, kind: ${_this.kind}, by: ${_this.by}, text: ${_this.text}, taskId: ${_this.taskId}, job: ${_this.job}, outcome: ${_this.outcome}, screenshot: ${_this.screenshot}, raw: ${_this.raw})';
}


}

/// @nodoc
abstract mixin class $EntryCopyWith<$Res>  {
  factory $EntryCopyWith(Entry value, $Res Function(Entry) _then) = _$EntryCopyWithImpl;
@useResult
$Res call({
 int at, String kind, String? by, String text, String? taskId, String? job, String? outcome,@ScreenshotConverter() WireScreenshot? screenshot,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> raw
});




}
/// @nodoc
class _$EntryCopyWithImpl<$Res>
    implements $EntryCopyWith<$Res> {
  _$EntryCopyWithImpl(this._self, this._then);

  final Entry _self;
  final $Res Function(Entry) _then;

/// Create a copy of Entry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? at = null,Object? kind = null,Object? by = freezed,Object? text = null,Object? taskId = freezed,Object? job = freezed,Object? outcome = freezed,Object? screenshot = freezed,Object? raw = null,}) {
  return _then(Entry(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,by: freezed == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,taskId: freezed == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String?,job: freezed == job ? _self.job : job // ignore: cast_nullable_to_non_nullable
as String?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as String?,screenshot: freezed == screenshot ? _self.screenshot : screenshot // ignore: cast_nullable_to_non_nullable
as WireScreenshot?,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [Entry].
extension EntryPatterns on Entry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Entry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Entry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Entry value)  $default,){
final _that = this;
switch (_that) {
case _Entry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Entry value)?  $default,){
final _that = this;
switch (_that) {
case _Entry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int at,  String kind,  String? by,  String text,  String? taskId,  String? job,  String? outcome, @ScreenshotConverter()  WireScreenshot? screenshot, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Entry() when $default != null:
return $default(_that.at,_that.kind,_that.by,_that.text,_that.taskId,_that.job,_that.outcome,_that.screenshot,_that.raw);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int at,  String kind,  String? by,  String text,  String? taskId,  String? job,  String? outcome, @ScreenshotConverter()  WireScreenshot? screenshot, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)  $default,) {final _that = this;
switch (_that) {
case _Entry():
return $default(_that.at,_that.kind,_that.by,_that.text,_that.taskId,_that.job,_that.outcome,_that.screenshot,_that.raw);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int at,  String kind,  String? by,  String text,  String? taskId,  String? job,  String? outcome, @ScreenshotConverter()  WireScreenshot? screenshot, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)?  $default,) {final _that = this;
switch (_that) {
case _Entry() when $default != null:
return $default(_that.at,_that.kind,_that.by,_that.text,_that.taskId,_that.job,_that.outcome,_that.screenshot,_that.raw);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Entry extends Entry {
  const _Entry({required this.at, required this.kind, this.by, this.text = '', this.taskId, this.job, this.outcome, @ScreenshotConverter() this.screenshot, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw = const <String, Object?>{}}): _raw = raw,super._();
  factory _Entry.fromJson(Map<String, dynamic> json) => _$EntryFromJson(json);

@override final  int at;
@override final  String kind;
@override final  String? by;
@override@JsonKey() final  String text;
@override final  String? taskId;
@override final  String? job;
@override final  String? outcome;
@override@ScreenshotConverter() final  WireScreenshot? screenshot;
 final  Map<String, Object?> _raw;
@override@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> get raw {
  if (_raw is EqualUnmodifiableMapView) return _raw;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_raw);
}


/// Create a copy of Entry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntryCopyWith<_Entry> get copyWith => __$EntryCopyWithImpl<_Entry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Entry&&(identical(other.at, at) || other.at == at)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.by, by) || other.by == by)&&(identical(other.text, text) || other.text == text)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.job, job) || other.job == job)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.screenshot, screenshot) || other.screenshot == screenshot)&&const DeepCollectionEquality().equals(other.raw, _raw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,at,kind,by,text,taskId,job,outcome,screenshot,const DeepCollectionEquality().hash(_raw));
}

@override
String toString() {
    return 'Entry(at: $at, kind: $kind, by: $by, text: $text, taskId: $taskId, job: $job, outcome: $outcome, screenshot: $screenshot, raw: $raw)';
}


}

/// @nodoc
abstract mixin class _$EntryCopyWith<$Res> implements $EntryCopyWith<$Res> {
  factory _$EntryCopyWith(_Entry value, $Res Function(_Entry) _then) = __$EntryCopyWithImpl;
@override @useResult
$Res call({
 int at, String kind, String? by, String text, String? taskId, String? job, String? outcome,@ScreenshotConverter() WireScreenshot? screenshot,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> raw
});




}
/// @nodoc
class __$EntryCopyWithImpl<$Res>
    implements _$EntryCopyWith<$Res> {
  __$EntryCopyWithImpl(this._self, this._then);

  final _Entry _self;
  final $Res Function(_Entry) _then;

/// Create a copy of Entry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? at = null,Object? kind = null,Object? by = freezed,Object? text = null,Object? taskId = freezed,Object? job = freezed,Object? outcome = freezed,Object? screenshot = freezed,Object? raw = null,}) {
  return _then(_Entry(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,by: freezed == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,taskId: freezed == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String?,job: freezed == job ? _self.job : job // ignore: cast_nullable_to_non_nullable
as String?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as String?,screenshot: freezed == screenshot ? _self.screenshot : screenshot // ignore: cast_nullable_to_non_nullable
as WireScreenshot?,raw: null == raw ? _self._raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

// dart format on
