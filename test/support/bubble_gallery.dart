/// The bubble gallery (every bubble kind and end status) shared by the
/// gallery test and the goldens.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class QuietShots extends ScreenshotStore {
  QuietShots() : super(Directory('/nonexistent'));
}

const galleryEndings = {
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
SessionData gallerySession() {
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
    for (final MapEntry(:key, :value) in galleryEndings.entries)
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

Widget galleryHost(Widget child, {Brightness brightness = Brightness.light}) =>
    ProviderScope(
      overrides: [screenshotStoreProvider.overrideWith((ref) => QuietShots())],
      child: MaterialApp(
        theme: brightness == Brightness.light
            ? octoLightTheme()
            : octoDarkTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

Widget galleryThread() {
  final entries = projectThread(gallerySession(), const MeIdentity(name: 'Harsh'));
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

