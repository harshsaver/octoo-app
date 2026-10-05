import '../../transport/relay/relay_link.dart' show isRelayComputerId;
import '../db/database.dart';
import 'octo_backend.dart';

/// Computers paired straight over October's relay (`rly_…`, see
/// `EnrollmentMode.direct`) have no Octo backend record. For them the
/// profile lives on this phone, and the calls that only the backend can
/// answer (usage, mute fan-out, delete) do nothing. Everything else goes
/// to [inner].
class RelayAwareBackend implements OctoBackend {
  RelayAwareBackend(this.inner, this.db);

  final OctoBackend inner;
  final OctoDatabase db;

  @override
  Future<List<BackendComputer>> listComputers() async {
    final local = [
      for (final row in await db.allComputers())
        if (isRelayComputerId(row.id) && !row.tombstone)
          BackendComputer(
            id: row.id,
            hostId: row.hostId,
            name: row.computerName,
            person: row.person,
            language: row.language,
            role: 'member',
            octo: row.look,
            muted: row.muted,
          ),
    ];
    try {
      return [...await inner.listComputers(), ...local];
    } on BackendException {
      if (local.isEmpty) rethrow;
      return local;
    }
  }

  @override
  Future<BackendComputer> patchComputer(
    String id, {
    String? name,
    String? person,
    String? language,
    String? octo,
  }) async {
    if (!isRelayComputerId(id)) {
      return inner.patchComputer(id, name: name, person: person, language: language, octo: octo);
    }
    final row = await db.computer(id);
    return BackendComputer(
      id: id,
      hostId: row?.hostId,
      name: name ?? row?.computerName ?? '',
      person: person ?? row?.person ?? '',
      language: language ?? row?.language,
      role: 'member',
      octo: octo ?? row?.look,
      muted: row?.muted ?? false,
    );
  }

  @override
  Future<void> deleteComputer(String id) async {
    if (!isRelayComputerId(id)) await inner.deleteComputer(id);
  }

  @override
  Future<Usage> usage(String computerId, String month) async => isRelayComputerId(computerId)
      ? const Usage(tasks: 0, steps: 0, questions: 0, costAmount: 0, currency: 'USD')
      : inner.usage(computerId, month);

  @override
  Future<void> setMuted(String computerId, bool muted) async {
    if (!isRelayComputerId(computerId)) await inner.setMuted(computerId, muted);
  }

  @override
  Future<ClaimResult> claim(
    ClaimCredentials credentials, {
    String? person,
    String? computerName,
    String? language,
  }) => inner.claim(credentials, person: person, computerName: computerName, language: language);

  @override
  Future<void> registerPush({
    required String token,
    required String platform,
    String? deviceLabel,
    String? appVersion,
  }) => inner.registerPush(token: token, platform: platform, deviceLabel: deviceLabel, appVersion: appVersion);

  @override
  Future<void> unregisterPush(String token) => inner.unregisterPush(token);

  @override
  Future<Set<String>> notifyPreferences() => inner.notifyPreferences();

  @override
  Future<void> setNotifyPreferences(Set<String> off) => inner.setNotifyPreferences(off);
}
