import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:path/path.dart' as p;

import '../protocol/models/screenshot.dart';
import 'ids.dart';
import 'session/session_data.dart';

/// How long screenshots are kept (brief §2: deleted after 7 days).
const screenshotLifetime = Duration(days: 7);

/// App-private screenshot files (PLAN §3.6), in the OS cache directory,
/// which isn't backed up: `<cache>/<userId>/screenshots/`.
///
/// A file's expiry is in its name (`<id>.<expiresAtMs>`), so it is stable
/// across duplicate deliveries and survives restarts without a table.
/// Guarantee: never shown after expiry, and deleted the first time the app
/// runs after expiry ([purgeExpired] at startup and on resume).
class ScreenshotStore {
  ScreenshotStore(this.directory);

  final Directory directory;
  final Map<String, Future<void>> _chains = {};
  final Map<String, _Entry> _index = {};
  final _changes = StreamController<String>.broadcast();
  bool _indexed = false;

  /// Emits a screenshot id when its file is written or removed.
  Stream<String> get changes => _changes.stream;

  Directory get _shareDir => Directory(p.join(directory.parent.path, 'share'));

  /// Normalises a wire screenshot for an event that happened at [at]: inline
  /// bytes are written (in the background, in order per computer) and
  /// become a [LocalShot]; anything already past its expiry is never
  /// written. Never throws.
  ShotRef? accept(
    WireScreenshot? shot, {
    required int at,
    required String computerId,
  }) {
    switch (shot) {
      case null:
        return null;
      case HostPathScreenshot():
        return const HostShot();
      case RejectedScreenshot():
        return const UnavailableShot();
      case InlineScreenshot(:final bytes, :final mimeType):
        final expiresAt = at + screenshotLifetime.inMilliseconds;
        if (expiresAt <= clock.now().millisecondsSinceEpoch) {
          return const UnavailableShot();
        }
        final id = contentId(bytes);
        final existing = _index[id];
        if (existing != null) return LocalShot(id);
        _index[id] = _Entry(expiresAt, written: false);
        final previous = _chains[computerId] ?? Future<void>.value();
        _chains[computerId] = previous.then(
          (_) => _write(id, bytes, expiresAt, mimeType),
        );
        return LocalShot(id);
    }
  }

  /// The file for [id] if it can be shown now; null if missing, expired or
  /// still being written.
  File? fileFor(String id) {
    final entry = _index[id];
    if (entry == null || !entry.written) return null;
    if (entry.expiresAt <= clock.now().millisecondsSinceEpoch) return null;
    final file = File(_path(id, entry.expiresAt));
    return file.existsSync() ? file : null;
  }

  ShotStatus status(String id) {
    final entry = _index[id];
    if (entry == null) return ShotStatus.missing;
    if (entry.expiresAt <= clock.now().millisecondsSinceEpoch) {
      return ShotStatus.missing;
    }
    return entry.written ? ShotStatus.ready : ShotStatus.writing;
  }

  /// A copy for the share sheet, removed by the next purge.
  Future<File?> shareCopy(String id) async {
    final file = fileFor(id);
    if (file == null) return null;
    await _shareDir.create(recursive: true);
    return file.copy(p.join(_shareDir.path, 'screenshot-$id.png'));
  }

  /// Reads existing files and deletes expired ones and old share copies.
  Future<void> purgeExpired() async {
    final now = clock.now().millisecondsSinceEpoch;
    if (await directory.exists()) {
      await for (final f in directory.list()) {
        if (f is! File) continue;
        final name = p.basename(f.path);
        final parts = name.split('.');
        final expiresAt = parts.length == 2 ? int.tryParse(parts[1]) : null;
        if (name.endsWith('.tmp') || expiresAt == null || expiresAt <= now) {
          await _delete(f);
          if (parts.length == 2) _forget(parts[0]);
          continue;
        }
        if (!_indexed) _index[parts[0]] = _Entry(expiresAt, written: true);
      }
    }
    _indexed = true;
    for (final MapEntry(:key, :value) in _index.entries.toList()) {
      if (value.expiresAt <= now) _forget(key);
    }
    if (await _shareDir.exists()) {
      await for (final f in _shareDir.list()) {
        if (f is File) await _delete(f);
      }
    }
  }

  /// Deletes every file (account sign-out or reset).
  Future<void> clear() async {
    _index.clear();
    if (await directory.exists()) await directory.delete(recursive: true);
    if (await _shareDir.exists()) await _shareDir.delete(recursive: true);
  }

  /// Waits for queued writes (tests).
  Future<void> flush() => Future.wait(_chains.values);

  Future<void> dispose() async {
    await flush();
    await _changes.close();
  }

  Future<void> _write(
    String id,
    Uint8List bytes,
    int expiresAt,
    String mime,
  ) async {
    try {
      await directory.create(recursive: true);
      final target = File(_path(id, expiresAt));
      if (!await target.exists()) {
        final tmp = File('${target.path}.tmp');
        await tmp.writeAsBytes(bytes, flush: true);
        await tmp.rename(target.path);
      }
      final entry = _index[id];
      if (entry != null) _index[id] = _Entry(entry.expiresAt, written: true);
      if (!_changes.isClosed) _changes.add(id);
    } on FileSystemException {
      _index.remove(id);
      if (!_changes.isClosed) _changes.add(id);
    }
  }

  void _forget(String id) {
    if (_index.remove(id) != null && !_changes.isClosed) _changes.add(id);
  }

  String _path(String id, int expiresAt) =>
      p.join(directory.path, '$id.$expiresAt');

  static Future<void> _delete(File f) async {
    try {
      await f.delete();
    } on FileSystemException {
      // Already gone.
    }
  }
}

enum ShotStatus { ready, writing, missing }

class _Entry {
  const _Entry(this.expiresAt, {required this.written});

  final int expiresAt;
  final bool written;
}
