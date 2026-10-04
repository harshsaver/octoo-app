// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskStep {

 int get n; int? get at; String? get say; String? get did; bool? get ok; String? get error;
/// Create a copy of TaskStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskStepCopyWith<TaskStep> get copyWith => _$TaskStepCopyWithImpl<TaskStep>(this as TaskStep, _$identity);

  /// Serializes this TaskStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TaskStep;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskStep&&(identical(other.n, _this.n) || other.n == _this.n)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.say, _this.say) || other.say == _this.say)&&(identical(other.did, _this.did) || other.did == _this.did)&&(identical(other.ok, _this.ok) || other.ok == _this.ok)&&(identical(other.error, _this.error) || other.error == _this.error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TaskStep;
  return Object.hash(runtimeType,_this.n,_this.at,_this.say,_this.did,_this.ok,_this.error);
}

@override
String toString() {
  final _this = this as TaskStep;
  return 'TaskStep(n: ${_this.n}, at: ${_this.at}, say: ${_this.say}, did: ${_this.did}, ok: ${_this.ok}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $TaskStepCopyWith<$Res>  {
  factory $TaskStepCopyWith(TaskStep value, $Res Function(TaskStep) _then) = _$TaskStepCopyWithImpl;
@useResult
$Res call({
 int n, int? at, String? say, String? did, bool? ok, String? error
});




}
/// @nodoc
class _$TaskStepCopyWithImpl<$Res>
    implements $TaskStepCopyWith<$Res> {
  _$TaskStepCopyWithImpl(this._self, this._then);

  final TaskStep _self;
  final $Res Function(TaskStep) _then;

/// Create a copy of TaskStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? n = null,Object? at = freezed,Object? say = freezed,Object? did = freezed,Object? ok = freezed,Object? error = freezed,}) {
  return _then(TaskStep(
n: null == n ? _self.n : n // ignore: cast_nullable_to_non_nullable
as int,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int?,say: freezed == say ? _self.say : say // ignore: cast_nullable_to_non_nullable
as String?,did: freezed == did ? _self.did : did // ignore: cast_nullable_to_non_nullable
as String?,ok: freezed == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskStep].
extension TaskStepPatterns on TaskStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskStep value)  $default,){
final _that = this;
switch (_that) {
case _TaskStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskStep value)?  $default,){
final _that = this;
switch (_that) {
case _TaskStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int n,  int? at,  String? say,  String? did,  bool? ok,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskStep() when $default != null:
return $default(_that.n,_that.at,_that.say,_that.did,_that.ok,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int n,  int? at,  String? say,  String? did,  bool? ok,  String? error)  $default,) {final _that = this;
switch (_that) {
case _TaskStep():
return $default(_that.n,_that.at,_that.say,_that.did,_that.ok,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int n,  int? at,  String? say,  String? did,  bool? ok,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _TaskStep() when $default != null:
return $default(_that.n,_that.at,_that.say,_that.did,_that.ok,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskStep implements TaskStep {
  const _TaskStep({required this.n, this.at, this.say, this.did, this.ok, this.error});
  factory _TaskStep.fromJson(Map<String, dynamic> json) => _$TaskStepFromJson(json);

@override final  int n;
@override final  int? at;
@override final  String? say;
@override final  String? did;
@override final  bool? ok;
@override final  String? error;

/// Create a copy of TaskStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskStepCopyWith<_TaskStep> get copyWith => __$TaskStepCopyWithImpl<_TaskStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskStepToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskStep&&(identical(other.n, n) || other.n == n)&&(identical(other.at, at) || other.at == at)&&(identical(other.say, say) || other.say == say)&&(identical(other.did, did) || other.did == did)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,n,at,say,did,ok,error);
}

@override
String toString() {
    return 'TaskStep(n: $n, at: $at, say: $say, did: $did, ok: $ok, error: $error)';
}


}

/// @nodoc
abstract mixin class _$TaskStepCopyWith<$Res> implements $TaskStepCopyWith<$Res> {
  factory _$TaskStepCopyWith(_TaskStep value, $Res Function(_TaskStep) _then) = __$TaskStepCopyWithImpl;
@override @useResult
$Res call({
 int n, int? at, String? say, String? did, bool? ok, String? error
});




}
/// @nodoc
class __$TaskStepCopyWithImpl<$Res>
    implements _$TaskStepCopyWith<$Res> {
  __$TaskStepCopyWithImpl(this._self, this._then);

  final _TaskStep _self;
  final $Res Function(_TaskStep) _then;

/// Create a copy of TaskStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? n = null,Object? at = freezed,Object? say = freezed,Object? did = freezed,Object? ok = freezed,Object? error = freezed,}) {
  return _then(_TaskStep(
n: null == n ? _self.n : n // ignore: cast_nullable_to_non_nullable
as int,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int?,say: freezed == say ? _self.say : say // ignore: cast_nullable_to_non_nullable
as String?,did: freezed == did ? _self.did : did // ignore: cast_nullable_to_non_nullable
as String?,ok: freezed == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Task {

 String get id; String? get from; String? get fromName; String get text; String? get job; String? get scope; List<String> get may; String get status; String? get say; List<TaskStep> get steps; String? get result; String? get resultForHer;@ScreenshotConverter() WireScreenshot? get screenshot; int? get createdAt; int? get startedAt; int? get endedAt;@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> get raw;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Task;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.fromName, _this.fromName) || other.fromName == _this.fromName)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.job, _this.job) || other.job == _this.job)&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&const DeepCollectionEquality().equals(other.may, _this.may)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.say, _this.say) || other.say == _this.say)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&(identical(other.result, _this.result) || other.result == _this.result)&&(identical(other.resultForHer, _this.resultForHer) || other.resultForHer == _this.resultForHer)&&(identical(other.screenshot, _this.screenshot) || other.screenshot == _this.screenshot)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&const DeepCollectionEquality().equals(other.raw, _this.raw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Task;
  return Object.hash(runtimeType,_this.id,_this.from,_this.fromName,_this.text,_this.job,_this.scope,const DeepCollectionEquality().hash(_this.may),_this.status,_this.say,const DeepCollectionEquality().hash(_this.steps),_this.result,_this.resultForHer,_this.screenshot,_this.createdAt,_this.startedAt,_this.endedAt,const DeepCollectionEquality().hash(_this.raw));
}

@override
String toString() {
  final _this = this as Task;
  return 'Task(id: ${_this.id}, from: ${_this.from}, fromName: ${_this.fromName}, text: ${_this.text}, job: ${_this.job}, scope: ${_this.scope}, may: ${_this.may}, status: ${_this.status}, say: ${_this.say}, steps: ${_this.steps}, result: ${_this.result}, resultForHer: ${_this.resultForHer}, screenshot: ${_this.screenshot}, createdAt: ${_this.createdAt}, startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt}, raw: ${_this.raw})';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String? from, String? fromName, String text, String? job, String? scope, List<String> may, String status, String? say, List<TaskStep> steps, String? result, String? resultForHer,@ScreenshotConverter() WireScreenshot? screenshot, int? createdAt, int? startedAt, int? endedAt,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> raw
});




}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? from = freezed,Object? fromName = freezed,Object? text = null,Object? job = freezed,Object? scope = freezed,Object? may = null,Object? status = null,Object? say = freezed,Object? steps = null,Object? result = freezed,Object? resultForHer = freezed,Object? screenshot = freezed,Object? createdAt = freezed,Object? startedAt = freezed,Object? endedAt = freezed,Object? raw = null,}) {
  return _then(Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,fromName: freezed == fromName ? _self.fromName : fromName // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,job: freezed == job ? _self.job : job // ignore: cast_nullable_to_non_nullable
as String?,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String?,may: null == may ? _self.may : may // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,say: freezed == say ? _self.say : say // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<TaskStep>,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,resultForHer: freezed == resultForHer ? _self.resultForHer : resultForHer // ignore: cast_nullable_to_non_nullable
as String?,screenshot: freezed == screenshot ? _self.screenshot : screenshot // ignore: cast_nullable_to_non_nullable
as WireScreenshot?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as int?,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? from,  String? fromName,  String text,  String? job,  String? scope,  List<String> may,  String status,  String? say,  List<TaskStep> steps,  String? result,  String? resultForHer, @ScreenshotConverter()  WireScreenshot? screenshot,  int? createdAt,  int? startedAt,  int? endedAt, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.from,_that.fromName,_that.text,_that.job,_that.scope,_that.may,_that.status,_that.say,_that.steps,_that.result,_that.resultForHer,_that.screenshot,_that.createdAt,_that.startedAt,_that.endedAt,_that.raw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? from,  String? fromName,  String text,  String? job,  String? scope,  List<String> may,  String status,  String? say,  List<TaskStep> steps,  String? result,  String? resultForHer, @ScreenshotConverter()  WireScreenshot? screenshot,  int? createdAt,  int? startedAt,  int? endedAt, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.from,_that.fromName,_that.text,_that.job,_that.scope,_that.may,_that.status,_that.say,_that.steps,_that.result,_that.resultForHer,_that.screenshot,_that.createdAt,_that.startedAt,_that.endedAt,_that.raw);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? from,  String? fromName,  String text,  String? job,  String? scope,  List<String> may,  String status,  String? say,  List<TaskStep> steps,  String? result,  String? resultForHer, @ScreenshotConverter()  WireScreenshot? screenshot,  int? createdAt,  int? startedAt,  int? endedAt, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.from,_that.fromName,_that.text,_that.job,_that.scope,_that.may,_that.status,_that.say,_that.steps,_that.result,_that.resultForHer,_that.screenshot,_that.createdAt,_that.startedAt,_that.endedAt,_that.raw);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Task extends Task {
  const _Task({required this.id, this.from, this.fromName, this.text = '', this.job, this.scope,  List<String> may = const <String>[], this.status = '', this.say,  List<TaskStep> steps = const <TaskStep>[], this.result, this.resultForHer, @ScreenshotConverter() this.screenshot, this.createdAt, this.startedAt, this.endedAt, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw = const <String, Object?>{}}): _may = may,_steps = steps,_raw = raw,super._();
  factory _Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

@override final  String id;
@override final  String? from;
@override final  String? fromName;
@override@JsonKey() final  String text;
@override final  String? job;
@override final  String? scope;
 final  List<String> _may;
@override@JsonKey() List<String> get may {
  if (_may is EqualUnmodifiableListView) return _may;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_may);
}

