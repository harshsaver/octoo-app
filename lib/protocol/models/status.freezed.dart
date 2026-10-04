// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Job {

 String get id; String get title; String? get scope; List<String> get may;
/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobCopyWith<Job> get copyWith => _$JobCopyWithImpl<Job>(this as Job, _$identity);

  /// Serializes this Job to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Job;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Job&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&const DeepCollectionEquality().equals(other.may, _this.may));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Job;
  return Object.hash(runtimeType,_this.id,_this.title,_this.scope,const DeepCollectionEquality().hash(_this.may));
}

@override
String toString() {
  final _this = this as Job;
  return 'Job(id: ${_this.id}, title: ${_this.title}, scope: ${_this.scope}, may: ${_this.may})';
}


}

/// @nodoc
abstract mixin class $JobCopyWith<$Res>  {
  factory $JobCopyWith(Job value, $Res Function(Job) _then) = _$JobCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? scope, List<String> may
});




}
/// @nodoc
class _$JobCopyWithImpl<$Res>
    implements $JobCopyWith<$Res> {
  _$JobCopyWithImpl(this._self, this._then);

  final Job _self;
  final $Res Function(Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? scope = freezed,Object? may = null,}) {
  return _then(Job(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String?,may: null == may ? _self.may : may // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Job].
extension JobPatterns on Job {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Job value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Job() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Job value)  $default,){
final _that = this;
switch (_that) {
case _Job():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Job value)?  $default,){
final _that = this;
switch (_that) {
case _Job() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? scope,  List<String> may)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.id,_that.title,_that.scope,_that.may);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? scope,  List<String> may)  $default,) {final _that = this;
switch (_that) {
case _Job():
return $default(_that.id,_that.title,_that.scope,_that.may);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? scope,  List<String> may)?  $default,) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.id,_that.title,_that.scope,_that.may);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Job extends Job {
  const _Job({required this.id, this.title = '', this.scope,  List<String> may = const <String>[]}): _may = may,super._();
  factory _Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);

@override final  String id;
@override@JsonKey() final  String title;
@override final  String? scope;
 final  List<String> _may;
@override@JsonKey() List<String> get may {
  if (_may is EqualUnmodifiableListView) return _may;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_may);
}


/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobCopyWith<_Job> get copyWith => __$JobCopyWithImpl<_Job>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Job&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.scope, scope) || other.scope == scope)&&const DeepCollectionEquality().equals(other.may, _may));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,scope,const DeepCollectionEquality().hash(_may));
}

@override
String toString() {
    return 'Job(id: $id, title: $title, scope: $scope, may: $may)';
}


}

/// @nodoc
abstract mixin class _$JobCopyWith<$Res> implements $JobCopyWith<$Res> {
  factory _$JobCopyWith(_Job value, $Res Function(_Job) _then) = __$JobCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? scope, List<String> may
});




}
/// @nodoc
class __$JobCopyWithImpl<$Res>
    implements _$JobCopyWith<$Res> {
  __$JobCopyWithImpl(this._self, this._then);

  final _Job _self;
  final $Res Function(_Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? scope = freezed,Object? may = null,}) {
  return _then(_Job(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String?,may: null == may ? _self._may : may // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$FamilyMember {

 String get name; String? get device;
/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyMemberCopyWith<FamilyMember> get copyWith => _$FamilyMemberCopyWithImpl<FamilyMember>(this as FamilyMember, _$identity);

  /// Serializes this FamilyMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FamilyMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilyMember&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.device, _this.device) || other.device == _this.device));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FamilyMember;
  return Object.hash(runtimeType,_this.name,_this.device);
}

@override
String toString() {
  final _this = this as FamilyMember;
  return 'FamilyMember(name: ${_this.name}, device: ${_this.device})';
}


}

/// @nodoc
abstract mixin class $FamilyMemberCopyWith<$Res>  {
  factory $FamilyMemberCopyWith(FamilyMember value, $Res Function(FamilyMember) _then) = _$FamilyMemberCopyWithImpl;
@useResult
$Res call({
 String name, String? device
});




}
/// @nodoc
class _$FamilyMemberCopyWithImpl<$Res>
    implements $FamilyMemberCopyWith<$Res> {
  _$FamilyMemberCopyWithImpl(this._self, this._then);

  final FamilyMember _self;
  final $Res Function(FamilyMember) _then;

/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? device = freezed,}) {
  return _then(FamilyMember(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FamilyMember].
extension FamilyMemberPatterns on FamilyMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilyMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilyMember value)  $default,){
final _that = this;
switch (_that) {
case _FamilyMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilyMember value)?  $default,){
final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? device)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
return $default(_that.name,_that.device);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? device)  $default,) {final _that = this;
switch (_that) {
case _FamilyMember():
return $default(_that.name,_that.device);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? device)?  $default,) {final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
return $default(_that.name,_that.device);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FamilyMember implements FamilyMember {
  const _FamilyMember({this.name = '', this.device});
  factory _FamilyMember.fromJson(Map<String, dynamic> json) => _$FamilyMemberFromJson(json);

@override@JsonKey() final  String name;
@override final  String? device;

/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyMemberCopyWith<_FamilyMember> get copyWith => __$FamilyMemberCopyWithImpl<_FamilyMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilyMemberToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilyMember&&(identical(other.name, name) || other.name == name)&&(identical(other.device, device) || other.device == device));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,device);
}

