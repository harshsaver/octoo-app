import 'dart:convert';

import 'package:drift/drift.dart';

import '../outbox.dart';
import '../session/session_store.dart';

part 'database.g.dart';

/// The family computers on this phone, for this account.
@DataClassName('ComputerRow')
class Computers extends Table {
  TextColumn get id => text()();
  TextColumn get hostId => text().nullable()();

  /// The relay pairing this phone holds; outbox rows are bound to it.
  TextColumn get bind => text().nullable()();
  TextColumn get computerName => text()();
  TextColumn get person => text()();
  TextColumn get language => text().nullable()();
  TextColumn get os => text().nullable()();
  TextColumn get look => text().withDefault(const Constant('orange'))();

  /// `owner` or `helper`.
  TextColumn get role => text().withDefault(const Constant('owner'))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Items newer than this are unread (epoch ms).
  IntColumn get lastReadAt => integer().withDefault(const Constant(0))();
  IntColumn get addedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Projection inputs (tasks, to-dos, help, screens, log entries, notes) as
/// raw JSON without screenshot bytes.
@DataClassName('RecordRow')
class Records extends Table {
  /// Insert sequence; ties on `at` keep arrival order.
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get computerId => text()();
  TextColumn get kind => text()();
  TextColumn get recordId => text()();
  IntColumn get at => integer()();
  IntColumn get sortOrder => integer()();
  TextColumn get json => text()();
  TextColumn get shot => text().nullable()();
  TextColumn get meta => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {computerId, kind, recordId},
  ];
}

@DataClassName('OutboxDbRow')
class Outbox extends Table {
  TextColumn get id => text()();
  TextColumn get computerId => text()();
  TextColumn get bind => text().nullable()();
  TextColumn get kind => text()();
  TextColumn get payload => text()();
  TextColumn get state => text()();
  TextColumn get requestId => text().nullable()();
  TextColumn get taskId => text().nullable()();
  TextColumn get error => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get retryOf => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SyncRow')
class SyncStates extends Table {
  TextColumn get computerId => text()();
  IntColumn get logCursor => integer().nullable()();
  BoolColumn get logMayBeIncomplete =>
      boolean().withDefault(const Constant(false))();
  TextColumn get myHelperId => text().nullable()();
  TextColumn get statusJson => text().nullable()();
  TextColumn get policyJson => text().nullable()();
  IntColumn get lastSeenAt => integer().nullable()();
  BoolColumn get removed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {computerId};
}

/// One database per account (`ApplicationSupport/<userId>/octo.sqlite`),
/// excluded from backups.
@DriftDatabase(tables: [Computers, Records, Outbox, SyncStates])
class OctoDatabase extends _$OctoDatabase {
  OctoDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ---------------------------------------------------------------------
  // Computers

  Stream<List<ComputerRow>> watchComputers() =>
      (select(computers)..orderBy([
            (c) => OrderingTerm.asc(c.sortOrder),
            (c) => OrderingTerm.asc(c.addedAt),
          ]))
          .watch();

  Future<List<ComputerRow>> allComputers() => select(computers).get();

  Future<ComputerRow?> computer(String id) =>
      (select(computers)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<void> upsertComputer(ComputersCompanion row) =>
      into(computers).insertOnConflictUpdate(row);

  Future<void> updateComputer(String id, ComputersCompanion changes) =>
      (update(computers)..where((c) => c.id.equals(id))).write(changes);

  /// Removes the computer and everything stored for it.
  Future<void> deleteComputer(String id) => transaction(() async {
    await (delete(computers)..where((c) => c.id.equals(id))).go();
    await DriftSessionStore(this).purge(id);
  });
}

/// [SessionStore] over [OctoDatabase].
class DriftSessionStore implements SessionStore {
  DriftSessionStore(this.db);

  final OctoDatabase db;

