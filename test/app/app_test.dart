import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/app/app.dart';
import 'package:octo_family/app/config.dart';
import 'package:octo_family/app/providers.dart';
import 'package:octo_family/data/account_scope.dart';
import 'package:octo_family/data/db/database.dart';
import 'package:octo_family/data/screenshot_store.dart';

/// No file I/O in widget tests (it never completes under fake time).
class _QuietShots extends ScreenshotStore {
  _QuietShots() : super(Directory('/nonexistent'));

  @override
  Future<void> purgeExpired() async {}
}

final _dirs = AccountDirs(
  support: Directory('/nonexistent/s'),
  cache: Directory('/nonexistent/c'),
);

Widget _app() => buildApp(
  ConfigOk(AppConfig.fake),
  dirs: _dirs,
  overrides: [
    databaseProvider.overrideWith((ref) {
      final db = OctoDatabase(NativeDatabase.memory());
      ref.onDispose(db.close);
      return db;
    }),
    screenshotStoreProvider.overrideWith((ref) => _QuietShots()),
    cameraAvailableProvider.overrideWithValue(false),
  ],
);

Future<void> _pump(
  WidgetTester tester, [
  Duration total = const Duration(seconds: 1),
]) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

/// Unmounts the app and lets the simulator's short timers run out.
Future<void> _tearDown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 10));
}

Future<void> _checkAccessibility(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}

void main() {
  testWidgets('a missing config shows "This build isn\'t configured"', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(parseConfig({}, isRelease: false), dirs: _dirs),
    );
    await tester.pumpAndSettle();
    expect(find.text("This build isn't configured"), findsOneWidget);
    await _checkAccessibility(tester);
  });

  testWidgets('a release build that reaches fake mode refuses to run', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        parseConfig({'OCTO_MODE': 'fake'}, isRelease: true),
        dirs: _dirs,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("This build isn't configured"), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('the empty Octos list (${brightness.name})', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(_app());
      await _pump(tester);
      expect(find.text('Octos'), findsWidgets);
      expect(find.text('Add your first Octo'), findsOneWidget);
      expect(
        find.text(
          'Open Octo on the family computer and choose Add a family member.',
        ),
        findsOneWidget,
      );
      await _checkAccessibility(tester);
      await _tearDown(tester);
    });
  }

  testWidgets('the largest text size still lays out', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app());
    await _pump(tester);
    expect(tester.takeException(), isNull);
    await _tearDown(tester);
  });

  testWidgets('add an Octo, ask it something, watch it work, see the result', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _pump(tester);

    // + opens the add flow.
    await tester.tap(find.byTooltip('Add an Octo').first);
    await _pump(tester);
    expect(find.text('Type the code instead'), findsOneWidget);
    expect(
      find.text(
        "Only add a family member's computer while you're with them, or on a call with them.",
      ),
      findsOneWidget,
    );

    // Pair with a simulated computer.
    await tester.tap(find.text('Use a simulated computer'));
    await _pump(tester);
    expect(
      find.text(
        "Mom's laptop shows the same key. Check they match, and ask them to tap OK.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('They match'));
    await _pump(tester);
    expect(
      find.text("Waiting for someone to tap OK on Mom's laptop…"),
      findsOneWidget,
    );
    await _pump(tester, const Duration(seconds: 4));

    // Name it, pick a look.
    expect(find.text('Who is it for?'), findsOneWidget);
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await _pump(tester);
    expect(find.text('Pick their Octo'), findsOneWidget);
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await _pump(tester, const Duration(seconds: 2));

    // The thread opens with Octo's welcome.
    expect(find.textContaining("Hi Harsh! I'm Mom's Octo."), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text("Harsh's Android phone was added"), findsOneWidget);

    // Ask Octo.
    await tester.enterText(
      find.byType(TextField),
      "Join the Discord call from Priya's invite",
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await _pump(tester);
    expect(find.text('Waiting for Mom to say OK'), findsOneWidget);

    await _pump(tester, const Duration(seconds: 4));
    expect(find.text('Mom said OK'), findsOneWidget);
    expect(find.text('Working…'), findsOneWidget);
    expect(find.textContaining('Step '), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);

    await _pump(tester, const Duration(seconds: 6));
    expect(find.text("Joined. She's in the call."), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    await _checkAccessibility(tester);

    // Back to the list: the row shows the result.
    await tester.pageBack();
    await _pump(tester);
    expect(find.text('Mom'), findsOneWidget);
    expect(find.text("Joined. She's in the call."), findsOneWidget);

    await _tearDown(tester);
  });
}
