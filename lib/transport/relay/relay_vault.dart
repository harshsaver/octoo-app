/// How far a pairing got (PLAN §3.8 binding phases).
enum BindingPhase {
  /// Keys made, nothing approved yet. Deleted at startup unless a pairing
  /// is still running.
  started,

  /// Her computer sent the credential; saved before `pairAck`. Kept and
  /// used like [complete]: the pairing may have finished on her side.
  finalizing,

  /// Paired.
  complete,
}

/// The computer's profile as this phone last saw it, so the list can be
/// rebuilt from the vault after sign-out, a lost database or a crash.
class BindingProfile {
  const BindingProfile({
    required this.computerName,
    required this.person,
    this.language,
    this.look,
  });

  static BindingProfile? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final name = json['computerName'], person = json['person'];
    if (name is! String || person is! String) return null;
    return BindingProfile(
      computerName: name,
      person: person,
      language: json['language'] as String?,
      look: json['look'] as String?,
    );
  }

  final String computerName;
  final String person;
  final String? language;
  final String? look;

  Map<String, Object?> toJson() => {
    'computerName': computerName,
    'person': person,
    'language': ?language,
    'look': ?look,
  };

  @override
  bool operator ==(Object other) =>
      other is BindingProfile &&
      other.computerName == computerName &&
      other.person == person &&
      other.language == language &&
      other.look == look;

  @override
  int get hashCode => Object.hash(computerName, person, language, look);
}

/// What this phone keeps for one paired computer: its keys and the
/// credential her computer issued. Never leaves the device; on iOS it is
/// this-device-only Keychain, on Android encrypted shared preferences.
class RelayBinding {
  const RelayBinding({
    required this.computerId,
    required this.userId,
    required this.hostId,
    required this.bind,
    required this.hostStatic,
    required this.hostName,
    required this.deviceStaticKey,
    required this.deviceSignSeed,
    this.credential,
    BindingPhase? phase,
    this.startedAt,
    this.profile,
    this.helperId,
  }) : phase = phase ?? (credential == null ? BindingPhase.started : BindingPhase.complete);

  factory RelayBinding.fromJson(Map<String, Object?> json) => RelayBinding(
    computerId: json['computerId']! as String,
    userId: json['userId']! as String,
    hostId: json['hostId']! as String,
    bind: json['bind']! as String,
    hostStatic: json['hostStatic']! as String,
    hostName: json['hostName'] as String? ?? '',
    deviceStaticKey: json['deviceStaticKey']! as String,
    deviceSignSeed: json['deviceSignSeed']! as String,
    credential: json['credential'] as String?,
    phase: BindingPhase.values.asNameMap()[json['phase']],
    startedAt: (json['startedAt'] as num?)?.toInt(),
    profile: BindingProfile.fromJson(json['profile']),
    helperId: json['helperId'] as String?,
  );

  final String computerId;

  /// The October account it was paired under.
  final String userId;
  final String hostId;
  final String bind;

  /// Her computer's Noise key, base64url (pinned on every connection).
  final String hostStatic;
  final String hostName;

  /// This phone's X25519 private key and Ed25519 seed, base64url.
  final String deviceStaticKey;
  final String deviceSignSeed;

  /// Null until her computer approved the pairing.
  final String? credential;
  final BindingPhase phase;

  /// When the pairing began (epoch ms).
  final int? startedAt;
  final BindingProfile? profile;

  /// This phone's helper id on her computer, from `octo.hello`.
  final String? helperId;

  /// Has a credential, so it can connect.
  bool get usable => credential != null && phase != BindingPhase.started;

  RelayBinding copyWith({String? credential, BindingPhase? phase, BindingProfile? profile, String? helperId}) =>
      RelayBinding(
    computerId: computerId,
    userId: userId,
    hostId: hostId,
    bind: bind,
    hostStatic: hostStatic,
    hostName: hostName,
    deviceStaticKey: deviceStaticKey,
    deviceSignSeed: deviceSignSeed,
    credential: credential ?? this.credential,
    phase: phase ?? this.phase,
    startedAt: startedAt,
    profile: profile ?? this.profile,
    helperId: helperId ?? this.helperId,
  );

  Map<String, Object?> toJson() => {
    'computerId': computerId,
    'userId': userId,
    'hostId': hostId,
    'bind': bind,
    'hostStatic': hostStatic,
    'hostName': hostName,
    'deviceStaticKey': deviceStaticKey,
    'deviceSignSeed': deviceSignSeed,
    'credential': ?credential,
    'phase': phase.name,
    'startedAt': ?startedAt,
    'profile': ?profile?.toJson(),
    'helperId': ?helperId,
  };
}

abstract class RelayVault {
  /// Every binding of [userId] on this phone.
  Future<List<RelayBinding>> list(String userId);
  Future<RelayBinding?> read(String userId, String computerId);
  Future<void> write(RelayBinding binding);
  Future<void> delete(String userId, String computerId);
}

class MemoryVault implements RelayVault {
  final Map<String, RelayBinding> bindings = {};

  @override
  Future<List<RelayBinding>> list(String userId) async => [
    for (final b in bindings.values)
      if (b.userId == userId) b,
  ];

  @override
  Future<RelayBinding?> read(String userId, String computerId) async => bindings['$userId/$computerId'];

  @override
  Future<void> write(RelayBinding binding) async => bindings['${binding.userId}/${binding.computerId}'] = binding;

  @override
  Future<void> delete(String userId, String computerId) async => bindings.remove('$userId/$computerId');
}
