// Release preflight: fails unless a define file configures real mode.
//
//   dart run tool/check_release_config.dart config/release.json
//
// Run it before every release build (tool/build_release.sh does).

import 'dart:convert';
import 'dart:io';

import 'package:octo_family/app/config.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'usage: dart run tool/check_release_config.dart <defines.json>',
    );
    exit(64);
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(File(args.single).readAsStringSync());
  } on Object catch (e) {
    stderr.writeln('Cannot read ${args.single}: $e');
    exit(1);
  }
  if (decoded is! Map<String, Object?>) {
    stderr.writeln('${args.single} must be a JSON object');
    exit(1);
  }
  switch (parseConfig(decoded, isRelease: true)) {
    case ConfigOk(:final config) when config.mode == OctoMode.real:
      stdout.writeln('Release config OK (${args.single}).');
    case ConfigOk():
      stderr.writeln('A release build must use OCTO_MODE=real.');
      exit(1);
    case ConfigProblem(:final problems):
      stderr.writeln('Release config rejected (${args.single}):');
      for (final p in problems) {
        stderr.writeln('  - $p');
      }
      exit(1);
  }
}
