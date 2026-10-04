import 'dart:convert';

import '../../protocol/models/entry.dart';
import '../../protocol/models/policy.dart';
import '../../protocol/models/status.dart';
import '../../protocol/models/task.dart';
import '../../protocol/models/todo.dart';
import '../outbox.dart';
import 'session_data.dart';

/// One row of the `records` table: a projection input as raw JSON with
/// screenshot bytes stripped.
class StoredRecord {
  const StoredRecord({
    required this.computerId,
    required this.kind,
    required this.id,
    required this.at,
    required this.order,
    required this.json,
    this.shot,
    this.meta,
  });

  final String computerId;

  /// `task`, `todo`, `help`, `screen`, `entry` or `note`.
  final String kind;
  final String id;
  final int at;
  final int order;
  final String json;
  final String? shot;
  final String? meta;
}

/// Per-computer sync state (the `sync` table).
class StoredSync {
  const StoredSync({
    required this.computerId,
    this.logCursor,
    this.logMayBeIncomplete = false,
    this.myHelperId,
    this.statusJson,
    this.policyJson,
    this.lastSeenAt,
    this.removed = false,
  });

  final String computerId;
  final int? logCursor;
  final bool logMayBeIncomplete;
  final String? myHelperId;
  final String? statusJson;
  final String? policyJson;
  final int? lastSeenAt;
  final bool removed;
}

/// Changes to persist in one transaction. The log cursor travels with the
/// rows it covers.
class SessionWrite {
  const SessionWrite({
    this.records = const [],
    this.outbox = const [],
    this.outboxDeletes = const [],
    this.sync,
  });

  final List<StoredRecord> records;
  final List<OutboxRow> outbox;
  final List<String> outboxDeletes;
  final StoredSync? sync;

  bool get isEmpty =>
      records.isEmpty &&
      outbox.isEmpty &&
      outboxDeletes.isEmpty &&
      sync == null;
}

abstract class SessionStore {
  /// Records, outbox rows and sync state for one computer.
  Future<StoredSession> load(String computerId);

  Future<void> write(SessionWrite write);

  /// Deletes everything stored for [computerId].
  Future<void> purge(String computerId);
}

class StoredSession {
  const StoredSession({required this.records, required this.outbox, this.sync});

  final List<StoredRecord> records;
  final List<OutboxRow> outbox;
  final StoredSync? sync;
}

/// Rebuilds a session from storage. Live sequence numbers restart at zero:
/// anything stored loses to anything received live.
SessionData hydrate(String computerId, StoredSession stored) {
  final tasks = <String, TrackedTask>{};
  final todos = <String, TrackedTodo>{};
  final helps = <String, HelpEvent>{};
  final screens = <String, ScreenEvent>{};
  final entries = <String, LogRecord>{};
  final notes = <String, LocalNote>{};
  var maxOrder = 0;
  for (final r in stored.records) {
    if (r.order > maxOrder) maxOrder = r.order;
    final Map<String, Object?> json;
    try {
      json = jsonDecode(r.json) as Map<String, Object?>;
    } on FormatException {
      continue;
    }
    try {
      switch (r.kind) {
        case 'task':
          tasks[r.id] = TrackedTask(
            task: Task.fromJson(json),
            shot: ShotRef.decode(r.shot),
            order: r.order,
            liveSeq: 0,
            askedHer: r.meta == 'asked',
          );
        case 'todo':
          todos[r.id] = TrackedTodo(
            todo: Todo.fromJson(json),
            shot: ShotRef.decode(r.shot),
            order: r.order,
            liveSeq: 0,
          );
        case 'help':
          helps[r.id] = HelpEvent(
            id: r.id,
            at: r.at,
            text: json['text'] as String?,
            order: r.order,
          );
        case 'screen':
          screens[r.id] = ScreenEvent(
            id: r.id,
            at: r.at,
            ok: json['ok'] == true,
            shot: ShotRef.decode(r.shot),
            app: json['app'] as String?,
            window: json['window'] as String?,
            reason: json['reason'] as String?,
            order: r.order,
          );
        case 'entry':
          entries[r.id] = LogRecord(
            id: r.id,
            entry: Entry.fromJson(json),
            order: r.order,
          );
        case 'note':
          notes[r.id] = LocalNote(
            id: r.id,
            at: r.at,
            text: json['text'] as String? ?? '',
            order: r.order,
          );
      }
    } on TypeError {
      // A row this version can't read is skipped; history rebuilds from her
      // computer.
    }
  }
  final sync = stored.sync;
  ComputerStatus? status;
  Policy? policy;
  try {
    if (sync?.statusJson != null) {
      status = ComputerStatus.fromJson(
        jsonDecode(sync!.statusJson!) as Map<String, Object?>,
      );
    }
    if (sync?.policyJson != null) {
      policy = Policy.fromJson(
        jsonDecode(sync!.policyJson!) as Map<String, Object?>,
      );
    }
  } on Object {
    status = null;
    policy = null;
  }
  return SessionData(
    computerId: computerId,
    nextOrder: maxOrder + 1,
    tasks: tasks,
    todos: todos,
    helps: helps,
    screens: screens,
    entries: entries,
    notes: notes,
    outbox: {for (final row in stored.outbox) row.id: row},
    status: status,
    policy: policy ?? status?.policy,
    myHelperId: sync?.myHelperId,
    lastSeenAt: sync?.lastSeenAt,
    removed: sync?.removed ?? false,
    logCursor: sync?.logCursor,
    logMayBeIncomplete: sync?.logMayBeIncomplete ?? false,
  );
}

