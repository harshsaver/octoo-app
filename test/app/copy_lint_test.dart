import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Brief §2 and §6: no "user", "device" or "endpoint", and no error codes,
/// in anything families read. Checks the authored strings (the ARB file);
/// names, her computer's own text and logs aren't covered.
void main() {
  test('authored copy avoids banned words and error codes', () {
    final arb = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, Object?>;
    final banned = RegExp(
      r'\b(users?|devices?|endpoints?|error \d+|request pending|'
      r'bad_request|unknown_job|not_found|plan_required|credit_exhausted|'
      r'free_limit|rate_limited|unauthorized)\b',
      caseSensitive: false,
    );
    final offenders = <String>[
      for (final MapEntry(:key, :value) in arb.entries)
        if (!key.startsWith('@') && value is String && banned.hasMatch(value))
          '$key: $value',
    ];
    expect(offenders, isEmpty);
  });
}
