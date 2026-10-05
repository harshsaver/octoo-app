import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:octo_family/app/app.dart';
import 'package:octo_family/app/app_settings.dart';
import 'package:octo_family/app/config.dart';
import 'package:octo_family/app/providers.dart';
import 'package:octo_family/data/account_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On a device or emulator, against the simulator (PLAN §5): pair → task →
/// her OK → steps → result, with the real database and screenshot store.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  testWidgets('pair, ask Octo, she says OK, watch the steps, get the result', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync('octo-it-');
    addTearDown(() => root.deleteSync(recursive: true));
    await tester.pumpWidget(
      buildApp(
        ConfigOk(AppConfig.fake),
        roots: AppRoots(
          support: Directory('${root.path}/support'),
          cache: Directory('${root.path}/cache'),
        ),
        overrides: [
          cameraAvailableProvider.overrideWithValue(false),
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
      ),
    );

    await waitFor(tester, find.text('Add your first Octo'));
    await tester.tap(find.byTooltip('Add an Octo').first);
    await waitFor(tester, find.text('Use a simulated computer'));
    await tester.tap(find.text('Use a simulated computer'));

    await waitFor(tester, find.text('They match'));
    await tester.tap(find.text('They match'));
    await waitFor(tester, find.text('Who is it for?'));
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await waitFor(tester, find.text('Pick their Octo'));
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));

    await waitFor(tester, find.textContaining("Hi Harsh! I'm Mom's Octo."));
    await waitFor(tester, find.text('Online'));
    await tester.enterText(
      find.byType(TextField),
      "Join the Discord call from Priya's invite",
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));

    await waitFor(tester, find.text('Waiting for Mom to say OK'));
    await waitFor(tester, find.text('Mom said OK'));
    await waitFor(tester, find.text('Working…'));
    await waitFor(tester, find.textContaining('Step '));
    await waitFor(tester, find.text("Joined. She's in the call."));
    // The final screenshot is written to the app-private store and shown.
    await waitFor(tester, find.bySemanticsLabel('Screenshot from Octo'));
  });
}
