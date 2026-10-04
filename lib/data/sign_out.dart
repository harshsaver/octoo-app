import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'account_scope.dart';
import 'auth/auth_service.dart';
import 'db/database.dart';
import 'push/push_registrar.dart';
import 'screenshot_store.dart';
import 'session/sessions_controller.dart';

/// Folders still to delete after a sign-out (survives a crash midway).
const pendingWipeKey = 'signOut.pendingWipe';

/// Signs out in the order PLAN §3.9 sets: unregister push while the access
/// token still works → stop sessions → delete this account's database,
/// outbox and screenshots → sign out. Relay keys (stage 5) stay, namespaced
/// to the account.
Future<void> signOutAndForget({
  required PushRegistrar registrar,
  required SessionsController sessions,
  required OctoDatabase db,
  required ScreenshotStore shots,
  required AccountDirs dirs,
  required SharedPreferences prefs,
  required AuthService auth,
}) async {
  await registrar.unregister();
  await sessions.dispose();
  await prefs.setStringList(
    pendingWipeKey,
    {
      ...?prefs.getStringList(pendingWipeKey),
      dirs.support.path,
      dirs.cache.path,
    }.toList(),
  );
  await db.close();
  await shots.clear();
  await wipePending(prefs);
  await auth.signOut();
}

/// Deletes folders left by an interrupted sign-out. Run at startup.
Future<void> wipePending(SharedPreferences prefs) async {
  final left = <String>[];
  for (final path in prefs.getStringList(pendingWipeKey) ?? const <String>[]) {
    final dir = Directory(path);
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } on FileSystemException {
      left.add(path);
    }
  }
  if (left.isEmpty) {
    await prefs.remove(pendingWipeKey);
  } else {
    await prefs.setStringList(pendingWipeKey, left);
  }
}