@override
String toString() {
    return 'FamilyMember(name: $name, device: $device)';
}


}

/// @nodoc
abstract mixin class _$FamilyMemberCopyWith<$Res> implements $FamilyMemberCopyWith<$Res> {
  factory _$FamilyMemberCopyWith(_FamilyMember value, $Res Function(_FamilyMember) _then) = __$FamilyMemberCopyWithImpl;
@override @useResult
$Res call({
 String name, String? device
});




}
/// @nodoc
class __$FamilyMemberCopyWithImpl<$Res>
    implements _$FamilyMemberCopyWith<$Res> {
  __$FamilyMemberCopyWithImpl(this._self, this._then);

  final _FamilyMember _self;
  final $Res Function(_FamilyMember) _then;

/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? device = freezed,}) {
  return _then(_FamilyMember(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TodoCounts {

 int get open;
/// Create a copy of TodoCounts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodoCountsCopyWith<TodoCounts> get copyWith => _$TodoCountsCopyWithImpl<TodoCounts>(this as TodoCounts, _$identity);

  /// Serializes this TodoCounts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TodoCounts;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodoCounts&&(identical(other.open, _this.open) || other.open == _this.open));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TodoCounts;
  return Object.hash(runtimeType,_this.open);
}

@override
String toString() {
  final _this = this as TodoCounts;
  return 'TodoCounts(open: ${_this.open})';
}


}

/// @nodoc
abstract mixin class $TodoCountsCopyWith<$Res>  {
  factory $TodoCountsCopyWith(TodoCounts value, $Res Function(TodoCounts) _then) = _$TodoCountsCopyWithImpl;
@useResult
$Res call({
 int open
});




}
/// @nodoc
class _$TodoCountsCopyWithImpl<$Res>
    implements $TodoCountsCopyWith<$Res> {
  _$TodoCountsCopyWithImpl(this._self, this._then);

  final TodoCounts _self;
  final $Res Function(TodoCounts) _then;

/// Create a copy of TodoCounts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? open = null,}) {
  return _then(TodoCounts(
open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TodoCounts].
extension TodoCountsPatterns on TodoCounts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TodoCounts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TodoCounts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TodoCounts value)  $default,){
final _that = this;
switch (_that) {
case _TodoCounts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TodoCounts value)?  $default,){
final _that = this;
switch (_that) {
case _TodoCounts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int open)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TodoCounts() when $default != null:
return $default(_that.open);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int open)  $default,) {final _that = this;
switch (_that) {
case _TodoCounts():
return $default(_that.open);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int open)?  $default,) {final _that = this;
switch (_that) {
case _TodoCounts() when $default != null:
return $default(_that.open);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TodoCounts implements TodoCounts {
  const _TodoCounts({this.open = 0});
  factory _TodoCounts.fromJson(Map<String, dynamic> json) => _$TodoCountsFromJson(json);

@override@JsonKey() final  int open;

/// Create a copy of TodoCounts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodoCountsCopyWith<_TodoCounts> get copyWith => __$TodoCountsCopyWithImpl<_TodoCounts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TodoCountsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TodoCounts&&(identical(other.open, open) || other.open == open));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,open);
}

@override
String toString() {
    return 'TodoCounts(open: $open)';
}


}

/// @nodoc
abstract mixin class _$TodoCountsCopyWith<$Res> implements $TodoCountsCopyWith<$Res> {
  factory _$TodoCountsCopyWith(_TodoCounts value, $Res Function(_TodoCounts) _then) = __$TodoCountsCopyWithImpl;
@override @useResult
$Res call({
 int open
});




}
/// @nodoc
class __$TodoCountsCopyWithImpl<$Res>
    implements _$TodoCountsCopyWith<$Res> {
  __$TodoCountsCopyWithImpl(this._self, this._then);

  final _TodoCounts _self;
  final $Res Function(_TodoCounts) _then;

/// Create a copy of TodoCounts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? open = null,}) {
  return _then(_TodoCounts(
open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$HelpState {

 int get since; String? get text;
/// Create a copy of HelpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelpStateCopyWith<HelpState> get copyWith => _$HelpStateCopyWithImpl<HelpState>(this as HelpState, _$identity);

  /// Serializes this HelpState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HelpState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelpState&&(identical(other.since, _this.since) || other.since == _this.since)&&(identical(other.text, _this.text) || other.text == _this.text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HelpState;
  return Object.hash(runtimeType,_this.since,_this.text);
}

@override
String toString() {
  final _this = this as HelpState;
  return 'HelpState(since: ${_this.since}, text: ${_this.text})';
}


}

/// @nodoc
abstract mixin class $HelpStateCopyWith<$Res>  {
  factory $HelpStateCopyWith(HelpState value, $Res Function(HelpState) _then) = _$HelpStateCopyWithImpl;
@useResult
$Res call({
 int since, String? text
});




}
/// @nodoc
class _$HelpStateCopyWithImpl<$Res>
    implements $HelpStateCopyWith<$Res> {
  _$HelpStateCopyWithImpl(this._self, this._then);

  final HelpState _self;
  final $Res Function(HelpState) _then;

/// Create a copy of HelpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? since = null,Object? text = freezed,}) {
  return _then(HelpState(
since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HelpState].
extension HelpStatePatterns on HelpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelpState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelpState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelpState value)  $default,){
final _that = this;
switch (_that) {
case _HelpState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelpState value)?  $default,){
final _that = this;
switch (_that) {
case _HelpState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int since,  String? text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelpState() when $default != null:
return $default(_that.since,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int since,  String? text)  $default,) {final _that = this;
switch (_that) {
case _HelpState():
return $default(_that.since,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int since,  String? text)?  $default,) {final _that = this;
switch (_that) {
case _HelpState() when $default != null:
return $default(_that.since,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelpState implements HelpState {
  const _HelpState({required this.since, this.text});
  factory _HelpState.fromJson(Map<String, dynamic> json) => _$HelpStateFromJson(json);

@override final  int since;
@override final  String? text;

/// Create a copy of HelpState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelpStateCopyWith<_HelpState> get copyWith => __$HelpStateCopyWithImpl<_HelpState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelpStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelpState&&(identical(other.since, since) || other.since == since)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,since,text);
}

@override
String toString() {
    return 'HelpState(since: $since, text: $text)';
}


}

/// @nodoc
abstract mixin class _$HelpStateCopyWith<$Res> implements $HelpStateCopyWith<$Res> {
  factory _$HelpStateCopyWith(_HelpState value, $Res Function(_HelpState) _then) = __$HelpStateCopyWithImpl;
@override @useResult
$Res call({
 int since, String? text
});




}
/// @nodoc
class __$HelpStateCopyWithImpl<$Res>
    implements _$HelpStateCopyWith<$Res> {
  __$HelpStateCopyWithImpl(this._self, this._then);

  final _HelpState _self;
  final $Res Function(_HelpState) _then;

/// Create a copy of HelpState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? since = null,Object? text = freezed,}) {
  return _then(_HelpState(
since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AgentState {

 bool get connected;
/// Create a copy of AgentState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentStateCopyWith<AgentState> get copyWith => _$AgentStateCopyWithImpl<AgentState>(this as AgentState, _$identity);

  /// Serializes this AgentState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AgentState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentState&&(identical(other.connected, _this.connected) || other.connected == _this.connected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AgentState;
  return Object.hash(runtimeType,_this.connected);
}

@override
String toString() {
  final _this = this as AgentState;
  return 'AgentState(connected: ${_this.connected})';
}


}

/// @nodoc
abstract mixin class $AgentStateCopyWith<$Res>  {
  factory $AgentStateCopyWith(AgentState value, $Res Function(AgentState) _then) = _$AgentStateCopyWithImpl;
@useResult
$Res call({
 bool connected
});




}
/// @nodoc
class _$AgentStateCopyWithImpl<$Res>
    implements $AgentStateCopyWith<$Res> {
  _$AgentStateCopyWithImpl(this._self, this._then);

  final AgentState _self;
  final $Res Function(AgentState) _then;

/// Create a copy of AgentState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connected = null,}) {
  return _then(AgentState(
connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentState].
extension AgentStatePatterns on AgentState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentState value)  $default,){
final _that = this;
switch (_that) {
case _AgentState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentState value)?  $default,){
final _that = this;
switch (_that) {
case _AgentState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool connected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentState() when $default != null:
return $default(_that.connected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool connected)  $default,) {final _that = this;
switch (_that) {
case _AgentState():
return $default(_that.connected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool connected)?  $default,) {final _that = this;
switch (_that) {
case _AgentState() when $default != null:
return $default(_that.connected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentState implements AgentState {
  const _AgentState({this.connected = false});
  factory _AgentState.fromJson(Map<String, dynamic> json) => _$AgentStateFromJson(json);

@override@JsonKey() final  bool connected;

/// Create a copy of AgentState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentStateCopyWith<_AgentState> get copyWith => __$AgentStateCopyWithImpl<_AgentState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentState&&(identical(other.connected, connected) || other.connected == connected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,connected);
}

@override
String toString() {
    return 'AgentState(connected: $connected)';
}


}

/// @nodoc
abstract mixin class _$AgentStateCopyWith<$Res> implements $AgentStateCopyWith<$Res> {
  factory _$AgentStateCopyWith(_AgentState value, $Res Function(_AgentState) _then) = __$AgentStateCopyWithImpl;
@override @useResult
$Res call({
 bool connected
});




}
/// @nodoc
class __$AgentStateCopyWithImpl<$Res>
    implements _$AgentStateCopyWith<$Res> {
  __$AgentStateCopyWithImpl(this._self, this._then);

  final _AgentState _self;
  final $Res Function(_AgentState) _then;

/// Create a copy of AgentState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connected = null,}) {
  return _then(_AgentState(
connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ComputerStatus {

 String? get computer; String? get person; String? get language; String? get os; bool get busy; Task? get task; List<Task> get queued; List<Task> get recent; TodoCounts? get todos; HelpState? get help; Policy? get policy; List<FamilyMember> get family; List<Job> get jobs; AgentState? get agent;@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> get raw;
/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComputerStatusCopyWith<ComputerStatus> get copyWith => _$ComputerStatusCopyWithImpl<ComputerStatus>(this as ComputerStatus, _$identity);

  /// Serializes this ComputerStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ComputerStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComputerStatus&&(identical(other.computer, _this.computer) || other.computer == _this.computer)&&(identical(other.person, _this.person) || other.person == _this.person)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.os, _this.os) || other.os == _this.os)&&(identical(other.busy, _this.busy) || other.busy == _this.busy)&&(identical(other.task, _this.task) || other.task == _this.task)&&const DeepCollectionEquality().equals(other.queued, _this.queued)&&const DeepCollectionEquality().equals(other.recent, _this.recent)&&(identical(other.todos, _this.todos) || other.todos == _this.todos)&&(identical(other.help, _this.help) || other.help == _this.help)&&(identical(other.policy, _this.policy) || other.policy == _this.policy)&&const DeepCollectionEquality().equals(other.family, _this.family)&&const DeepCollectionEquality().equals(other.jobs, _this.jobs)&&(identical(other.agent, _this.agent) || other.agent == _this.agent)&&const DeepCollectionEquality().equals(other.raw, _this.raw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ComputerStatus;
  return Object.hash(runtimeType,_this.computer,_this.person,_this.language,_this.os,_this.busy,_this.task,const DeepCollectionEquality().hash(_this.queued),const DeepCollectionEquality().hash(_this.recent),_this.todos,_this.help,_this.policy,const DeepCollectionEquality().hash(_this.family),const DeepCollectionEquality().hash(_this.jobs),_this.agent,const DeepCollectionEquality().hash(_this.raw));
}

@override
String toString() {
  final _this = this as ComputerStatus;
  return 'ComputerStatus(computer: ${_this.computer}, person: ${_this.person}, language: ${_this.language}, os: ${_this.os}, busy: ${_this.busy}, task: ${_this.task}, queued: ${_this.queued}, recent: ${_this.recent}, todos: ${_this.todos}, help: ${_this.help}, policy: ${_this.policy}, family: ${_this.family}, jobs: ${_this.jobs}, agent: ${_this.agent}, raw: ${_this.raw})';
}


}

/// @nodoc
abstract mixin class $ComputerStatusCopyWith<$Res>  {
  factory $ComputerStatusCopyWith(ComputerStatus value, $Res Function(ComputerStatus) _then) = _$ComputerStatusCopyWithImpl;
@useResult
$Res call({
 String? computer, String? person, String? language, String? os, bool busy, Task? task, List<Task> queued, List<Task> recent, TodoCounts? todos, HelpState? help, Policy? policy, List<FamilyMember> family, List<Job> jobs, AgentState? agent,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> raw
});


$TaskCopyWith<$Res>? get task;$TodoCountsCopyWith<$Res>? get todos;$HelpStateCopyWith<$Res>? get help;$PolicyCopyWith<$Res>? get policy;$AgentStateCopyWith<$Res>? get agent;

}
/// @nodoc
class _$ComputerStatusCopyWithImpl<$Res>
    implements $ComputerStatusCopyWith<$Res> {
  _$ComputerStatusCopyWithImpl(this._self, this._then);

  final ComputerStatus _self;
  final $Res Function(ComputerStatus) _then;

/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? computer = freezed,Object? person = freezed,Object? language = freezed,Object? os = freezed,Object? busy = null,Object? task = freezed,Object? queued = null,Object? recent = null,Object? todos = freezed,Object? help = freezed,Object? policy = freezed,Object? family = null,Object? jobs = null,Object? agent = freezed,Object? raw = null,}) {
  return _then(ComputerStatus(
computer: freezed == computer ? _self.computer : computer // ignore: cast_nullable_to_non_nullable
as String?,person: freezed == person ? _self.person : person // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,os: freezed == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,task: freezed == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task?,queued: null == queued ? _self.queued : queued // ignore: cast_nullable_to_non_nullable
as List<Task>,recent: null == recent ? _self.recent : recent // ignore: cast_nullable_to_non_nullable
as List<Task>,todos: freezed == todos ? _self.todos : todos // ignore: cast_nullable_to_non_nullable
as TodoCounts?,help: freezed == help ? _self.help : help // ignore: cast_nullable_to_non_nullable
as HelpState?,policy: freezed == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as Policy?,family: null == family ? _self.family : family // ignore: cast_nullable_to_non_nullable
as List<FamilyMember>,jobs: null == jobs ? _self.jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<Job>,agent: freezed == agent ? _self.agent : agent // ignore: cast_nullable_to_non_nullable
as AgentState?,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskCopyWith<$Res>? get task {
    if (_self.task == null) {
    return null;
  }

  return $TaskCopyWith<$Res>(_self.task!, (value) {
    return _then(_self.copyWith(task: value));
  });
}/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TodoCountsCopyWith<$Res>? get todos {
    if (_self.todos == null) {
    return null;
  }

  return $TodoCountsCopyWith<$Res>(_self.todos!, (value) {
    return _then(_self.copyWith(todos: value));
  });
}/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelpStateCopyWith<$Res>? get help {
    if (_self.help == null) {
    return null;
  }

  return $HelpStateCopyWith<$Res>(_self.help!, (value) {
    return _then(_self.copyWith(help: value));
  });
}/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PolicyCopyWith<$Res>? get policy {
    if (_self.policy == null) {
    return null;
  }

  return $PolicyCopyWith<$Res>(_self.policy!, (value) {
    return _then(_self.copyWith(policy: value));
  });
}/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgentStateCopyWith<$Res>? get agent {
    if (_self.agent == null) {
    return null;
  }

  return $AgentStateCopyWith<$Res>(_self.agent!, (value) {
    return _then(_self.copyWith(agent: value));
  });
}
}


/// Adds pattern-matching-related methods to [ComputerStatus].
extension ComputerStatusPatterns on ComputerStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComputerStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComputerStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComputerStatus value)  $default,){
final _that = this;
switch (_that) {
case _ComputerStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComputerStatus value)?  $default,){
final _that = this;
switch (_that) {
case _ComputerStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? computer,  String? person,  String? language,  String? os,  bool busy,  Task? task,  List<Task> queued,  List<Task> recent,  TodoCounts? todos,  HelpState? help,  Policy? policy,  List<FamilyMember> family,  List<Job> jobs,  AgentState? agent, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComputerStatus() when $default != null:
return $default(_that.computer,_that.person,_that.language,_that.os,_that.busy,_that.task,_that.queued,_that.recent,_that.todos,_that.help,_that.policy,_that.family,_that.jobs,_that.agent,_that.raw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? computer,  String? person,  String? language,  String? os,  bool busy,  Task? task,  List<Task> queued,  List<Task> recent,  TodoCounts? todos,  HelpState? help,  Policy? policy,  List<FamilyMember> family,  List<Job> jobs,  AgentState? agent, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)  $default,) {final _that = this;
switch (_that) {
case _ComputerStatus():
return $default(_that.computer,_that.person,_that.language,_that.os,_that.busy,_that.task,_that.queued,_that.recent,_that.todos,_that.help,_that.policy,_that.family,_that.jobs,_that.agent,_that.raw);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? computer,  String? person,  String? language,  String? os,  bool busy,  Task? task,  List<Task> queued,  List<Task> recent,  TodoCounts? todos,  HelpState? help,  Policy? policy,  List<FamilyMember> family,  List<Job> jobs,  AgentState? agent, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)?  $default,) {final _that = this;
switch (_that) {
case _ComputerStatus() when $default != null:
return $default(_that.computer,_that.person,_that.language,_that.os,_that.busy,_that.task,_that.queued,_that.recent,_that.todos,_that.help,_that.policy,_that.family,_that.jobs,_that.agent,_that.raw);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComputerStatus implements ComputerStatus {
  const _ComputerStatus({this.computer, this.person, this.language, this.os, this.busy = false, this.task,  List<Task> queued = const <Task>[],  List<Task> recent = const <Task>[], this.todos, this.help, this.policy,  List<FamilyMember> family = const <FamilyMember>[],  List<Job> jobs = const <Job>[], this.agent, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw = const <String, Object?>{}}): _queued = queued,_recent = recent,_family = family,_jobs = jobs,_raw = raw;
  factory _ComputerStatus.fromJson(Map<String, dynamic> json) => _$ComputerStatusFromJson(json);

@override final  String? computer;
@override final  String? person;
@override final  String? language;
@override final  String? os;
@override@JsonKey() final  bool busy;
@override final  Task? task;
 final  List<Task> _queued;
@override@JsonKey() List<Task> get queued {
  if (_queued is EqualUnmodifiableListView) return _queued;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queued);
}

 final  List<Task> _recent;
@override@JsonKey() List<Task> get recent {
  if (_recent is EqualUnmodifiableListView) return _recent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recent);
}

@override final  TodoCounts? todos;
@override final  HelpState? help;
@override final  Policy? policy;
 final  List<FamilyMember> _family;
@override@JsonKey() List<FamilyMember> get family {
  if (_family is EqualUnmodifiableListView) return _family;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_family);
}

 final  List<Job> _jobs;
@override@JsonKey() List<Job> get jobs {
  if (_jobs is EqualUnmodifiableListView) return _jobs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_jobs);
}

@override final  AgentState? agent;
 final  Map<String, Object?> _raw;
@override@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> get raw {
  if (_raw is EqualUnmodifiableMapView) return _raw;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_raw);
}


/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComputerStatusCopyWith<_ComputerStatus> get copyWith => __$ComputerStatusCopyWithImpl<_ComputerStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComputerStatusToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComputerStatus&&(identical(other.computer, computer) || other.computer == computer)&&(identical(other.person, person) || other.person == person)&&(identical(other.language, language) || other.language == language)&&(identical(other.os, os) || other.os == os)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.task, task) || other.task == task)&&const DeepCollectionEquality().equals(other.queued, _queued)&&const DeepCollectionEquality().equals(other.recent, _recent)&&(identical(other.todos, todos) || other.todos == todos)&&(identical(other.help, help) || other.help == help)&&(identical(other.policy, policy) || other.policy == policy)&&const DeepCollectionEquality().equals(other.family, _family)&&const DeepCollectionEquality().equals(other.jobs, _jobs)&&(identical(other.agent, agent) || other.agent == agent)&&const DeepCollectionEquality().equals(other.raw, _raw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,computer,person,language,os,busy,task,const DeepCollectionEquality().hash(_queued),const DeepCollectionEquality().hash(_recent),todos,help,policy,const DeepCollectionEquality().hash(_family),const DeepCollectionEquality().hash(_jobs),agent,const DeepCollectionEquality().hash(_raw));
}

@override
String toString() {
    return 'ComputerStatus(computer: $computer, person: $person, language: $language, os: $os, busy: $busy, task: $task, queued: $queued, recent: $recent, todos: $todos, help: $help, policy: $policy, family: $family, jobs: $jobs, agent: $agent, raw: $raw)';
}


}

/// @nodoc
abstract mixin class _$ComputerStatusCopyWith<$Res> implements $ComputerStatusCopyWith<$Res> {
  factory _$ComputerStatusCopyWith(_ComputerStatus value, $Res Function(_ComputerStatus) _then) = __$ComputerStatusCopyWithImpl;
@override @useResult
$Res call({
 String? computer, String? person, String? language, String? os, bool busy, Task? task, List<Task> queued, List<Task> recent, TodoCounts? todos, HelpState? help, Policy? policy, List<FamilyMember> family, List<Job> jobs, AgentState? agent,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> raw
});


@override $TaskCopyWith<$Res>? get task;@override $TodoCountsCopyWith<$Res>? get todos;@override $HelpStateCopyWith<$Res>? get help;@override $PolicyCopyWith<$Res>? get policy;@override $AgentStateCopyWith<$Res>? get agent;

}
/// @nodoc
class __$ComputerStatusCopyWithImpl<$Res>
    implements _$ComputerStatusCopyWith<$Res> {
  __$ComputerStatusCopyWithImpl(this._self, this._then);

  final _ComputerStatus _self;
  final $Res Function(_ComputerStatus) _then;

/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? computer = freezed,Object? person = freezed,Object? language = freezed,Object? os = freezed,Object? busy = null,Object? task = freezed,Object? queued = null,Object? recent = null,Object? todos = freezed,Object? help = freezed,Object? policy = freezed,Object? family = null,Object? jobs = null,Object? agent = freezed,Object? raw = null,}) {
  return _then(_ComputerStatus(
computer: freezed == computer ? _self.computer : computer // ignore: cast_nullable_to_non_nullable
as String?,person: freezed == person ? _self.person : person // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,os: freezed == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,task: freezed == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task?,queued: null == queued ? _self._queued : queued // ignore: cast_nullable_to_non_nullable
as List<Task>,recent: null == recent ? _self._recent : recent // ignore: cast_nullable_to_non_nullable
as List<Task>,todos: freezed == todos ? _self.todos : todos // ignore: cast_nullable_to_non_nullable
as TodoCounts?,help: freezed == help ? _self.help : help // ignore: cast_nullable_to_non_nullable
as HelpState?,policy: freezed == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as Policy?,family: null == family ? _self._family : family // ignore: cast_nullable_to_non_nullable
as List<FamilyMember>,jobs: null == jobs ? _self._jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<Job>,agent: freezed == agent ? _self.agent : agent // ignore: cast_nullable_to_non_nullable
as AgentState?,raw: null == raw ? _self._raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskCopyWith<$Res>? get task {
    if (_self.task == null) {
    return null;
  }

  return $TaskCopyWith<$Res>(_self.task!, (value) {
    return _then(_self.copyWith(task: value));
  });
}/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TodoCountsCopyWith<$Res>? get todos {
    if (_self.todos == null) {
    return null;
  }

  return $TodoCountsCopyWith<$Res>(_self.todos!, (value) {
    return _then(_self.copyWith(todos: value));
  });
}/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelpStateCopyWith<$Res>? get help {
    if (_self.help == null) {
    return null;
  }

  return $HelpStateCopyWith<$Res>(_self.help!, (value) {
    return _then(_self.copyWith(help: value));
  });
}/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PolicyCopyWith<$Res>? get policy {
    if (_self.policy == null) {
    return null;
  }

  return $PolicyCopyWith<$Res>(_self.policy!, (value) {
    return _then(_self.copyWith(policy: value));
  });
}/// Create a copy of ComputerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgentStateCopyWith<$Res>? get agent {
    if (_self.agent == null) {
    return null;
  }

  return $AgentStateCopyWith<$Res>(_self.agent!, (value) {
    return _then(_self.copyWith(agent: value));
  });
}
}

// dart format on