@override@JsonKey() final  String status;
@override final  String? say;
 final  List<TaskStep> _steps;
@override@JsonKey() List<TaskStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override final  String? result;
@override final  String? resultForHer;
@override@ScreenshotConverter() final  WireScreenshot? screenshot;
@override final  int? createdAt;
@override final  int? startedAt;
@override final  int? endedAt;
 final  Map<String, Object?> _raw;
@override@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> get raw {
  if (_raw is EqualUnmodifiableMapView) return _raw;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_raw);
}


/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.from, from) || other.from == from)&&(identical(other.fromName, fromName) || other.fromName == fromName)&&(identical(other.text, text) || other.text == text)&&(identical(other.job, job) || other.job == job)&&(identical(other.scope, scope) || other.scope == scope)&&const DeepCollectionEquality().equals(other.may, _may)&&(identical(other.status, status) || other.status == status)&&(identical(other.say, say) || other.say == say)&&const DeepCollectionEquality().equals(other.steps, _steps)&&(identical(other.result, result) || other.result == result)&&(identical(other.resultForHer, resultForHer) || other.resultForHer == resultForHer)&&(identical(other.screenshot, screenshot) || other.screenshot == screenshot)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&const DeepCollectionEquality().equals(other.raw, _raw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,from,fromName,text,job,scope,const DeepCollectionEquality().hash(_may),status,say,const DeepCollectionEquality().hash(_steps),result,resultForHer,screenshot,createdAt,startedAt,endedAt,const DeepCollectionEquality().hash(_raw));
}

