// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TodoContext {

 String? get app; String? get window; String? get url;
/// Create a copy of TodoContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodoContextCopyWith<TodoContext> get copyWith => _$TodoContextCopyWithImpl<TodoContext>(this as TodoContext, _$identity);

  /// Serializes this TodoContext to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TodoContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodoContext&&(identical(other.app, _this.app) || other.app == _this.app)&&(identical(other.window, _this.window) || other.window == _this.window)&&(identical(other.url, _this.url) || other.url == _this.url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TodoContext;
  return Object.hash(runtimeType,_this.app,_this.window,_this.url);
}

@override
String toString() {
  final _this = this as TodoContext;
  return 'TodoContext(app: ${_this.app}, window: ${_this.window}, url: ${_this.url})';
}


}

/// @nodoc
abstract mixin class $TodoContextCopyWith<$Res>  {
  factory $TodoContextCopyWith(TodoContext value, $Res Function(TodoContext) _then) = _$TodoContextCopyWithImpl;
@useResult
$Res call({
 String? app, String? window, String? url
});




}
/// @nodoc
class _$TodoContextCopyWithImpl<$Res>
    implements $TodoContextCopyWith<$Res> {
  _$TodoContextCopyWithImpl(this._self, this._then);

  final TodoContext _self;
  final $Res Function(TodoContext) _then;

/// Create a copy of TodoContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? app = freezed,Object? window = freezed,Object? url = freezed,}) {
  return _then(TodoContext(
app: freezed == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as String?,window: freezed == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TodoContext].
extension TodoContextPatterns on TodoContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TodoContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TodoContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TodoContext value)  $default,){
final _that = this;
switch (_that) {
case _TodoContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TodoContext value)?  $default,){
final _that = this;
switch (_that) {
case _TodoContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? app,  String? window,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TodoContext() when $default != null:
return $default(_that.app,_that.window,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? app,  String? window,  String? url)  $default,) {final _that = this;
switch (_that) {
case _TodoContext():
return $default(_that.app,_that.window,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? app,  String? window,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _TodoContext() when $default != null:
return $default(_that.app,_that.window,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TodoContext implements TodoContext {
  const _TodoContext({this.app, this.window, this.url});
  factory _TodoContext.fromJson(Map<String, dynamic> json) => _$TodoContextFromJson(json);

@override final  String? app;
@override final  String? window;
@override final  String? url;

/// Create a copy of TodoContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodoContextCopyWith<_TodoContext> get copyWith => __$TodoContextCopyWithImpl<_TodoContext>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TodoContextToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TodoContext&&(identical(other.app, app) || other.app == app)&&(identical(other.window, window) || other.window == window)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,app,window,url);
}

@override
String toString() {
    return 'TodoContext(app: $app, window: $window, url: $url)';
}


}

/// @nodoc
abstract mixin class _$TodoContextCopyWith<$Res> implements $TodoContextCopyWith<$Res> {
  factory _$TodoContextCopyWith(_TodoContext value, $Res Function(_TodoContext) _then) = __$TodoContextCopyWithImpl;
@override @useResult
$Res call({
 String? app, String? window, String? url
});




}
/// @nodoc
class __$TodoContextCopyWithImpl<$Res>
    implements _$TodoContextCopyWith<$Res> {
  __$TodoContextCopyWithImpl(this._self, this._then);

  final _TodoContext _self;
  final $Res Function(_TodoContext) _then;

/// Create a copy of TodoContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? app = freezed,Object? window = freezed,Object? url = freezed,}) {
  return _then(_TodoContext(
app: freezed == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as String?,window: freezed == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Reply {

 int get at; String? get from; String get text;
/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReplyCopyWith<Reply> get copyWith => _$ReplyCopyWithImpl<Reply>(this as Reply, _$identity);

  /// Serializes this Reply to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Reply;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reply&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.text, _this.text) || other.text == _this.text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Reply;
  return Object.hash(runtimeType,_this.at,_this.from,_this.text);
}

@override
String toString() {
  final _this = this as Reply;
  return 'Reply(at: ${_this.at}, from: ${_this.from}, text: ${_this.text})';
}


}

/// @nodoc
abstract mixin class $ReplyCopyWith<$Res>  {
  factory $ReplyCopyWith(Reply value, $Res Function(Reply) _then) = _$ReplyCopyWithImpl;
@useResult
$Res call({
 int at, String? from, String text
});




}
/// @nodoc
class _$ReplyCopyWithImpl<$Res>
    implements $ReplyCopyWith<$Res> {
  _$ReplyCopyWithImpl(this._self, this._then);

  final Reply _self;
  final $Res Function(Reply) _then;

/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? at = null,Object? from = freezed,Object? text = null,}) {
  return _then(Reply(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Reply].
extension ReplyPatterns on Reply {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reply value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reply() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reply value)  $default,){
final _that = this;
switch (_that) {
case _Reply():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reply value)?  $default,){
final _that = this;
switch (_that) {
case _Reply() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int at,  String? from,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reply() when $default != null:
return $default(_that.at,_that.from,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int at,  String? from,  String text)  $default,) {final _that = this;
switch (_that) {
case _Reply():
return $default(_that.at,_that.from,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int at,  String? from,  String text)?  $default,) {final _that = this;
switch (_that) {
case _Reply() when $default != null:
return $default(_that.at,_that.from,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reply implements Reply {
  const _Reply({required this.at, this.from, this.text = ''});
  factory _Reply.fromJson(Map<String, dynamic> json) => _$ReplyFromJson(json);

@override final  int at;
@override final  String? from;
@override@JsonKey() final  String text;

/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReplyCopyWith<_Reply> get copyWith => __$ReplyCopyWithImpl<_Reply>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReplyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reply&&(identical(other.at, at) || other.at == at)&&(identical(other.from, from) || other.from == from)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,at,from,text);
}

@override
String toString() {
    return 'Reply(at: $at, from: $from, text: $text)';
}


}

/// @nodoc
abstract mixin class _$ReplyCopyWith<$Res> implements $ReplyCopyWith<$Res> {
  factory _$ReplyCopyWith(_Reply value, $Res Function(_Reply) _then) = __$ReplyCopyWithImpl;
@override @useResult
$Res call({
 int at, String? from, String text
});




}
/// @nodoc
class __$ReplyCopyWithImpl<$Res>
    implements _$ReplyCopyWith<$Res> {
  __$ReplyCopyWithImpl(this._self, this._then);

  final _Reply _self;
  final $Res Function(_Reply) _then;

/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? at = null,Object? from = freezed,Object? text = null,}) {
  return _then(_Reply(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Todo {

 String get id; int get at; String get text; String? get answer;@ScreenshotConverter() WireScreenshot? get screenshot; TodoContext? get context; bool get done; List<Reply> get replies;@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> get raw;
/// Create a copy of Todo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodoCopyWith<Todo> get copyWith => _$TodoCopyWithImpl<Todo>(this as Todo, _$identity);

  /// Serializes this Todo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Todo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Todo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.answer, _this.answer) || other.answer == _this.answer)&&(identical(other.screenshot, _this.screenshot) || other.screenshot == _this.screenshot)&&(identical(other.context, _this.context) || other.context == _this.context)&&(identical(other.done, _this.done) || other.done == _this.done)&&const DeepCollectionEquality().equals(other.replies, _this.replies)&&const DeepCollectionEquality().equals(other.raw, _this.raw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Todo;
  return Object.hash(runtimeType,_this.id,_this.at,_this.text,_this.answer,_this.screenshot,_this.context,_this.done,const DeepCollectionEquality().hash(_this.replies),const DeepCollectionEquality().hash(_this.raw));
}

@override
String toString() {
  final _this = this as Todo;
  return 'Todo(id: ${_this.id}, at: ${_this.at}, text: ${_this.text}, answer: ${_this.answer}, screenshot: ${_this.screenshot}, context: ${_this.context}, done: ${_this.done}, replies: ${_this.replies}, raw: ${_this.raw})';
}


}

/// @nodoc
abstract mixin class $TodoCopyWith<$Res>  {
  factory $TodoCopyWith(Todo value, $Res Function(Todo) _then) = _$TodoCopyWithImpl;
@useResult
$Res call({
 String id, int at, String text, String? answer,@ScreenshotConverter() WireScreenshot? screenshot, TodoContext? context, bool done, List<Reply> replies,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> raw
});


$TodoContextCopyWith<$Res>? get context;

}
/// @nodoc
class _$TodoCopyWithImpl<$Res>
    implements $TodoCopyWith<$Res> {
  _$TodoCopyWithImpl(this._self, this._then);

  final Todo _self;
  final $Res Function(Todo) _then;

/// Create a copy of Todo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? at = null,Object? text = null,Object? answer = freezed,Object? screenshot = freezed,Object? context = freezed,Object? done = null,Object? replies = null,Object? raw = null,}) {
  return _then(Todo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,answer: freezed == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String?,screenshot: freezed == screenshot ? _self.screenshot : screenshot // ignore: cast_nullable_to_non_nullable
as WireScreenshot?,context: freezed == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as TodoContext?,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as List<Reply>,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of Todo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TodoContextCopyWith<$Res>? get context {
    if (_self.context == null) {
    return null;
  }

  return $TodoContextCopyWith<$Res>(_self.context!, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}


/// Adds pattern-matching-related methods to [Todo].
extension TodoPatterns on Todo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Todo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Todo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Todo value)  $default,){
final _that = this;
switch (_that) {
case _Todo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Todo value)?  $default,){
final _that = this;
switch (_that) {
case _Todo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int at,  String text,  String? answer, @ScreenshotConverter()  WireScreenshot? screenshot,  TodoContext? context,  bool done,  List<Reply> replies, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Todo() when $default != null:
return $default(_that.id,_that.at,_that.text,_that.answer,_that.screenshot,_that.context,_that.done,_that.replies,_that.raw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int at,  String text,  String? answer, @ScreenshotConverter()  WireScreenshot? screenshot,  TodoContext? context,  bool done,  List<Reply> replies, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)  $default,) {final _that = this;
switch (_that) {
case _Todo():
return $default(_that.id,_that.at,_that.text,_that.answer,_that.screenshot,_that.context,_that.done,_that.replies,_that.raw);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int at,  String text,  String? answer, @ScreenshotConverter()  WireScreenshot? screenshot,  TodoContext? context,  bool done,  List<Reply> replies, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw)?  $default,) {final _that = this;
switch (_that) {
case _Todo() when $default != null:
return $default(_that.id,_that.at,_that.text,_that.answer,_that.screenshot,_that.context,_that.done,_that.replies,_that.raw);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Todo implements Todo {
  const _Todo({required this.id, required this.at, this.text = '', this.answer, @ScreenshotConverter() this.screenshot, this.context, this.done = false,  List<Reply> replies = const <Reply>[], @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, Object?> raw = const <String, Object?>{}}): _replies = replies,_raw = raw;
  factory _Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);

@override final  String id;
@override final  int at;
@override@JsonKey() final  String text;
@override final  String? answer;
@override@ScreenshotConverter() final  WireScreenshot? screenshot;
@override final  TodoContext? context;
@override@JsonKey() final  bool done;
 final  List<Reply> _replies;
@override@JsonKey() List<Reply> get replies {
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_replies);
}

 final  Map<String, Object?> _raw;
@override@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> get raw {
  if (_raw is EqualUnmodifiableMapView) return _raw;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_raw);
}


/// Create a copy of Todo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodoCopyWith<_Todo> get copyWith => __$TodoCopyWithImpl<_Todo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TodoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Todo&&(identical(other.id, id) || other.id == id)&&(identical(other.at, at) || other.at == at)&&(identical(other.text, text) || other.text == text)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.screenshot, screenshot) || other.screenshot == screenshot)&&(identical(other.context, context) || other.context == context)&&(identical(other.done, done) || other.done == done)&&const DeepCollectionEquality().equals(other.replies, _replies)&&const DeepCollectionEquality().equals(other.raw, _raw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,at,text,answer,screenshot,context,done,const DeepCollectionEquality().hash(_replies),const DeepCollectionEquality().hash(_raw));
}

@override
String toString() {
    return 'Todo(id: $id, at: $at, text: $text, answer: $answer, screenshot: $screenshot, context: $context, done: $done, replies: $replies, raw: $raw)';
}


}

/// @nodoc
abstract mixin class _$TodoCopyWith<$Res> implements $TodoCopyWith<$Res> {
  factory _$TodoCopyWith(_Todo value, $Res Function(_Todo) _then) = __$TodoCopyWithImpl;
@override @useResult
$Res call({
 String id, int at, String text, String? answer,@ScreenshotConverter() WireScreenshot? screenshot, TodoContext? context, bool done, List<Reply> replies,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, Object?> raw
});


@override $TodoContextCopyWith<$Res>? get context;

}
/// @nodoc
class __$TodoCopyWithImpl<$Res>
    implements _$TodoCopyWith<$Res> {
  __$TodoCopyWithImpl(this._self, this._then);

  final _Todo _self;
  final $Res Function(_Todo) _then;

/// Create a copy of Todo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? at = null,Object? text = null,Object? answer = freezed,Object? screenshot = freezed,Object? context = freezed,Object? done = null,Object? replies = null,Object? raw = null,}) {
  return _then(_Todo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,answer: freezed == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String?,screenshot: freezed == screenshot ? _self.screenshot : screenshot // ignore: cast_nullable_to_non_nullable
as WireScreenshot?,context: freezed == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as TodoContext?,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,replies: null == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<Reply>,raw: null == raw ? _self._raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

/// Create a copy of Todo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TodoContextCopyWith<$Res>? get context {
    if (_self.context == null) {
    return null;
  }

  return $TodoContextCopyWith<$Res>(_self.context!, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

// dart format on
