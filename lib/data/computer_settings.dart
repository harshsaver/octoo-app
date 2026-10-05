import 'package:drift/drift.dart' show Value;

import 'backend/octo_backend.dart';
import 'db/database.dart';

/// Mutes or unmutes a computer for this person. The backend first (on iOS
/// the system shows alerts itself, so the server must stop sending them);
/// if that fails this throws [BackendException] and nothing local changes.
/// The local flag then covers Android display and in-app banners.
Future<void> setComputerMuted(
  OctoDatabase db,
  OctoBackend backend,
  String computerId,
  bool muted,
) async {
  await backend.setMuted(computerId, muted);
  await db.updateComputer(computerId, ComputersCompanion(muted: Value(muted)));
}