@override
String toString() {
    return 'Task(id: $id, from: $from, fromName: $fromName, text: $text, job: $job, scope: $scope, may: $may, status: $status, say: $say, steps: $steps, result: $result, resultForHer: $resultForHer, screenshot: $screenshot, createdAt: $createdAt, startedAt: $startedAt, endedAt: $endedAt, raw: $raw)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String? from, String? fromName, String text, String? job, String? scope, List<String> may, String status, String? say, List<TaskStep> steps, String? result, String? resultForHer,@ScreenshotConverter() WireScreenshot? screenshot, int? createdAt, int? startedAt, int? endedAt,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> raw
});




}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? from = freezed,Object? fromName = freezed,Object? text = null,Object? job = freezed,Object? scope = freezed,Object? may = null,Object? status = null,Object? say = freezed,Object? steps = null,Object? result = freezed,Object? resultForHer = freezed,Object? screenshot = freezed,Object? createdAt = freezed,Object? startedAt = freezed,Object? endedAt = freezed,Object? raw = null,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,fromName: freezed == fromName ? _self.fromName : fromName // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,job: freezed == job ? _self.job : job // ignore: cast_nullable_to_non_nullable
as String?,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String?,may: null == may ? _self._may : may // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,say: freezed == say ? _self.say : say // ignore: cast_nullable_to_non_nullable
as String?,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<TaskStep>,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,resultForHer: freezed == resultForHer ? _self.resultForHer : resultForHer // ignore: cast_nullable_to_non_nullable
as String?,screenshot: freezed == screenshot ? _self.screenshot : screenshot // ignore: cast_nullable_to_non_nullable
as WireScreenshot?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as int?,raw: null == raw ? _self._raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

// dart format on
