import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/data/db/database.dart';
import 'package:octo_family/data/relay_restore.dart';
import 'package:octo_family/transport/relay/relay_vault.dart';

RelayBinding _binding(
  String id, {
  BindingPhase phase = BindingPhase.complete,
  int? startedAt,
  BindingProfile? profile,
  String hostName = "Mom's laptop",
  String user = 'u1',
}) => RelayBinding(
  computerId: id,
  userId: user,
  hostId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
  bind: '11111111-2222-4333-8444-555555555555',
  hostStatic: 'k',
  hostName: hostName,
  deviceStaticKey: 's',
  deviceSignSeed: 'g',
  credential: phase == BindingPhase.started ? null : 'c' * 43,
  phase: phase,
  startedAt: startedAt,
  profile: profile,
);

void main() {
  final now = DateTime(2026, 10, 6, 12);
  late OctoDatabase db;
  late MemoryVault vault;

  setUp(() {
    db = OctoDatabase(NativeDatabase.memory());
    vault = MemoryVault();
  });
  tearDown(() => db.close());

  Future<RelayReconcileReport> reconcile({Set<String> pairing = const {}}) =>
      reconcileRelayBindings(db: db, vault: vault, userId: 'u1', pairingNow: pairing, now: now);

  test('a started binding left by a killed pairing is deleted; a fresh or running one stays', () async {
    final old = now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
    final fresh = now.subtract(const Duration(minutes: 2)).millisecondsSinceEpoch;
    await vault.write(_binding('rly_old', phase: BindingPhase.started, startedAt: old));
    await vault.write(_binding('rly_fresh', phase: BindingPhase.started, startedAt: fresh));
    await vault.write(_binding('rly_running', phase: BindingPhase.started, startedAt: old));

    final report = await reconcile(pairing: {'rly_running'});

    expect(report.discarded, 1);
    expect(vault.bindings.keys, unorderedEquals(['u1/rly_fresh', 'u1/rly_running']));
    expect(await db.allComputers(), isEmpty);
  });

  test('a paired computer missing from the list comes back with its saved profile', () async {
    await vault.write(
      _binding(
        'rly_a',
        profile: const BindingProfile(computerName: 'Laptop', person: 'Ma', language: 'hi', look: 'rose-bow'),
      ),
    );
    final report = await reconcile();

    expect(report.restored, 1);
    final row = (await db.computer('rly_a'))!;
    expect(row.computerName, 'Laptop');
    expect(row.person, 'Ma');
    expect(row.language, 'hi');
    expect(row.look, 'rose-bow');
    expect(row.role, 'direct');
    expect(row.bind, '11111111-2222-4333-8444-555555555555');
    expect(row.profileGen, 0); // nothing is owed to her computer
  });

  test('a finalizing binding (app killed after the credential) also comes back', () async {
    await vault.write(_binding('rly_f', phase: BindingPhase.finalizing));
    await reconcile();
    final row = (await db.computer('rly_f'))!;
    expect((row.computerName, row.person), ("Mom's laptop", 'Mom'));
  });

  test("without a profile, the name is guessed from the computer's name", () async {
    await vault.write(_binding('rly_x', hostName: 'Office PC'));
    await reconcile();
    final row = (await db.computer('rly_x'))!;
    expect((row.computerName, row.person), ('Office PC', 'Office PC'));
  });

  test("the list's profile is saved into the binding, and a finalizing one becomes complete", () async {
    await vault.write(_binding('rly_a', phase: BindingPhase.finalizing));
    await db.upsertComputer(
      ComputersCompanion.insert(
        id: 'rly_a',
        computerName: 'Den PC',
        person: 'Dad',
        look: const Value('mint-headphones'),
        role: const Value('direct'),
        addedAt: 0,
      ),
    );
    final report = await reconcile();
    expect(report.profilesSaved, 1);
    final saved = vault.bindings['u1/rly_a']!;
    expect(saved.phase, BindingPhase.complete);
    expect(saved.profile, const BindingProfile(computerName: 'Den PC', person: 'Dad', look: 'mint-headphones'));
    expect((await reconcile()).profilesSaved, 0); // nothing changed the second time
  });

  test('a computer being removed is left to the unpair', () async {
    await vault.write(_binding('rly_t'));
    await db.upsertComputer(
      ComputersCompanion.insert(
        id: 'rly_t',
        computerName: 'PC',
        person: 'Mom',
        tombstone: const Value(true),
        addedAt: 0,
      ),
    );
    final report = await reconcile();
    expect((report.restored, report.profilesSaved), (0, 0));
    expect(vault.bindings['u1/rly_t']!.profile, isNull);
  });

  test("another account's bindings are not touched", () async {
    await vault.write(_binding('rly_b', user: 'u2'));
    await reconcile();
    expect(await db.allComputers(), isEmpty);
  });

  test('bindings written before phases existed read as started or complete', () {
    final old = RelayBinding.fromJson({
      'computerId': 'rly_o',
      'userId': 'u1',
      'hostId': 'h',
      'bind': 'b',
      'hostStatic': 'k',
      'deviceStaticKey': 's',
      'deviceSignSeed': 'g',
      'credential': 'c' * 43,
    });
    expect(old.phase, BindingPhase.complete);
    expect(RelayBinding.fromJson({...old.toJson(), 'credential': null, 'phase': null}).phase, BindingPhase.started);
    final round = RelayBinding.fromJson(_binding('r', profile: const BindingProfile(computerName: 'A', person: 'B')).toJson());
    expect(round.profile, const BindingProfile(computerName: 'A', person: 'B'));
  });
}
