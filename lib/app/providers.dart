import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_scope.dart';
import '../data/backend/octo_backend.dart';
import '../data/db/database.dart';
import '../data/enrollment/enrollment_repository.dart';
import '../data/profile_sync.dart';
import '../data/screenshot_store.dart';
import '../data/session/computer_session.dart';
import '../data/session/session_data.dart';
import '../data/session/session_store.dart';
import '../data/session/sessions_controller.dart';
import '../data/thread/projection.dart';
import '../transport/octo_link.dart';
import '../transport/simulator/simulator_link.dart';
import 'config.dart';

/// The validated build configuration. Overridden at the root.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('appConfigProvider must be overridden'),
);

/// The signed-in account. Fake mode has one local account until sign-in
/// arrives (stage 4).
final accountProvider = Provider<Account>((ref) => Account.fake);

/// This account's directories. Overridden at the root (resolved before
/// `runApp`) and in tests.
final accountDirsProvider = Provider<AccountDirs>(
  (ref) => throw StateError('accountDirsProvider must be overridden'),
);

/// Whether the scanner may use the camera (tests turn it off).
final cameraAvailableProvider = Provider<bool>((ref) => true);

/// The simulator. Only exists in fake mode.
final simulatorLinkProvider = Provider<SimulatorLink>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.isFake) {
    throw StateError('The simulator is only available in fake mode');
  }
  final simulator = SimulatorLink();
  ref.onDispose(simulator.dispose);
  return simulator;
});

/// The transport. `RelayLink` replaces the simulator in real mode (stage 5).
final octoLinkProvider = Provider<OctoLink>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.isFake) return ref.watch(simulatorLinkProvider);
  throw UnimplementedError('RelayLink arrives in stage 5');
});

final backendProvider = Provider<OctoBackend>((ref) {
  if (ref.watch(appConfigProvider).isFake) return FakeBackend();
  throw UnimplementedError('HttpBackend arrives in stage 4');
});

final enrollmentProvider = Provider<EnrollmentRepository>((ref) {
  if (ref.watch(appConfigProvider).isFake) return FakeEnrollment();
  throw UnimplementedError('HttpEnrollment arrives with its contract');
});

/// This account's database. The folder is excluded from iOS backups before
/// the database opens (it covers the WAL/journal files too).
final databaseProvider = Provider<OctoDatabase>((ref) {
  final dirs = ref.watch(accountDirsProvider);
  final db = OctoDatabase(
    LazyDatabase(() async {
      await dirs.support.create(recursive: true);
      await excludeFromBackup(dirs.support);
      return NativeDatabase.createInBackground(dirs.databaseFile);
    }),
  );
  ref.onDispose(db.close);
  return db;
});

final screenshotStoreProvider = Provider<ScreenshotStore>((ref) {
  final store = ScreenshotStore(ref.watch(accountDirsProvider).screenshots);
  // An expired or deleted screenshot also leaves the decoded-image cache.
  final evictions = store.changes.listen((id) {
    if (store.status(id) == ShotStatus.missing) {
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
    }
  });
  ref.onDispose(() {
    unawaited(evictions.cancel());
    unawaited(store.dispose());
  });
  return store;
});

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => DriftSessionStore(ref.watch(databaseProvider)),
);

/// The app-level owner of every computer's session. Building it has no side
/// effects; [sessionsStartupProvider] starts it.
final sessionsControllerProvider = Provider<SessionsController>((ref) {
  final controller = SessionsController(
    db: ref.watch(databaseProvider),
    link: ref.watch(octoLinkProvider),
    store: ref.watch(sessionStoreProvider),
    shots: ref.watch(screenshotStoreProvider),
    backend: ref.watch(backendProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Starts the sessions once (watched by the app root).
final sessionsStartupProvider = FutureProvider<void>((ref) async {
  ref.watch(profileSyncProvider);
  await ref.watch(sessionsControllerProvider).start();
});

/// Keeps her computer's copy of the profile in step (PLAN §3.5); runs on
/// every connect.
final profileSyncProvider = Provider<ProfileSync>((ref) {
  final sessions = ref.watch(sessionsControllerProvider);
  final sync = ProfileSync(
    db: ref.watch(databaseProvider),
    backend: ref.watch(backendProvider),
    sessionFor: sessions.session,
  );
  sessions.addConnectedListener((id) => unawaited(sync.sync(id)));
  return sync;
});

/// The computers on this phone (not those being removed).
final computersProvider = StreamProvider<List<ComputerRow>>(
  (ref) => ref
      .watch(databaseProvider)
      .watchComputers()
      .map(
        (rows) => [
          for (final r in rows)
            if (!r.tombstone) r,
        ],
      ),
);

final computerProvider = Provider.family<ComputerRow?, String>((ref, id) {
  final rows = ref.watch(computersProvider).value ?? const [];
  for (final r in rows) {
    if (r.id == id) return r;
  }
  return null;
});

/// The session for a computer, once it's open.
final sessionProvider = StreamProvider.family<ComputerSession?, String>((
  ref,
  id,
) async* {
  final controller = ref.watch(sessionsControllerProvider);
  yield controller.session(id);
  await for (final _ in controller.changes) {
    yield controller.session(id);
  }
});

/// A computer's conversation state, live.
final sessionDataProvider = StreamProvider.family<SessionData, String>((
  ref,
  id,
) async* {
  final session = await ref.watch(sessionProvider(id).future);
  if (session == null) return;
  yield session.data;
  yield* session.changes;
});

/// Who this phone is, for one computer.
final meProvider = Provider.family<MeIdentity, String>((ref, id) {
  final data = ref.watch(sessionDataProvider(id)).value;
  return MeIdentity(
    name: ref.watch(accountProvider).name,
    helperId: data?.myHelperId,
  );
});

/// The thread for one computer.
final threadProvider = Provider.family<List<ThreadEntry>, String>((ref, id) {
  final data = ref.watch(sessionDataProvider(id)).value;
  if (data == null) return const [];
  return projectThread(data, ref.watch(meProvider(id)));
});

/// The screenshot store's updates, so images appear once written.
final screenshotChangesProvider = StreamProvider<String>(
  (ref) => ref.watch(screenshotStoreProvider).changes,
);

const _backupChannel = MethodChannel('dev.october.octo/backup');

/// Excludes [dir] from iOS backups (`NSURLIsExcludedFromBackupKey`). Android
/// disables backup in the manifest.
Future<void> excludeFromBackup(Directory dir) async {
  if (!Platform.isIOS) return;
  try {
    await _backupChannel.invokeMethod<void>('excludeFromBackup', dir.path);
  } on MissingPluginException {
    // Tests and other hosts.
  }
}
