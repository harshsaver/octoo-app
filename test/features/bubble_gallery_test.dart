import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/app/providers.dart';
import 'package:octo_family/data/outbox.dart';
import 'package:octo_family/data/screenshot_store.dart';
import 'package:octo_family/data/session/reducer.dart';
import 'package:octo_family/data/session/session_data.dart';
import 'package:octo_family/data/thread/projection.dart';
import 'package:octo_family/features/thread/thread_bubbles.dart';
import 'package:octo_family/l10n/app_localizations.dart';
import 'package:octo_family/protocol/host_message.dart';
import 'package:octo_family/protocol/models/entry.dart';
import 'package:octo_family/protocol/models/task.dart';
import 'package:octo_family/protocol/models/todo.dart';
import 'package:octo_family/ui/theme.dart';

class _QuietShots extends ScreenshotStore {
  _QuietShots() : super(Directory('/nonexistent'));
}

const _endings = {
  'done': "Joined. She's in the call.",
  'gaveUp': null,
  'blocked': null,
  'refused': null,
  'declined': null,
  'noAnswer': null,
  'stopped': 'Stopped by Priya.',
  'failed': null,
  'paused': null, // a status this version doesn't know
};

/// Every bubble kind (brief §5.4), each end status, and an unknown status.
SessionData _gallery() {
  var at = 1000;
  Task task(
    String id,
    String status, {
    String? result,
    String? from,
    String? fromName,
  }) => Task(
    id: id,
    text: 'Task $id',
    status: status,
    from: from,
    fromName: fromName,
    say: status == 'running' ? 'Opening the invite' : null,
    steps: status == 'running' ? const [TaskStep(n: 1)] : const [],
    result: result,
    createdAt: at += 60000,
    startedAt: at + 1000,
  );
  final events = <SessionEvent>[
    const NoteAdded(id: 'welcome', at: 1000, text: "Hi Harsh! I'm Mom's Octo."),
    LogReceived([
      Entry(
        at: at += 1000,
        kind: 'pairing',
        by: 'Mom',
        text: "Harsh's iPhone was added",
      ),
    ]),
    OutboxUpserted(
      OutboxRow(
        id: 'o-pending',
        computerId: 'c1',
        kind: OutboxKind.task,
        payload: const {'text': 'Check the printer'},
        state: OutboxState.pending,
        createdAt: at += 60000,
        updatedAt: at,
      ),
    ),
    OutboxUpserted(
      OutboxRow(
        id: 'o-uncertain',
        computerId: 'c1',
        kind: OutboxKind.task,
        payload: const {'text': 'Install Zoom'},
        state: OutboxState.uncertain,
        createdAt: at += 60000,
        updatedAt: at,
      ),
    ),
    OutboxUpserted(
      OutboxRow(
        id: 'o-msg',
        computerId: 'c1',
        kind: OutboxKind.message,
        payload: const {'text': 'Calling you in 5 minutes!'},
        state: OutboxState.sent,
        createdAt: at += 60000,
        updatedAt: at,
      ),
    ),
    TaskReceived(task('q', 'queued'), null),
    TaskReceived(task('w', 'waitingOk'), null),
    TaskReceived(task('r', 'running'), null),
    TaskReceived(task('p', 'running', from: 'u_p', fromName: 'Priya'), null),
    for (final MapEntry(:key, :value) in _endings.entries)
      TaskReceived(
        task('e-$key', key, result: value),
        key == 'done' ? const HostShot() : null,
      ),
    TodoReceived(
      Todo(
        id: 'd1',
        at: at += 60000,
        text: 'Is this email real?',
        answer: 'It looks like a scam.',
      ),
      const UnavailableShot(),
    ),
    HelpReceived(at += 60000, "The printer isn't working"),
    OutboxUpserted(
      OutboxRow(
        id: 'o-screen',
        computerId: 'c1',
        kind: OutboxKind.screenRequest,
        payload: const {},
        state: OutboxState.sent,
        createdAt: at += 60000,
        updatedAt: at,
      ),
    ),
    ScreenReceived(
      ScreenMessage(ok: false, at: at += 1000, reason: 'She said no.'),
      null,
      at,
    ),
  ];
  return events.fold(const SessionData(computerId: 'c1'), reduce);
}

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    ProviderScope(
      overrides: [screenshotStoreProvider.overrideWith((ref) => _QuietShots())],
      child: MaterialApp(
        theme: brightness == Brightness.light
            ? octoLightTheme()
            : octoDarkTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

Widget _thread() {
  final entries = projectThread(_gallery(), const MeIdentity(name: 'Harsh'));
  return ListView(
    children: [
      for (final e in entries)
        ThreadEntryView(
          entry: e,
          person: 'Mom',
          actions: ThreadActions(
            tryAgain: (_) {},
            stop: (_) {},
            details: (_) {},
            reply: (_) {},
            doIt: (_) {},
            seeScreen: () {},
          ),
        ),
    ],
  );
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'every bubble kind and end status renders (${brightness.name})',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 12000);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_host(_thread(), brightness: brightness));
        await tester.pump(const Duration(milliseconds: 100));

        // Requests and their states.
        expect(find.text('Not sent yet'), findsOneWidget);
        expect(
          find.textContaining("Couldn't confirm it reached Mom's computer"),
          findsOneWidget,
        );
        expect(find.text('Try again'), findsOneWidget);
        expect(find.text('Waiting its turn'), findsOneWidget);
        expect(find.text('Waiting for Mom to say OK'), findsOneWidget);
        expect(find.text('Priya → Octo'), findsOneWidget);
        // The live bubble.
        expect(find.text('Opening the invite'), findsNWidgets(2));
        expect(find.text('Stop'), findsNWidgets(2));
        // Each end, in plain sentences; never "done" for an unknown status.
        expect(find.text("Joined. She's in the call."), findsOneWidget);
        expect(
          find.text("I couldn't finish this. It's back with you."),
          findsOneWidget,
        );
        expect(
          find.text('I stopped because of a safety rule.'),
          findsOneWidget,
        );
        expect(find.text("Your rules don't allow this."), findsOneWidget);
        expect(find.text('Mom said no.'), findsOneWidget);
        expect(find.text("Mom didn't answer."), findsOneWidget);
        expect(find.text('Stopped by Priya.'), findsOneWidget);
        expect(find.text("That didn't work."), findsOneWidget);
        expect(
          find.text(
            "Octo sent an update this app can't show yet. Update the app.",
          ),
          findsOneWidget,
        );
        // Screenshots that can't be shown say so.
        expect(find.text('Screenshot on her computer'), findsOneWidget);
        expect(find.text('Screenshot no longer available'), findsOneWidget);
        // From Mom.
        expect(find.text('Is this email real?'), findsOneWidget);
        expect(
          find.text('Octo told her: It looks like a scam.'),
          findsOneWidget,
        );
        expect(find.text('Reply'), findsOneWidget);
        expect(find.text('Octo, do it'), findsOneWidget);
        expect(find.textContaining('Can you take a look?'), findsOneWidget);
        expect(find.text('See her screen'), findsOneWidget);
        // Centre lines.
        expect(find.text('Asked Mom to show her screen'), findsOneWidget);
        expect(find.text('Mom said no to showing her screen'), findsOneWidget);
        expect(find.text("Harsh's iPhone was added"), findsOneWidget);
        // Tell Mom.
        expect(find.text('Calling you in 5 minutes!'), findsOneWidget);

        final handle = tester.ensureSemantics();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        expect(
          find.bySemanticsLabel(
            RegExp(r"^Octo, .*: Joined\. She's in the call\.$"),
          ),
          findsOneWidget,
          reason: 'screen-reader label on every bubble',
        );
        handle.dispose();
      },
    );
  }

  testWidgets('the thread at the largest text size', (tester) async {
    tester.view.physicalSize = const Size(1080, 40000);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_host(_thread()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
