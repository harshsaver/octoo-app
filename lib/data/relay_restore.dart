import 'package:drift/drift.dart';

import '../transport/relay/relay_vault.dart';
import 'db/database.dart';

/// What [reconcileRelayBindings] changed, for logs and tests.
class RelayReconcileReport {
  int restored = 0;
  int discarded = 0;
  int profilesSaved = 0;
}

/// A `started` binding older than this, not part of a running pairing, is
/// a leftover from a pairing that never finished (the app was killed).
const startedBindingLifetime = Duration(minutes: 15);

/// Keeps this account's relay keys and its list of computers in step
/// (PLAN §3.8 binding phases). Run at startup, before sessions start.
///
/// - A `started` binding that no pairing is using anymore is deleted.
/// - A `finalizing` or `complete` binding with no computer in the list puts
///   it back (after a sign-out, a lost database, or a crash between saving
///   the credential and saving the computer), with the profile last seen.
/// - The list's profile is copied into the binding, so that next time it
///   comes back as it was.
///
/// A computer being removed (tombstone) is left alone: its keys go when
/// the unpair succeeds.
Future<RelayReconcileReport> reconcileRelayBindings({
  required OctoDatabase db,
  required RelayVault vault,
  required String userId,
  required Set<String> pairingNow,
  required DateTime now,
}) async {
  final report = RelayReconcileReport();
  final bindings = await vault.list(userId);
  var order = (await db.allComputers()).length;
  for (final b in bindings) {
    if (b.phase == BindingPhase.started) {
      final age = now.millisecondsSinceEpoch - (b.startedAt ?? 0);
      if (!pairingNow.contains(b.computerId) && age >= startedBindingLifetime.inMilliseconds) {
        await vault.delete(userId, b.computerId);
        report.discarded++;
      }
      continue;
    }
    final row = await db.computer(b.computerId);
    if (row == null) {
      final profile = b.profile ?? _guessProfile(b.hostName);
      await db.upsertComputer(
        ComputersCompanion.insert(
          id: b.computerId,
          hostId: Value(b.hostId),
          bind: Value(b.bind),
          computerName: profile.computerName,
          person: profile.person,
          language: Value(profile.language),
          look: Value(profile.look ?? 'orange'),
          role: const Value('direct'),
          sortOrder: Value(order++),
          lastReadAt: Value(now.millisecondsSinceEpoch),
          addedAt: now.millisecondsSinceEpoch,
        ),
      );
      report.restored++;
      continue;
    }
    if (row.tombstone) continue;
    final seen = BindingProfile(
      computerName: row.computerName,
      person: row.person,
      language: row.language,
      look: row.look,
    );
    if (b.profile != seen || b.phase != BindingPhase.complete) {
      // A listed computer finished pairing and setup.
      await vault.write(b.copyWith(profile: seen, phase: BindingPhase.complete));
      report.profilesSaved++;
    }
  }
  return report;
}

/// No profile saved yet: "Mom's laptop" → Mom; otherwise the computer's
/// name stands in for both.
BindingProfile _guessProfile(String hostName) {
  final name = hostName.trim().isEmpty ? 'Computer' : hostName.trim();
  final person = RegExp(r"^(.+?)['’]s\b").firstMatch(name)?.group(1) ?? name;
  return BindingProfile(computerName: name, person: person);
}
