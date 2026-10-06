import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_scope.dart';
import '../data/auth/auth_service.dart';
import '../data/auth/supabase_auth.dart';
import '../data/backend/http_backend.dart';
import '../data/backend/octo_backend.dart';
import '../data/backend/relay_aware_backend.dart';
import '../data/db/database.dart';
import '../data/enrollment/enrollment_repository.dart';
import '../data/profile_sync.dart';
import '../data/relay_restore.dart';
import '../data/push/apns_push.dart';
import '../data/push/push_registrar.dart';
import '../data/push/push_service.dart';
import '../data/push/unified_push.dart';
import '../data/screenshot_store.dart';
import '../data/session/computer_session.dart';
import '../data/session/session_data.dart';
import '../data/session/session_store.dart';
import '../data/session/sessions_controller.dart';
import '../data/thread/projection.dart';
import '../transport/octo_link.dart';
import '../transport/relay/control_plane.dart';
import '../transport/relay/relay_link.dart';
import '../transport/relay/secure_vault.dart';
import '../transport/simulator/simulator_link.dart';
import '../transport/unavailable_link.dart';
import 'config.dart';

/// The validated build configuration. Overridden at the root.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('appConfigProvider must be overridden'),
);

/// October sign-in (brief §5.1): a local account in fake mode, Supabase
/// Auth at auth.october.dev in real mode.
final authServiceProvider = Provider<AuthService>((ref) {
  final config = ref.watch(appConfigProvider);
  final AuthService auth = config.isFake
      ? FakeAuth()
      : SupabaseAuth(redirectUrl: config.authRedirect);
  ref.onDispose(auth.dispose);
  return auth;
});

/// The signed-in account, live (null when signed out).
final authAccountProvider = StreamProvider<Account?>((ref) async* {
  final auth = ref.watch(authServiceProvider);
  yield auth.current;
  yield* auth.changes;
});

final signedInAccountProvider = Provider<Account?>((ref) {
  final auth = ref.watch(authServiceProvider);
  final live = ref.watch(authAccountProvider);
  return live.hasValue ? live.value : auth.current;
});

/// The signed-in account. Everything below it (database, sessions,
/// screenshots) is per account and rebuilt when it changes; it is only read
/// while someone is signed in.
final accountProvider = Provider<Account>(
  (ref) => ref.watch(signedInAccountProvider) ?? Account.signedOut,
);

/// The app's root folders. Overridden at the root (resolved before `runApp`).
final appRootsProvider = Provider<AppRoots>(
  (ref) => throw StateError('appRootsProvider must be overridden'),
);

/// This account's directories (tests override it directly).
final accountDirsProvider = Provider<AccountDirs>((ref) {
  final roots = ref.watch(appRootsProvider);
  return AccountDirs.under(
    supportRoot: roots.support,
    cacheRoot: roots.cache,
    account: ref.watch(accountProvider),
  );
});

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
  // One link per signed-in account; signing out closes its connections.
  if (ref.watch(accountProvider).isSignedOut) return UnavailableLink();
  final link = RelayLink(
    control: ControlPlane(
      authOrigin: config.supabaseUrl!,
      accessToken: ref.watch(accessTokenProvider),
      apiKey: config.supabaseAnonKey,
    ),
    vault: SecureVault(),
    relay: Uri.parse(config.relayUrl),
    platform: Platform.isIOS ? 'ios' : 'android',
  );
  ref.onDispose(link.dispose);
  return link;
});

/// A fresh October access token for the signed-in person.
final accessTokenProvider = Provider<Future<String?> Function()>(
  (ref) => ref.watch(authServiceProvider).accessToken,
);

/// Notifications on this phone: Firebase when configured, otherwise none.
final pushServiceProvider = Provider<PushService>((ref) {
  final config = ref.watch(appConfigProvider);
  final PushService push = config.isFake || !config.pushEnabled
      ? NoPush()
      : Platform.isIOS
      ? ApnsPushService()
      : UnifiedPushService();
  ref.onDispose(push.dispose);
  return push;
});

/// Tells October which phone to notify, for the signed-in account.
final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  final name = ref.watch(accountProvider).name;
  final registrar = PushRegistrar(
    push: ref.watch(pushServiceProvider),
    backend: ref.watch(backendProvider),
    deviceLabel: Platform.isIOS ? "$name's iPhone" : "$name's Android phone",
    appVersion: null,
  );
  ref.onDispose(registrar.dispose);
  return registrar;
});

final backendProvider = Provider<OctoBackend>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.isFake) return FakeBackend();
  final backend = HttpBackend(
    baseUrl: config.apiBase,
    accessToken: ref.watch(accessTokenProvider),
  );
  ref.onDispose(backend.close);
  return RelayAwareBackend(backend, ref.watch(databaseProvider));
});

final enrollmentProvider = Provider<EnrollmentRepository>((ref) {
  if (ref.watch(appConfigProvider).isFake) return FakeEnrollment();
  return LinkEnrollment();
});

/// This account's database. The folder is excluded from iOS backups before
/// the database opens (it covers the WAL/journal files too).
final databaseProvider = Provider<OctoDatabase>((ref) {
  // Signed out (only for a frame or two while screens change): an empty
  // database in memory, so nothing is written for no one.
  if (ref.watch(accountProvider).isSignedOut) {
    final empty = OctoDatabase(NativeDatabase.memory());
    ref.onDispose(() => unawaited(empty.close().catchError((Object _) {})));
    return empty;
  }
  final dirs = ref.watch(accountDirsProvider);
  final db = OctoDatabase(
    LazyDatabase(() async {
      await dirs.support.create(recursive: true);
      await excludeFromBackup(dirs.support);
      return NativeDatabase.createInBackground(dirs.databaseFile);
    }),
  );
  // Sign-out may have closed it already.
  ref.onDispose(() => unawaited(db.close().catchError((Object _) {})));
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
  final link = ref.watch(octoLinkProvider);
  final account = ref.watch(accountProvider);
  if (link is RelayLink && !account.isSignedOut) {
    // Before sessions start, so restored computers get theirs.
    try {
      await reconcileRelayBindings(
        db: ref.watch(databaseProvider),
        vault: link.vault,
        userId: account.userId,
        pairingNow: link.pairingNow,
        now: DateTime.now(),
      );
    } on Object {
      // Secure storage unavailable: the list stays as it is; next start retries.
    }
  }
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
