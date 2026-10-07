import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:octo_family/app/app.dart';
import 'package:octo_family/app/app_settings.dart';
import 'package:octo_family/app/config.dart';
import 'package:octo_family/app/providers.dart';
import 'package:octo_family/data/account_scope.dart';
import 'package:octo_family/data/db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/scripted_link.dart';

/// PLAN §5 performance, in a profile build on a device:
///   flutter drive --profile --no-dds --driver=test_driver/perf_driver.dart \
///     --target=integration_test/perf_test.dart
/// Reports the time to the list and the frame times while 50 steps of a
/// task stream into an open thread (build/steps.timeline_summary.json).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) throw TestFailure('Timed out waiting for $finder');
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('the list, then 50 steps streaming into a thread', (tester) async {
    final root = Directory.systemTemp.createTempSync('octo-perf-');
    addTearDown(() => root.deleteSync(recursive: true));
    final link = ScriptedLink()
      ..connected = true
      ..answerRequests();

    final start = Stopwatch()..start();
    await tester.pumpWidget(
      buildApp(
        ConfigOk(AppConfig.fake),
        roots: AppRoots(support: Directory('${root.path}/s'), cache: Directory('${root.path}/c')),
        overrides: [
          octoLinkProvider.overrideWithValue(link),
          cameraAvailableProvider.overrideWithValue(false),
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        ],
      ),
    );
    await waitFor(tester, find.text('Octos'));
    binding.reportData = {'list_ms': start.elapsedMilliseconds};

    final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));
    final now = DateTime.now().millisecondsSinceEpoch;
    await container.read(databaseProvider).upsertComputer(
      ComputersCompanion.insert(
        id: 'c1',
        computerName: "Mom's laptop",
        person: 'Mom',
        role: const Value('direct'),
        addedAt: now,
      ),
    );
    await waitFor(tester, find.text('Mom'));
    await tester.tap(find.text('Mom'));
    await waitFor(tester, find.text('Ask Octo'));

    Map<String, Object?> task(int steps, String status) => {
      'type': 'task',
      'task': {
        'id': 't_perf',
        'text': 'Clean up the desktop and sort the downloads',
        'from': 'u_me',
        'fromName': 'Harsh',
        'status': status,
        'createdAt': now,
        'startedAt': now,
        'say': status == 'running' ? 'Moving file $steps of 50' : null,
        'steps': [
          for (var n = 1; n <= steps; n++)
            {'n': n, 'at': now + n * 1000, 'say': 'Moving file $n of 50', 'did': 'Moved report-$n.pdf', 'ok': true},
        ],
        if (status == 'done') 'result': 'Sorted 50 files into Documents.',
      },
    };

    await binding.traceAction(() async {
      for (var n = 1; n <= 50; n++) {
        link.push(task(n, 'running'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      link.push(task(50, 'done'));
      await Future<void>.delayed(const Duration(seconds: 1));
    }, reportKey: 'steps_timeline');
    expect(find.text('Sorted 50 files into Documents.'), findsOneWidget);
  });
}
