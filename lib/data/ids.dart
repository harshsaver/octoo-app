import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A stable id for something her computer doesn't give an id to (log
/// entries, help, screens): sha256 of the canonical JSON array of [parts],
/// which can't be confused across field boundaries.
String stableId(List<Object?> parts) =>
    sha256.convert(utf8.encode(jsonEncode(parts))).toString().substring(0, 32);

/// Content id for screenshot bytes.
String contentId(List<int> bytes) =>
    sha256.convert(bytes).toString().substring(0, 32);
