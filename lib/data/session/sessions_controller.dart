import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;

import '../../transport/octo_link.dart';
import '../backend/octo_backend.dart';
import '../db/database.dart';
import '../screenshot_store.dart';
import 'computer_session.dart';
import 'session_store.dart';

/// Owns one [ComputerSession] per computer for the whole app (PLAN §3.3).
/// Created once; independent of which screens are mounted, so list previews
/// stay live. Connects everything while the app is in the foreground and
/// disconnects in the background.
class SessionsController {
  SessionsController({
    required this.db,
    required this.link,
    required this.store,
    required this.shots,
    required this.backend,
  });

  final OctoDatabase db;
  final OctoLink link;
  final SessionStore store;
  final ScreenshotStore shots;
  final OctoBackend backend;

  final Map<String, ComputerSession> _sessions = {};
  Set<String> _listed = {};
  final Map<String, Future<ComputerSession>> _opening = {};
  final _changes = StreamController<void>.broadcast();
  final _banners = StreamController<String>.broadcast();
  final List<StreamSubscription<Object?>> _subs = [];
  bool _foreground = true;
  bool _disposed = false;

  /// Fires when sessions are added or removed.
  Stream<void> get changes => _changes.stream;

  /// One-time messages for the list ("Mom's computer removed you").
  Stream<String> get banners => _banners.stream;

  ComputerSession? session(String computerId) => _sessions[computerId];

  Future<void> start() async {
    await shots.purgeExpired();
    _subs.add(db.watchComputers().listen(_sync));
  }

  /// The session for a computer that was just added (before the watch fires).
  Future<ComputerSession> ensure(String computerId, {String? bind}) {
    final existing = _sessions[computerId];
    if (existing != null) return Future.value(existing);
    return _opening[computerId] ??= _open(computerId, bind);
  }

  void resume() {
    _foreground = true;
    unawaited(shots.purgeExpired());
    for (final s in _sessions.values) {
      s.connect();
    }
  }

  void pause() {
    _foreground = false;
    for (final s in _sessions.values) {
      unawaited(s.disconnect());
    }
  }

  /// Removes a computer from this phone: the backend first for an owner
  /// (on failure nothing changes), then `leave`, unpair and purge.
  /// Stage 3 adds the tombstone that retries an unpair that fails.
  Future<void> remove(String computerId) async {
    final row = await db.computer(computerId);
    if (row == null) return;
    if (row.role == 'owner') await backend.deleteComputer(computerId);
    final session = _sessions[computerId];
    if (session != null && session.isConnected) {
      try {
        await link.send(computerId, const {'type': 'leave'});
      } on Object {
        // Best effort; unpair revokes the pairing anyway.
      }
    }
    await link.unpair(computerId);
    await _forget(computerId);
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final s in _subs) {
      await s.cancel();
    }
    for (final s in _sessions.values) {
      await s.dispose();
    }
    _sessions.clear();
    await _changes.close();
    await _banners.close();
  }

  // ---------------------------------------------------------------------

  /// Opens sessions for new rows and closes those whose rows went away.
  /// Only ids seen in an earlier emission are closed: a session opened with
  /// [ensure] just before its row is visible here must survive a stale
  /// emission.
  void _sync(List<ComputerRow> rows) {
    final ids = {for (final r in rows) r.id};
    for (final row in rows) {
      if (!_sessions.containsKey(row.id)) {
        unawaited(ensure(row.id, bind: row.bind));
      }
    }
    for (final id in _listed.difference(ids)) {
      final session = _sessions.remove(id);
      if (session != null) {
        unawaited(session.dispose());
        _changes.add(null);
      }
    }
    _listed = ids;
  }

  Future<ComputerSession> _open(String computerId, String? bind) async {
    final session = ComputerSession(
      computerId: computerId,
      link: link,
      store: store,
      shots: shots,
      bind: bind,
    );
    await session.open();
    _opening.remove(computerId)?.ignore();
    if (_disposed) {
      await session.dispose();
      return session;
    }
    _sessions[computerId] = session;
    _subs.add(
      session.changes.listen((data) {
        if (data.removed) unawaited(_removedByHer(computerId));
      }),
    );
    if (_foreground) session.connect();
    _changes.add(null);
    return session;
  }

  /// Her computer removed this phone: off the list, data deleted, one banner.
  Future<void> _removedByHer(String computerId) async {
    final row = await db.computer(computerId);
    if (row == null) return;
    if (!_banners.isClosed) _banners.add(row.person);
    await _forget(computerId);
  }

  Future<void> _forget(String computerId) async {
    final session = _sessions.remove(computerId);
    await session?.dispose();
    await db.deleteComputer(computerId);
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Marks everything in [computerId]'s thread read now.
  Future<void> markRead(String computerId) => db.updateComputer(
    computerId,
    ComputersCompanion(lastReadAt: Value(clock.now().millisecondsSinceEpoch)),
  );
}
