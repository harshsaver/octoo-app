// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Policy {

 bool get askEveryChange; bool get askBeforeLooking; List<String> get never; List<String> get blockedSites;@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> get raw;
/// Create a copy of Policy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PolicyCopyWith<Policy> get copyWith => _$PolicyCopyWithImpl<Policy>(this as Policy, _$identity);

  /// Serializes this Policy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Policy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Policy&&(identical(other.askEveryChange, _this.askEveryChange) || other.askEveryChange == _this.askEveryChange)&&(identical(other.askBeforeLooking, _this.askBeforeLooking) || other.askBeforeLooking == _this.askBeforeLooking)&&const DeepCollectionEquality().equals(other.never, _this.never)&&const DeepCollectionEquality().equals(other.blockedSites, _this.blockedSites)&&const DeepCollectionEquality().equals(other.raw, _this.raw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Policy;
  return Object.hash(runtimeType,_this.askEveryChange,_this.askBeforeLooking,const DeepCollectionEquality().hash(_this.never),const DeepCollectionEquality().hash(_this.blockedSites),const DeepCollectionEquality().hash(_this.raw));
}

@override
String toString() {
  final _this = this as Policy;
  return 'Policy(askEveryChange: ${_this.askEveryChange}, askBeforeLooking: ${_this.askBeforeLooking}, never: ${_this.never}, blockedSites: ${_this.blockedSites}, raw: ${_this.raw})';
}


}

/// @nodoc
abstract mixin class $PolicyCopyWith<$Res>  {
  factory $PolicyCopyWith(Policy value, $Res Function(Policy) _then) = _$PolicyCopyWithImpl;
@useResult
$Res call({
 bool askEveryChange, bool askBeforeLooking, List<String> never, List<String> blockedSites,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> raw
});




}
/// @nodoc
class _$PolicyCopyWithImpl<$Res>
    implements $PolicyCopyWith<$Res> {
  _$PolicyCopyWithImpl(this._self, this._then);

  final Policy _self;
  final $Res Function(Policy) _then;

/// Create a copy of Policy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? askEveryChange = null,Object? askBeforeLooking = null,Object? never = null,Object? blockedSites = null,Object? raw = null,}) {
  return _then(Policy(
askEveryChange: null == askEveryChange ? _self.askEveryChange : askEveryChange // ignore: cast_nullable_to_non_nullable
as bool,askBeforeLooking: null == askBeforeLooking ? _self.askBeforeLooking : askBeforeLooking // ignore: cast_nullable_to_non_nullable
as bool,never: null == never ? _self.never : never // ignore: cast_nullable_to_non_nullable
as List<String>,blockedSites: null == blockedSites ? _self.blockedSites : blockedSites // ignore: cast_nullable_to_non_nullable
as List<String>,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [Policy].
extension PolicyPatterns on Policy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Policy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Policy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Policy value)  $default,){
final _that = this;
switch (_that) {
case _Policy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Policy value)?  $default,){
final _that = this;
switch (_that) {
case _Policy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool askEveryChange,  bool askBeforeLooking,  List<String> never,  List<String> blockedSites, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Policy() when $default != null:
return $default(_that.askEveryChange,_that.askBeforeLooking,_that.never,_that.blockedSites,_that.raw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool askEveryChange,  bool askBeforeLooking,  List<String> never,  List<String> blockedSites, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)  $default,) {final _that = this;
switch (_that) {
case _Policy():
return $default(_that.askEveryChange,_that.askBeforeLooking,_that.never,_that.blockedSites,_that.raw);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool askEveryChange,  bool askBeforeLooking,  List<String> never,  List<String> blockedSites, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)?  $default,) {final _that = this;
switch (_that) {
case _Policy() when $default != null:
return $default(_that.askEveryChange,_that.askBeforeLooking,_that.never,_that.blockedSites,_that.raw);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Policy extends Policy {
  const _Policy({this.askEveryChange = true, this.askBeforeLooking = false,  List<String> never = const <String>[],  List<String> blockedSites = const <String>[], @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw = const <String, Object?>{}}): _never = never,_blockedSites = blockedSites,_raw = raw,super._();
  factory _Policy.fromJson(Map<String, dynamic> json) => _$PolicyFromJson(json);

@override@JsonKey() final  bool askEveryChange;
@override@JsonKey() final  bool askBeforeLooking;
 final  List<String> _never;
@override@JsonKey() List<String> get never {
  if (_never is EqualUnmodifiableListView) return _never;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_never);
}

 final  List<String> _blockedSites;
@override@JsonKey() List<String> get blockedSites {
  if (_blockedSites is EqualUnmodifiableListView) return _blockedSites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blockedSites);
}

 final  Map<String, Object?> _raw;
@override@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> get raw {
  if (_raw is EqualUnmodifiableMapView) return _raw;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_raw);
}


/// Create a copy of Policy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PolicyCopyWith<_Policy> get copyWith => __$PolicyCopyWithImpl<_Policy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PolicyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Policy&&(identical(other.askEveryChange, askEveryChange) || other.askEveryChange == askEveryChange)&&(identical(other.askBeforeLooking, askBeforeLooking) || other.askBeforeLooking == askBeforeLooking)&&const DeepCollectionEquality().equals(other.never, _never)&&const DeepCollectionEquality().equals(other.blockedSites, _blockedSites)&&const DeepCollectionEquality().equals(other.raw, _raw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,askEveryChange,askBeforeLooking,const DeepCollectionEquality().hash(_never),const DeepCollectionEquality().hash(_blockedSites),const DeepCollectionEquality().hash(_raw));
}

@override
String toString() {
    return 'Policy(askEveryChange: $askEveryChange, askBeforeLooking: $askBeforeLooking, never: $never, blockedSites: $blockedSites, raw: $raw)';
}


}

/// @nodoc
abstract mixin class _$PolicyCopyWith<$Res> implements $PolicyCopyWith<$Res> {
  factory _$PolicyCopyWith(_Policy value, $Res Function(_Policy) _then) = __$PolicyCopyWithImpl;
@override @useResult
$Res call({
 bool askEveryChange, bool askBeforeLooking, List<String> never, List<String> blockedSites,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> raw
});




}
/// @nodoc
class __$PolicyCopyWithImpl<$Res>
    implements _$PolicyCopyWith<$Res> {
  __$PolicyCopyWithImpl(this._self, this._then);

  final _Policy _self;
  final $Res Function(_Policy) _then;

/// Create a copy of Policy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? askEveryChange = null,Object? askBeforeLooking = null,Object? never = null,Object? blockedSites = null,Object? raw = null,}) {
  return _then(_Policy(
askEveryChange: null == askEveryChange ? _self.askEveryChange : askEveryChange // ignore: cast_nullable_to_non_nullable
as bool,askBeforeLooking: null == askBeforeLooking ? _self.askBeforeLooking : askBeforeLooking // ignore: cast_nullable_to_non_nullable
as bool,never: null == never ? _self._never : never // ignore: cast_nullable_to_non_nullable
as List<String>,blockedSites: null == blockedSites ? _self._blockedSites : blockedSites // ignore: cast_nullable_to_non_nullable
as List<String>,raw: null == raw ? _self._raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

// dart format on
