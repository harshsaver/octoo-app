import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:octo_family/features/octos_list/octos_list_screen.dart';
import 'package:octo_family/app/app.dart';
import 'package:octo_family/app/app_settings.dart';
import 'package:octo_family/app/config.dart';
import 'package:octo_family/app/providers.dart';
import 'package:octo_family/data/account_scope.dart';
import 'package:octo_family/data/backend/octo_backend.dart';
import 'package:octo_family/data/db/database.dart';
import 'package:octo_family/data/screenshot_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QuietShots extends ScreenshotStore {
  _QuietShots() : super(Directory('/nonexistent'));

  @override
  Future<void> purgeExpired() async {}
}

void main() {
  late SharedPreferences prefs;
  late FakeBackend backend;
  late OctoDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    backend = FakeBackend();
    db = OctoDatabase(NativeDatabase.memory());
  });

  Widget app() => buildApp(
    ConfigOk(AppConfig.fake),
    roots: AppRoots(support: Directory('/nonexistent/s'), cache: Directory('/nonexistent/c')),
    overrides: [
      backendProvider.overrideWithValue(backend),
      databaseProvider.overrideWithValue(db),
      screenshotStoreProvider.overrideWith((ref) => _QuietShots()),
      cameraAvailableProvider.overrideWithValue(false),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a computer on the account with no keys on this phone offers "Pair again"', (tester) async {
    await backend.patchComputer('cmp_dad', name: "Dad's PC", person: 'Dad', octo: 'ocean-glasses');
    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.text('On your October account'), findsOneWidget);
    expect(find.text('Dad'), findsOneWidget);
    expect(find.text('Pair again on this phone'), findsOneWidget);
    // Not the empty state: there is something to do.
    expect(find.text('Add your first Octo'), findsNothing);

    await tester.tap(find.text('Pair again on this phone'));
    await settle(tester);
    expect(find.text('Type the code instead'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 10));
  });

  testWidgets('a computer this phone has (or is removing) is not offered again', (tester) async {
    await backend.patchComputer('cmp_mom', name: "Mom's laptop", person: 'Mom');
    await db.upsertComputer(ComputersCompanion.insert(id: 'cmp_mom', computerName: "Mom's laptop", person: 'Mom', addedAt: 0));
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.text('On your October account'), findsNothing);
    expect(find.text('Mom'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 10));
  });

  testWidgets('the backend unreachable: just the list, no error', (tester) async {
    backend.failNext = const BackendException('unavailable', 'Try again later.');
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.text('Add your first Octo'), findsOneWidget);
    expect(find.text('On your October account'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 10));
  });

  testWidgets('an octo.october.dev/add link opens pairing with its code', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    GoRouter.of(tester.element(find.byType(OctosListScreen))).go('/add#en_${'0' * 24}.${'s' * 43}');
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    // Straight into pairing with the simulated computer: the key to compare.
    expect(find.text('They match'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 10));
  });
}
