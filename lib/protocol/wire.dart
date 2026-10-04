/// Small typed readers for hand-parsed message envelopes.
///
/// They throw [FormatException] naming the field only, never its value, so a
/// malformed message can be logged without leaking content.
library;

typedef WireMap = Map<String, Object?>;

String readString(WireMap m, String key) {
  final v = m[key];
  if (v is String) return v;
  throw FormatException('expected string "$key"');
}

String? readOptString(WireMap m, String key) {
  final v = m[key];
  if (v == null || v is String) return v as String?;
  throw FormatException('expected optional string "$key"');
}

bool readBool(WireMap m, String key) {
  final v = m[key];
  if (v is bool) return v;
  throw FormatException('expected bool "$key"');
}

bool? readOptBool(WireMap m, String key) {
  final v = m[key];
  if (v == null || v is bool) return v as bool?;
  throw FormatException('expected optional bool "$key"');
}

int? readOptInt(WireMap m, String key) {
  final v = m[key];
  if (v == null) return null;
  if (v is num && v.isFinite) return v.toInt();
  throw FormatException('expected optional number "$key"');
}

WireMap readMap(WireMap m, String key) {
  final v = m[key];
  if (v is Map<String, Object?>) return v;
  throw FormatException('expected object "$key"');
}

List<WireMap> readMapList(WireMap m, String key) {
  final v = m[key];
  if (v is! List<Object?>) throw FormatException('expected list "$key"');
  return [
    for (final e in v)
      if (e is Map<String, Object?>)
        e
      else
        throw FormatException('expected objects in "$key"'),
  ];
}