  @override
  Future<StoredSession> load(String computerId) async {
    final records =
        await (db.select(db.records)
              ..where((r) => r.computerId.equals(computerId))
              ..orderBy([
                (r) => OrderingTerm.asc(r.sortOrder),
                (r) => OrderingTerm.asc(r.seq),
              ]))
            .get();
    final outbox = await (db.select(
      db.outbox,
    )..where((r) => r.computerId.equals(computerId))).get();
    final sync = await (db.select(
      db.syncStates,
    )..where((s) => s.computerId.equals(computerId))).getSingleOrNull();
    return StoredSession(
      records: [
        for (final r in records)
          StoredRecord(
            computerId: r.computerId,
            kind: r.kind,
            id: r.recordId,
            at: r.at,
            order: r.sortOrder,
            json: r.json,
            shot: r.shot,
            meta: r.meta,
          ),
      ],
      outbox: [for (final r in outbox) ?_outboxFromDb(r)],
      sync: sync == null
          ? null
          : StoredSync(
              computerId: sync.computerId,
              logCursor: sync.logCursor,
              logMayBeIncomplete: sync.logMayBeIncomplete,
              myHelperId: sync.myHelperId,
              statusJson: sync.statusJson,
              policyJson: sync.policyJson,
              lastSeenAt: sync.lastSeenAt,
              removed: sync.removed,
            ),
    );
  }

  @override
  Future<void> write(SessionWrite w) => db.transaction(() async {
    for (final r in w.records) {
      await db
          .into(db.records)
          .insert(
            RecordsCompanion.insert(
              computerId: r.computerId,
              kind: r.kind,
              recordId: r.id,
              at: r.at,
              sortOrder: r.order,
              json: r.json,
              shot: Value(r.shot),
              meta: Value(r.meta),
            ),
            onConflict: DoUpdate(
              (_) => RecordsCompanion(
                at: Value(r.at),
                json: Value(r.json),
                shot: Value(r.shot),
                meta: Value(r.meta),
              ),
              target: [
                db.records.computerId,
                db.records.kind,
                db.records.recordId,
              ],
            ),
          );
    }
    for (final row in w.outbox) {
      await db
          .into(db.outbox)
          .insertOnConflictUpdate(
            OutboxCompanion.insert(
              id: row.id,
              computerId: row.computerId,
              bind: Value(row.bind),
              kind: row.kind.wire,
              payload: jsonEncode(row.payload),
              state: row.state.name,
              requestId: Value(row.requestId),
              taskId: Value(row.taskId),
              error: Value(row.error),
              errorMessage: Value(row.errorMessage),
              retryOf: Value(row.retryOf),
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ),
          );
    }
    if (w.outboxDeletes.isNotEmpty) {
      await (db.delete(
        db.outbox,
      )..where((r) => r.id.isIn(w.outboxDeletes))).go();
    }
    final s = w.sync;
    if (s != null) {
      await db
          .into(db.syncStates)
          .insertOnConflictUpdate(
            SyncStatesCompanion.insert(
              computerId: s.computerId,
              logCursor: Value(s.logCursor),
              logMayBeIncomplete: Value(s.logMayBeIncomplete),
              myHelperId: Value(s.myHelperId),
              statusJson: Value(s.statusJson),
              policyJson: Value(s.policyJson),
              lastSeenAt: Value(s.lastSeenAt),
              removed: Value(s.removed),
            ),
          );
    }
  });

  @override
  Future<void> purge(String computerId) => db.transaction(() async {
    await (db.delete(
      db.records,
    )..where((r) => r.computerId.equals(computerId))).go();
    await (db.delete(
      db.outbox,
    )..where((r) => r.computerId.equals(computerId))).go();
    await (db.delete(
      db.syncStates,
    )..where((r) => r.computerId.equals(computerId))).go();
  });

  static OutboxRow? _outboxFromDb(OutboxDbRow r) {
    final kind = OutboxKind.fromWire(r.kind);
    final state = OutboxState.values.asNameMap()[r.state];
    if (kind == null || state == null) return null;
    return OutboxRow(
      id: r.id,
      computerId: r.computerId,
      bind: r.bind,
      kind: kind,
      payload: jsonDecode(r.payload) as Map<String, Object?>,
      state: state,
      requestId: r.requestId,
      taskId: r.taskId,
      error: r.error,
      errorMessage: r.errorMessage,
      retryOf: r.retryOf,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}
