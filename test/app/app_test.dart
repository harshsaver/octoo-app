import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/app/app.dart';
import 'package:octo_family/app/app_settings.dart';
import 'package:octo_family/app/config.dart';
import 'package:octo_family/app/providers.dart';
import 'package:octo_family/data/account_scope.dart';
import 'package:octo_family/data/auth/auth_service.dart';
import 'package:octo_family/data/push/push_service.dart';
import 'package:octo_family/data/db/database.dart';
import 'package:octo_family/data/screenshot_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// No file I/O in widget tests (it never completes under fake time).
class _QuietShots extends ScreenshotStore {
  _QuietShots() : super(Directory('/nonexistent'));

  @override
  Future<void> purgeExpired() async {}
}

final _roots = AppRoots(
  support: Directory('/nonexistent/s'),
  cache: Directory('/nonexistent/c'),
);

late SharedPreferences _prefs;

Widget _app({AuthService? auth, PushService? push}) => buildApp(
  ConfigOk(AppConfig.fake),
  roots: _roots,
  overrides: [
    if (auth != null) authServiceProvider.overrideWithValue(auth),
    if (push != null) pushServiceProvider.overrideWithValue(push),
    databaseProvider.overrideWith((ref) {
      final db = OctoDatabase(NativeDatabase.memory());
      ref.onDispose(db.close);
      return db;
    }),
    screenshotStoreProvider.overrideWith((ref) => _QuietShots()),
    cameraAvailableProvider.overrideWithValue(false),
    sharedPreferencesProvider.overrideWithValue(_prefs),
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('a missing config shows "This build isn\'t configured"', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(parseConfig({}, isRelease: false), roots: _roots),
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
        roots: _roots,
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
          'Open October on the family computer, go to Settings, then Phone access, and choose Add a phone.',
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

  stage3Tests();
  stage4Tests();
}

/// Adds a simulated computer through the UI and lands in its thread.
Future<void> _addOcto(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Add an Octo').first);
  await _pump(tester);
  await tester.tap(find.text('Use a simulated computer'));
  await _pump(tester);
  await tester.tap(find.text('They match'));
  await _pump(tester, const Duration(seconds: 4));
  await tester.ensureVisible(find.text('Next'));
  await tester.tap(find.text('Next'));
  await _pump(tester);
  await tester.ensureVisible(find.text('Done'));
  await tester.tap(find.text('Done'));
  await _pump(tester, const Duration(seconds: 2));
}

void stage3Tests() {
  testWidgets('Details: rename, rules, activity', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await _pump(tester);
    await _addOcto(tester);

    // The header opens Details.
    await tester.tap(find.text('Mom').first);
    await _pump(tester);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Change Octo'), findsOneWidget);
    expect(find.text('Harsh (you)'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget, reason: 'this month');

    // Rename her: PATCH, then her computer is updated.
    await tester.tap(find.text('Name'));
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'Ma');
    await tester.tap(find.text('Save'));
    await _pump(tester, const Duration(seconds: 2));
    expect(find.text('Ma'), findsWidgets);
    expect(
      find.text("Ma's computer will update when it's back."),
      findsNothing,
      reason: 'online: synced at once',
    );

    // Rules: a tightening change is applied by her computer.
    await tester.tap(find.text('Rules'));
    await _pump(tester);
    final looking = find.widgetWithText(
      SwitchListTile,
      'Ask before looking at the screen',
    );
    expect(tester.widget<SwitchListTile>(looking).value, isFalse);
    await tester.tap(looking);
    await tester.pump();
    expect(find.text('Applying change'), findsOneWidget);
    await _pump(tester, const Duration(seconds: 2));
    expect(find.text('Applying change'), findsNothing);
    expect(tester.widget<SwitchListTile>(looking).value, isTrue);

    // Loosening waits for her.
    final installs = find.widgetWithText(SwitchListTile, 'Install apps');
    await tester.ensureVisible(installs);
    await tester.tap(installs);
    await _pump(tester, const Duration(seconds: 1));
    expect(tester.widget<SwitchListTile>(installs).value, isTrue);
    await tester.tap(installs);
    await tester.pump();
    expect(find.text('Waiting for Ma to approve'), findsOneWidget);
    await _pump(tester, const Duration(seconds: 4)); // autopilot: she says OK
    expect(find.text('Waiting for Ma to approve'), findsNothing);
    expect(tester.widget<SwitchListTile>(installs).value, isFalse);

    // Activity lists what happened, by day.
    await tester.pageBack();
    await _pump(tester);
    await tester.tap(find.text('Activity'));
    await _pump(tester, const Duration(seconds: 1));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    await _tearDown(tester);
  });

  testWidgets('Settings: appearance and the developer toggle', (tester) async {
    await tester.pumpWidget(_app());
    await _pump(tester);
    expect(find.byTooltip('Play Mom (simulator)'), findsNothing);
    await tester.tap(find.byTooltip('Settings'));
    await _pump(tester);
    expect(
      find.text(
        'Simulated account. This copy plays the family computers itself.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Dark'));
    await _pump(tester);
    expect(
      Theme.of(tester.element(find.text('Settings').first)).brightness,
      Brightness.dark,
    );
    final dev = find.widgetWithText(SwitchListTile, 'Show simulator controls');
    await tester.scrollUntilVisible(dev, 200);
    await tester.tap(dev);
    await _pump(tester);
    await tester.pageBack();
    await _pump(tester);
    expect(find.byTooltip('Play Mom (simulator)'), findsOneWidget);
    await _checkAccessibility(tester);
    await _tearDown(tester);
  });
}

void stage4Tests() {
  testWidgets(
    'signed out: welcome, sign in with the email code, then the list',
    (tester) async {
      final auth = FakeAuth(signedIn: false);
      await tester.pumpWidget(_app(auth: auth));
      await _pump(tester);
      expect(
        find.text("Help your family's computers, from your phone"),
        findsOneWidget,
      );
      await _checkAccessibility(tester);

      await tester.tap(find.text('Sign in with October'));
      await _pump(tester);
      // Password comes first; the link is one tap away.
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      await tester.tap(find.text('Email me a link instead'));
      await _pump(tester);
      await tester.enterText(find.byType(TextField), 'harsh@example.com');
      await tester.tap(find.text('Email me a link'));
      await _pump(tester);
      expect(auth.sentLinks, ['harsh@example.com']);
      expect(
        find.textContaining('Check your email at harsh@example.com'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '000000');
      await tester.tap(find.text('Sign in'));
      await _pump(tester);
      expect(
        find.text("That code didn't work. Check the email and try again."),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Sign in'));
      await _pump(tester, const Duration(seconds: 2));
      expect(find.text('Add your first Octo'), findsOneWidget);
      await _tearDown(tester);
    },
  );

  testWidgets('sign in with email and password (shown first)', (tester) async {
    final auth = FakeAuth(signedIn: false);
    await tester.pumpWidget(_app(auth: auth));
    await _pump(tester);
    await tester.tap(find.text('Sign in with October'));
    await _pump(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'harsh@example.com',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await _pump(tester);
    expect(find.text("That email and password don't match."), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'octo-test',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await _pump(tester, const Duration(seconds: 2));
    expect(find.text('Add your first Octo'), findsOneWidget);
    await _tearDown(tester);
  });

  testWidgets('sign out from Settings returns to the welcome screen', (
    tester,
  ) async {
    final auth = FakeAuth();
    await tester.pumpWidget(_app(auth: auth));
    await _pump(tester);
    await tester.tap(find.byTooltip('Settings'));
    await _pump(tester);
    await tester.tap(find.text('Sign out'));
    await _pump(tester);
    expect(find.text('Sign out of Octo?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    // Sign-out deletes this account's files: real I/O needs real time.
    for (var i = 0; i < 10 && auth.current != null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _pump(tester, const Duration(seconds: 1));
    expect(auth.current, isNull);
    expect(find.text('Sign in with October'), findsOneWidget);
    await _tearDown(tester);
  });

  testWidgets('a tapped push opens that Octo; a foreground push is a banner', (
    tester,
  ) async {
    final push = NoPush();
    await tester.pumpWidget(_app(push: push));
    await _pump(tester);
    await _addOcto(tester);
    await tester.pageBack();
    await _pump(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(OctoApp)),
    );
    final id = container.read(computersProvider).value!.single.id;

    // While the app is open: an in-app banner with Open.
    push.deliver(
      PushMessage(computerId: id, kind: 'help', title: 'Mom needs a hand'),
    );
    await _pump(tester);
    expect(find.widgetWithText(SnackBar, 'Mom needs a hand'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await _pump(tester, const Duration(seconds: 2));
    expect(find.text('Ask Octo…'), findsOneWidget, reason: 'the thread');

    // A tap on a notification for a computer this phone doesn't know: the list.
    push.deliver(
      const PushMessage(computerId: 'c_unknown', kind: 'help'),
      tapped: true,
    );
    await _pump(tester, const Duration(seconds: 1));
    expect(find.text('Ask Octo…'), findsNothing);

    // A tap for a known one: its thread.
    push.deliver(PushMessage(computerId: id, kind: 'taskEnded'), tapped: true);
    await _pump(tester, const Duration(seconds: 1));
    expect(find.text('Ask Octo…'), findsOneWidget);

    // Muted: no banner.
    await container
        .read(databaseProvider)
        .updateComputer(id, const ComputersCompanion(muted: Value(true)));
    await _pump(tester);
    push.deliver(
      PushMessage(
        computerId: id,
        kind: 'todo',
        title: 'Mom sent you something',
      ),
    );
    await _pump(tester);
    expect(find.text('Mom sent you something'), findsNothing);
    await _tearDown(tester);
  });
}
