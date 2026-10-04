import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/app/config.dart';

void main() {
  test('fake mode is fine in debug and profile builds', () {
    final r = parseConfig({'OCTO_MODE': 'fake'}, isRelease: false);
    expect((r as ConfigOk).config.isFake, isTrue);
  });

  test('fake mode is refused in a release build', () {
    final r = parseConfig({'OCTO_MODE': 'fake'}, isRelease: true);
    expect(r, isA<ConfigProblem>());
  });

  test('no mode, or an unknown one, is a problem, never a silent fake', () {
    expect(parseConfig({}, isRelease: false), isA<ConfigProblem>());
    expect(
      parseConfig({'OCTO_MODE': 'demo'}, isRelease: false),
      isA<ConfigProblem>(),
    );
  });

  test('real mode needs Supabase settings over https', () {
    final missing =
        parseConfig({'OCTO_MODE': 'real'}, isRelease: true) as ConfigProblem;
    expect(missing.problems, hasLength(2));

    final http = parseConfig({
      'OCTO_MODE': 'real',
      'SUPABASE_URL': 'http://x.supabase.co',
      'SUPABASE_ANON_KEY': 'k',
    }, isRelease: true);
    expect(http, isA<ConfigProblem>());

    final ok = parseConfig({
      'OCTO_MODE': 'real',
      'SUPABASE_URL': 'https://x.supabase.co',
      'SUPABASE_ANON_KEY': 'k',
    }, isRelease: true) as ConfigOk;
    expect(ok.config.mode, OctoMode.real);
    expect(ok.config.apiBase, Uri.parse('https://www.october.dev'));
  });

  test('the committed config files: example is real, fake is fake', () {
    Map<String, Object?> read(String path) =>
        jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
    expect(
      parseConfig(read('config/example.json'), isRelease: true),
      isA<ConfigOk>(),
    );
    expect(
      parseConfig(read('config/fake.json'), isRelease: true),
      isA<ConfigProblem>(),
    );
    expect(
      parseConfig(read('config/fake.json'), isRelease: false),
      isA<ConfigOk>(),
    );
  });
}
