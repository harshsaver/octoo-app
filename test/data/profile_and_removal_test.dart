import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/data/backend/octo_backend.dart';
import 'package:octo_family/data/db/database.dart';
import 'package:octo_family/data/profile_sync.dart';
import 'package:octo_family/data/screenshot_store.dart';
import 'package:octo_family/data/session/sessions_controller.dart';

import '../support/scripted_link.dart';

class _Harness {
  _Harness({this.role = 'owner'});

  final String role;
  final db = OctoDatabase(NativeDatabase.memory());
  final backend = FakeBackend();
  final link = ScriptedLink()..connected = true;
  final shots = ScreenshotStore(
    Directory.systemTemp.createTempSync('octo-pr-'),
  );
  late SessionsController sessions;
  late ProfileSync sync;

  Future<void> start({
    int profileGen = 0,
    int profileSyncedGen = 0,
    String backendPerson = 'Mom',
  }) async {
    await db.upsertComputer(
      ComputersCompanion.insert(
        id: 'c1',
        computerName: "Mom's laptop",
        person: 'Mom',
        role: Value(role),
        addedAt: 1,
        profileGen: Value(profileGen),
        profileSyncedGen: Value(profileSyncedGen),
      ),
    );
    await backend.patchComputer(
      'c1',
      name: "Mom's laptop",
      person: backendPerson,
      language: 'en',
    );
    sessions = SessionsController(
      db: db,
      link: link,
      store: DriftSessionStore(db),
      shots: shots,
      backend: backend,
      requestTimeout: const Duration(milliseconds: 200),
    );
    sync = ProfileSync(db: db, backend: backend, sessionFor: sessions.session);
    sessions.addConnectedListener((id) => sync.sync(id));
    await sessions.start();
    await _settle();
  }

  Future<ComputerRow> row() async => (await db.computer('c1'))!;

  List<Map<String, Object?>> get profileSets => link.sentOfType('profile.set');

  Future<void> close() async {
    await sessions.dispose();
    await db.close();
  }
}

Future<void> _settle([int ms = 300]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  group('profile sync', () {
    test('a crash right after the PATCH still leaves the sync owed', () async {
      // The edit bumped the generation and the PATCH succeeded, then the app
      // died before her computer heard about it.
      final h = _Harness();
      h.link.answerRequests();
      await h.start(profileGen: 1, backendPerson: 'Ma');
      await h.sync.sync('c1');
      expect(h.profileSets.last['person'], 'Ma', reason: "the backend's value");
      expect((await h.row()).profileSyncedGen, 1);
      await h.close();
    });

    test(
      "another helper's newer value on the backend wins over a stale local one",
      () async {
        final h = _Harness();
        h.link.answerRequests();
        await h.start();
        await h.sync.edit('c1', person: 'Mom');
        await _settle();
        // Priya renames her from her phone.
        await h.backend.patchComputer('c1', person: 'Mummy');
        await h.db.updateComputer(
          'c1',
          const ComputersCompanion(profileGen: Value(5)),
        );
        await h.sync.sync('c1');
        expect(h.profileSets.last['person'], 'Mummy');
        await h.close();
      },
    );

    test('no result (lost or timed out) keeps the sync owed; it runs on the next connect', () async {
      final h = _Harness();
      h.link.answerRequests(profileOk: null);
      await h.start();
      await h.sync.edit('c1', person: 'Ma');
      await _settle(600);
      var row = await h.row();
      expect(row.profileGen, 1);
      expect(row.profileSyncedGen, 0);
      expect(h.profileSets, isNotEmpty);

      h.link.answerRequests();
      h.link.goOffline();
      await _settle();
      h.link.goOnline();
      await _settle(600);
      row = await h.row();
      expect(row.profileSyncedGen, 1);
      await h.close();
    });

    test('an edit made during a sync re-runs it and is not cleared by the older sync', () async {
      final h = _Harness();
      var first = true;
      h.link.answerRequests();
      final answer = h.link.onSend!;
      h.link.onSend = (m) {
        if (m['type'] == 'profile.set' && first) {
          first = false;
          // While her computer works on generation 1, a second edit lands.
          h.sync.edit('c1', person: 'Mummy');
          Future<void>.delayed(
            const Duration(milliseconds: 50),
            () => answer(m),
          );
          return;
        }
        answer(m);
      };
      await h.start();
      await h.sync.edit('c1', person: 'Ma');
      await _settle(800);
      final row = await h.row();
      expect(row.profileGen, 2);
      expect(row.profileSyncedGen, 2);
      expect(h.profileSets.last['person'], 'Mummy');
      await h.close();
    });

    test('a failed PATCH changes nothing local', () async {
      final h = _Harness();
      h.link.answerRequests();
      await h.start();
      h.backend.failNext = const BackendException(
        'rate_limited',
        'Try again in a minute.',
      );
      await expectLater(
        h.sync.edit('c1', person: 'Ma'),
        throwsA(isA<BackendException>()),
      );
      expect((await h.row()).person, 'Mom');
      await h.close();
    });
  });

  group('removal', () {
    test('owner: a failed DELETE leaves the Octo fully usable', () async {
      final h = _Harness();
      h.link.answerRequests();
      await h.start();
      h.backend.failNext = const BackendException(
        'failed',
        'Something went wrong.',
      );
      await expectLater(
        h.sessions.remove('c1'),
        throwsA(isA<BackendException>()),
      );
      final row = await h.row();
      expect(row.tombstone, isFalse);
      expect(h.sessions.session('c1'), isNotNull);
      expect(h.link.unpaired, isEmpty);
      await h.close();
    });

    test('helper: a tombstone survives a failed unpair and a restart, until unpair succeeds', () async {
      final h = _Harness(role: 'helper');
      h.link.answerRequests();
      await h.start();
      h.link.unpairError = StateError('relay unreachable');
      await h.sessions.remove('c1');
      final row = await h.row();
      expect(row.tombstone, isTrue, reason: 'hidden, but kept');
      expect(h.link.sentOfType('leave'), isNotEmpty);

      // Restart: a new controller finds the tombstone and retries.
      await h.sessions.dispose();
      h.sessions = SessionsController(
        db: h.db,
        link: h.link,
        store: DriftSessionStore(h.db),
        shots: h.shots,
        backend: h.backend,
      );
      await h.sessions.start();
      await _settle();
      expect(
        await h.db.computer('c1'),
        isNotNull,
        reason: 'unpair still failing',
      );

      h.link.unpairError = null;
      h.sessions.resume();
      await _settle();
      expect(await h.db.computer('c1'), isNull, reason: 'purged after unpair');
      expect(h.link.unpaired, ['c1']);
      expect(await h.sessions.hasPendingRemovals(), isFalse);
      await h.close();
    });
  });
}
