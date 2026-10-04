import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/data/db/database.dart';
import 'package:octo_family/data/outbox.dart';
import 'package:octo_family/data/screenshot_store.dart';
import 'package:octo_family/data/session/reducer.dart';
import 'package:octo_family/data/session/session_data.dart';
import 'package:octo_family/data/session/session_store.dart';
import 'package:octo_family/protocol/models/screenshot.dart';
import 'package:octo_family/protocol/models/task.dart';
import 'package:octo_family/transport/simulator/sample_screen.dart';

void main() {
  group('drift store', () {
    late OctoDatabase db;
    setUp(() => db = OctoDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test(
      'a session round-trips through the database without screenshot bytes',
      () async {
        final store = DriftSessionStore(db);
        final task = Task.fromJson(
          jsonDecode(
            jsonEncode({
              'id': 't1',
              'text': 'Check the Wi-Fi',
              'status': 'done',
              'createdAt': 1000,
              'screenshot': sampleScreenDataUri,
              'mood': 'kept',
            }),
          ) as Map<String, Object?>,
        );
        var data = const SessionData(computerId: 'c1');
        for (final e in [
          TaskReceived(task, const LocalShot('abc')),
          const HelpReceived(2000, 'Printer'),
          OutboxUpserted(
            const OutboxRow(
              id: 'o1',
              computerId: 'c1',
              kind: OutboxKind.task,
              payload: {'text': 'Check the Wi-Fi'},
              state: OutboxState.accepted,
              taskId: 't1',
              createdAt: 900,
              updatedAt: 900,
            ),
          ),
          const LogReceived([], cursor: 77, incomplete: true),
        ]) {
          final next = reduce(data, e);
          await store.write(diffSession(data, next));
          data = next;
        }

        final rows = await db.select(db.records).get();
        expect(
          rows.map((r) => r.json).where((j) => j.contains('base64')),
          isEmpty,
        );

        final loaded = hydrate('c1', await store.load('c1'));
        expect(loaded.tasks['t1']!.task.status, 'done');
        expect(loaded.tasks['t1']!.task.raw['mood'], 'kept');
        expect(loaded.tasks['t1']!.shot, const LocalShot('abc'));
        expect(loaded.helps.values.single.text, 'Printer');
        expect(loaded.outbox['o1']!.state, OutboxState.accepted);
        expect(loaded.myHelperId, isNull);
        expect(loaded.logCursor, 77);
        expect(loaded.logMayBeIncomplete, isTrue);
        expect(loaded.nextOrder, greaterThan(loaded.tasks['t1']!.order));

        // Upserts are idempotent.
        await store.write(
          diffSession(const SessionData(computerId: 'c1'), data),
        );
        expect(await db.select(db.records).get(), hasLength(rows.length));

        await db.deleteComputer('c1');
        final purged = await store.load('c1');
        expect(purged.records, isEmpty);
        expect(purged.outbox, isEmpty);
      },
    );
  });

  group('screenshot store', () {
    late Directory dir;
    late ScreenshotStore store;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('octo-shots-');
      store = ScreenshotStore(Directory('${dir.path}/u1/screenshots'));
    });
    tearDown(() => dir.deleteSync(recursive: true));

    final inline = WireScreenshot.fromWire(sampleScreenDataUri);

    test('writes atomically and serves until expiry', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final ref = store.accept(inline, at: now, computerId: 'c1') as LocalShot;
      expect(store.status(ref.id), ShotStatus.writing);
      await store.flush();
      expect(store.fileFor(ref.id)!.existsSync(), isTrue);
      expect(
        Directory('${dir.path}/u1/screenshots')
            .listSync()
            .where((f) => f.path.endsWith('.tmp')),
        isEmpty,
      );

      // The same screenshot again keeps its first expiry.
      expect(store.accept(inline, at: now + 1000, computerId: 'c1'), ref);

      await withClock(
        Clock.fixed(
          DateTime.fromMillisecondsSinceEpoch(now).add(const Duration(days: 8)),
        ),
        () async {
          expect(
            store.fileFor(ref.id),
            isNull,
            reason: 'never shown after expiry',
          );
          await store.purgeExpired();
        },
      );
      expect(
        Directory('${dir.path}/u1/screenshots').listSync(),
        isEmpty,
        reason: 'deleted on purge',
      );
    });

    test(
      'expired history is never written; host paths and rejects are not files',
      () async {
        final old = DateTime.now()
            .subtract(const Duration(days: 8))
            .millisecondsSinceEpoch;
        expect(
          store.accept(inline, at: old, computerId: 'c1'),
          const UnavailableShot(),
        );
        expect(
          store.accept(
            const HostPathScreenshot(r'C:\x.png'),
            at: old,
            computerId: 'c1',
          ),
          const HostShot(),
        );
        expect(
          store.accept(
            const RejectedScreenshot(ScreenshotRejection.tooLarge),
            at: old,
            computerId: 'c1',
          ),
          const UnavailableShot(),
        );
        await store.flush();
        expect(Directory('${dir.path}/u1/screenshots').existsSync(), isFalse);
      },
    );

    test('a restart finds existing files', () async {
      final ref = store.accept(
        inline,
        at: DateTime.now().millisecondsSinceEpoch,
        computerId: 'c1',
      ) as LocalShot;
      await store.flush();
      final again = ScreenshotStore(Directory('${dir.path}/u1/screenshots'));
      expect(again.fileFor(ref.id), isNull);
      await again.purgeExpired();
      expect(again.fileFor(ref.id), isNotNull);
    });
  });
}