/// What changed between two session states, as storage writes. Entities
/// are compared by identity: the reducer keeps unchanged ones.
SessionWrite diffSession(SessionData before, SessionData after) {
  final id = after.computerId;
  final records = <StoredRecord>[];

  for (final MapEntry(:key, :value) in after.tasks.entries) {
    if (identical(before.tasks[key], value)) continue;
    final t = value.task;
    records.add(
      StoredRecord(
        computerId: id,
        kind: 'task',
        id: key,
        at: t.createdAt ?? 0,
        order: value.order,
        json: _strip(t.raw.isEmpty ? t.toJson() : t.raw),
        shot: value.shot?.encode(),
        meta: value.askedHer ? 'asked' : null,
      ),
    );
  }
  for (final MapEntry(:key, :value) in after.todos.entries) {
    if (identical(before.todos[key], value)) continue;
    final t = value.todo;
    records.add(
      StoredRecord(
        computerId: id,
        kind: 'todo',
        id: key,
        at: t.at,
        order: value.order,
        json: _strip(t.raw.isEmpty ? t.toJson() : t.raw),
        shot: value.shot?.encode(),
      ),
    );
  }
  for (final MapEntry(:key, :value) in after.helps.entries) {
    if (identical(before.helps[key], value)) continue;
    records.add(
      StoredRecord(
        computerId: id,
        kind: 'help',
        id: key,
        at: value.at,
        order: value.order,
        json: jsonEncode({'at': value.at, 'text': ?value.text}),
      ),
    );
  }
  for (final MapEntry(:key, :value) in after.screens.entries) {
    if (identical(before.screens[key], value)) continue;
    records.add(
      StoredRecord(
        computerId: id,
        kind: 'screen',
        id: key,
        at: value.at,
        order: value.order,
        json: jsonEncode({
          'ok': value.ok,
          'app': ?value.app,
          'window': ?value.window,
          'reason': ?value.reason,
        }),
        shot: value.shot?.encode(),
      ),
    );
  }
  for (final MapEntry(:key, :value) in after.entries.entries) {
    if (identical(before.entries[key], value)) continue;
    final e = value.entry;
    records.add(
      StoredRecord(
        computerId: id,
        kind: 'entry',
        id: key,
        at: e.at,
        order: value.order,
        json: _strip(e.raw.isEmpty ? e.toJson() : e.raw),
      ),
    );
  }
  for (final MapEntry(:key, :value) in after.notes.entries) {
    if (identical(before.notes[key], value)) continue;
    records.add(
      StoredRecord(
        computerId: id,
        kind: 'note',
        id: key,
        at: value.at,
        order: value.order,
        json: jsonEncode({'text': value.text}),
      ),
    );
  }

  final outbox = [
    for (final MapEntry(:key, :value) in after.outbox.entries)
      if (!identical(before.outbox[key], value)) value,
  ];
  final deletes = [
    for (final key in before.outbox.keys)
      if (!after.outbox.containsKey(key)) key,
  ];

  final syncChanged =
      before.logCursor != after.logCursor ||
      before.logMayBeIncomplete != after.logMayBeIncomplete ||
      before.myHelperId != after.myHelperId ||
      !identical(before.status, after.status) ||
      !identical(before.policy, after.policy) ||
      before.lastSeenAt != after.lastSeenAt ||
      before.removed != after.removed;

  return SessionWrite(
    records: records,
    outbox: outbox,
    outboxDeletes: deletes,
    sync: syncChanged
        ? StoredSync(
            computerId: id,
            logCursor: after.logCursor,
            logMayBeIncomplete: after.logMayBeIncomplete,
            myHelperId: after.myHelperId,
            statusJson: after.status == null
                ? null
                : _strip(
                    after.status!.raw.isEmpty
                        ? after.status!.toJson()
                        : after.status!.raw,
                  ),
            policyJson: after.policy == null
                ? null
                : jsonEncode(after.policy!.toWire()),
            lastSeenAt: after.lastSeenAt,
            removed: after.removed,
          )
        : null,
  );
}

/// The raw JSON without screenshot data, anywhere in it.
String _strip(Map<String, Object?> raw) => jsonEncode(_stripValue(raw));

Object? _stripValue(Object? v) => switch (v) {
  Map<String, Object?>() => {
    for (final MapEntry(:key, :value) in v.entries)
      if (key != 'screenshot') key: _stripValue(value),
  },
  List<Object?>() => [for (final e in v) _stripValue(e)],
  _ => v,
};

/// An in-memory [SessionStore] for tests and previews.
class MemorySessionStore implements SessionStore {
  final Map<String, Map<String, StoredRecord>> _records = {};
  final Map<String, Map<String, OutboxRow>> _outbox = {};
  final Map<String, StoredSync> _sync = {};
  int writes = 0;

  @override
  Future<StoredSession> load(String computerId) async => StoredSession(
    records: (_records[computerId]?.values.toList() ?? [])
      ..sort((a, b) => a.order.compareTo(b.order)),
    outbox: _outbox[computerId]?.values.toList() ?? [],
    sync: _sync[computerId],
  );

  @override
  Future<void> write(SessionWrite w) async {
    writes++;
    for (final r in w.records) {
      (_records[r.computerId] ??= {})['${r.kind}:${r.id}'] = r;
    }
    for (final row in w.outbox) {
      (_outbox[row.computerId] ??= {})[row.id] = row;
    }
    for (final id in w.outboxDeletes) {
      for (final rows in _outbox.values) {
        rows.remove(id);
      }
    }
    if (w.sync != null) _sync[w.sync!.computerId] = w.sync!;
  }

  @override
  Future<void> purge(String computerId) async {
    _records.remove(computerId);
    _outbox.remove(computerId);
    _sync.remove(computerId);
  }

  /// The stored JSON strings, for assertions.
  Iterable<String> allJson() =>
      _records.values.expand((m) => m.values).map((r) => r.json);
}
