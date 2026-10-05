@Tags(['golden'])
library;

import 'dart:io';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/app/app.dart';
import 'package:octo_family/app/app_settings.dart';
import 'package:octo_family/app/config.dart';
import 'package:octo_family/app/providers.dart';
import 'package:octo_family/data/account_scope.dart';
import 'package:octo_family/data/db/database.dart';
import 'package:octo_family/data/screenshot_store.dart';
import 'package:octo_family/transport/simulator/simulator_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/bubble_gallery.dart';
import '../support/golden_fonts.dart';

/// Baselines for the screens PLAN §5 names: the Octos list, a thread with
/// every bubble kind, and the add-an-Octo sheets, in light and dark.
/// Viewport: a 390×844 phone at 2×.

class _QuietShots extends ScreenshotStore {
  _QuietShots() : super(Directory('/nonexistent'));

  @override
  Future<void> purgeExpired() async {}
}

late SharedPreferences _prefs;

Widget _app() => buildApp(
  ConfigOk(AppConfig.fake),
  roots: AppRoots(support: Directory('/nonexistent/s'), cache: Directory('/nonexistent/c')),
  overrides: [
    databaseProvider.overrideWith((ref) {
      final db = OctoDatabase(NativeDatabase.memory());
      ref.onDispose(db.close);
      return db;
    }),
    screenshotStoreProvider.overrideWith((ref) => _QuietShots()),
    cameraAvailableProvider.overrideWithValue(false),
    sharedPreferencesProvider.overrideWithValue(_prefs),
    // Seeded: the same pairing code and ids every run.
    simulatorLinkProvider.overrideWith((ref) {
      final link = SimulatorLink(random: Random(7));
      ref.onDispose(link.dispose);
      return link;
    }),
  ],
);

Future<void> _pump(WidgetTester tester, [Duration total = const Duration(seconds: 1)]) async {
  for (var t = Duration.zero; t < total; t += const Duration(milliseconds: 100)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _phone(WidgetTester tester, Brightness brightness) {
  tester.view
    ..physicalSize = const Size(780, 1688)
    ..devicePixelRatio = 2;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

/// Times on screen ("9:41 AM") must not depend on when the test runs: the
/// clock starts at 9:41 and moves with the test's fake time.
Future<void> _at941(WidgetTester tester, Future<void> Function() body) {
  _tester = tester;
  final start = tester.binding.clock.now();
  final base = DateTime(2026, 10, 6, 9, 41);
  return withClock(Clock(() => base.add(tester.binding.clock.now().difference(start))), body);
}

/// Snapshots the screen once every image on it has decoded (image loading
/// is real I/O, which fake time alone never finishes).
Future<void> _golden(String name) async {
  final tester = _tester!;
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
  await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('$name.png'));
}

WidgetTester? _tester;

/// Times render in the local timezone; baselines are made in UTC, as CI
/// runs. Elsewhere: `TZ=UTC flutter test --tags golden`.
final _utc = DateTime.now().timeZoneOffset == Duration.zero;

void main() {
  if (!_utc) {
    test('goldens', () {}, skip: 'Run goldens in UTC, as CI does: TZ=UTC flutter test --tags golden');
    return;
  }
  setUpAll(loadGoldenFonts);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  for (final brightness in Brightness.values) {
    final b = brightness.name;

    testWidgets('the list, the add-an-Octo sheets and a thread ($b)', (tester) => _at941(tester, () async {
      _phone(tester, brightness);
      await tester.pumpWidget(_app());
      await _pump(tester);
      await _golden('list_empty_$b');

      await tester.tap(find.byTooltip('Add an Octo').first);
      await _pump(tester);
      await tester.tap(find.text('Use a simulated computer'));
      await _pump(tester);
      await _golden('pair_compare_$b');

      await tester.tap(find.text('They match'));
      await _pump(tester);
      await _golden('pair_waiting_$b');

      await _pump(tester, const Duration(seconds: 4));
      await _golden('pair_name_$b');
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await _pump(tester);
      await _golden('pair_look_$b');
      await tester.ensureVisible(find.text('Done'));
      await tester.tap(find.text('Done'));
      await _pump(tester, const Duration(seconds: 2));

      await tester.enterText(find.byType(TextField), "Join the Discord call from Priya's invite");
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await _pump(tester, const Duration(seconds: 6));
      await _golden('thread_working_$b');

      await _pump(tester, const Duration(seconds: 6));
      await tester.pageBack();
      await _pump(tester);
      await _golden('list_one_$b');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 10));
    }));

    testWidgets('every bubble kind ($b)', (tester) async {
      _tester = tester;
      tester.view
        ..physicalSize = const Size(780, 6400)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(galleryHost(galleryThread(), brightness: brightness));
      await tester.pump(const Duration(milliseconds: 100));
      await _golden('bubbles_$b');
    });
  }
}
