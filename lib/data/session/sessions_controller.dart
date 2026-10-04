import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;

import '../../transport/octo_link.dart';
import '../backend/octo_backend.dart';
import '../db/database.dart';
import '../screenshot_store.dart';
import 'computer_session.dart';
import 'session_data.dart';
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
    this.requestTimeout = const Duration(seconds: 20),
  });

  final OctoDatabase db;
  final OctoLink link;
  final SessionStore store;
  final ScreenshotStore shots;
  final OctoBackend backend;
  final Duration requestTimeout;

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

  final List<void Function(String computerId)> _onConnected = [];
  final Set<String> _cleaning = {};

  /// Calls [listener] each time a computer's link becomes connected (the
  /// profile sync and other owed work run then).
  void addConnectedListener(void Function(String computerId) listener) =>
      _onConnected.add(listener);

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
    unawaited(_retryTombstones());
  }

  void pause() {
    _foreground = false;
    for (final s in _sessions.values) {
      unawaited(s.disconnect());
    }
  }

  /// Removes a computer (PLAN §3.8 Remove).
  ///
  /// Owner ("Remove for everyone"): `DELETE` first; if it fails this throws
  /// and nothing changes. Helper ("Remove from my phone"): no backend call.
  /// Then the computer becomes a hidden tombstone: its session, credentials
  /// and pending `leave` stay until `unpair` succeeds (retried on start,
  /// resume and connect). Only then are its data and screenshots purged.
  Future<void> remove(String computerId) async {
    final row = await db.computer(computerId);
    if (row == null) return;
    if (row.role == 'owner' && !row.tombstone) {
      await backend.deleteComputer(computerId);
    }
    await db.updateComputer(
      computerId,
      const ComputersCompanion(tombstone: Value(true)),
    );
    await _cleanUp(computerId);
  }

  /// Whether any removal is still waiting for its unpair (sign-out warns).
  Future<bool> hasPendingRemovals() async =>
      (await db.allComputers()).any((c) => c.tombstone);

  Future<void> _retryTombstones() async {
    for (final row in await db.allComputers()) {
      if (row.tombstone) await _cleanUp(row.id);
    }
  }

  /// `leave` (best effort), then `unpair`; purges only after unpair worked.
  Future<bool> _cleanUp(String computerId) async {
    if (!_cleaning.add(computerId)) return false;
    try {
      final session = _sessions[computerId];
      if (session != null && session.isConnected) {
        try {
          await link.send(computerId, const {'type': 'leave'});
        } on Object {
          // A leave that is only sent proves nothing; unpair decides.
        }
      }
      try {
        await link.unpair(computerId);
      } on Object {
        return false; // kept as a tombstone; retried later
      }
      await _forget(computerId);
      return true;
    } finally {
      _cleaning.remove(computerId);
    }
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
      if (row.tombstone && !_cleaning.contains(row.id)) {
        unawaited(_cleanUp(row.id));
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
      requestTimeout: requestTimeout,
    );
    await session.open();
    _opening.remove(computerId)?.ignore();
    if (_disposed) {
      await session.dispose();
      return session;
    }
    _sessions[computerId] = session;
    var previous = session.data.link;
    _subs.add(
      session.changes.listen((data) {
        if (data.removed) unawaited(_removedByHer(computerId));
        if (data.link == LinkState.connected &&
            previous != LinkState.connected) {
          for (final listener in _onConnected) {
            listener(computerId);
          }
          unawaited(_retryTombstones());
        }
        previous = data.link;
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
    try {
      await link.unpair(computerId);
    } on Object {
      // Her computer already revoked it.
    }
    await _forget(computerId);
  }

  /// Deletes everything this phone holds for [computerId].
  Future<void> _forget(String computerId) async {
    final session = _sessions.remove(computerId);
    if (session != null) {
      await shots.delete(_shotIds(session.data));
      await session.dispose();
    }
    await db.deleteComputer(computerId);
    if (!_changes.isClosed) _changes.add(null);
  }

  static Set<String> _shotIds(SessionData data) => {
    for (final shot in [
      for (final t in data.tasks.values) t.shot,
      for (final t in data.todos.values) t.shot,
      for (final s in data.screens.values) s.shot,
    ])
      if (shot is LocalShot) shot.id,
  };

  /// Marks everything in [computerId]'s thread read now.
  Future<void> markRead(String computerId) => db.updateComputer(
    computerId,
    ComputersCompanion(lastReadAt: Value(clock.now().millisecondsSinceEpoch)),
  );
}
