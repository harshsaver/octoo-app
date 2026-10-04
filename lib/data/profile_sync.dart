import 'dart:async';

import 'package:drift/drift.dart' show Value;

import 'backend/octo_backend.dart';
import 'db/database.dart';
import 'session/computer_session.dart';

/// Keeps her computer's copy of the profile (her name, the computer's name,
/// her language) in step with the backend, which owns it (PLAN §3.5).
///
/// `profile.set` is never stored as a value to replay. Each computer keeps
/// two counters: `profileGen`, bumped and stored *before* each `PATCH`, and
/// `profileSyncedGen`, the newest generation her computer confirmed. A
/// single-flight loop per computer waits for any `PATCH`, captures the
/// generation, re-reads the backend's current profile, sends it, and records
/// the generation only on a correlated `result ok:true`. An edit that lands
/// meanwhile makes the loop run again, so an older sync never clears a newer
/// edit, and a stale local value never overwrites another helper's write.
class ProfileSync {
  ProfileSync({
    required this.db,
    required this.backend,
    required this.sessionFor,
  });

  final OctoDatabase db;
  final OctoBackend backend;
  final ComputerSession? Function(String computerId) sessionFor;

  final Map<String, Future<void>> _patches = {};
  final Map<String, Future<void>> _loops = {};
  final Set<String> _again = {};

  /// Changes the profile: `PATCH` first. If it fails this throws
  /// ([BackendException]) and nothing local changes; on success the row
  /// takes the backend's values and her computer is synced (now, or when
  /// it's back).
  Future<void> edit(
    String computerId, {
    String? person,
    String? computerName,
    String? language,
    String? look,
  }) async {
    final row = await db.computer(computerId);
    if (row == null) return;
    final touchesHer =
        person != null || computerName != null || language != null;
    if (touchesHer) {
      await db.updateComputer(
        computerId,
        ComputersCompanion(profileGen: Value(row.profileGen + 1)),
      );
    }
    final patch = backend.patchComputer(
      computerId,
      name: computerName,
      person: person,
      language: language,
      octo: look,
    );
    _patches[computerId] = patch.then((_) {}, onError: (Object _) {});
    final BackendComputer updated;
    try {
      updated = await patch;
    } finally {
      unawaited(_patches.remove(computerId));
    }
    await db.updateComputer(
      computerId,
      ComputersCompanion(
        person: updated.person.isEmpty
            ? const Value.absent()
            : Value(updated.person),
        computerName: updated.name.isEmpty
            ? const Value.absent()
            : Value(updated.name),
        language: Value(updated.language),
        look: updated.octo == null
            ? const Value.absent()
            : Value(updated.octo!),
      ),
    );
    if (touchesHer) unawaited(sync(computerId));
  }

  /// Syncs [computerId] if a sync is owed. Single-flight per computer.
  Future<void> sync(String computerId) {
    final running = _loops[computerId];
    if (running != null) {
      _again.add(computerId);
      return running;
    }
    // A block body: returning the removed future here would make the loop
    // wait for itself.
    final loop = _run(computerId).whenComplete(() {
      _loops.remove(computerId);
    });
    _loops[computerId] = loop;
    return loop;
  }

  Future<void> _run(String computerId) async {
    do {
      _again.remove(computerId);
      await _patches[computerId];
      final row = await db.computer(computerId);
      if (row == null || row.tombstone) return;
      final generation = row.profileGen;
      if (generation <= row.profileSyncedGen) return;
      final session = sessionFor(computerId);
      if (session == null || !session.isConnected) {
        return; // owed; retried on connect
      }

      final List<BackendComputer> listed;
      try {
        listed = await backend.listComputers();
      } on BackendException {
        return;
      }
      final canonical = listed.where((c) => c.id == computerId).firstOrNull;
      if (canonical == null) return;

      final ok = await session.sendProfile(
        person: canonical.person,
        computer: canonical.name,
        language: canonical.language,
      );
      if (!ok) return; // timeout, disconnect or refusal: still owed

      final now = await db.computer(computerId);
      if (now == null) return;
      if (generation > now.profileSyncedGen) {
        await db.updateComputer(
          computerId,
          ComputersCompanion(profileSyncedGen: Value(generation)),
        );
      }
      if (now.profileGen > generation) _again.add(computerId);
    } while (_again.contains(computerId));
  }
}
