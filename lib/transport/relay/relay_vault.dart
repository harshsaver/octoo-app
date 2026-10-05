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
  });

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

  RelayBinding withCredential(String credential) => RelayBinding(
    computerId: computerId,
    userId: userId,
    hostId: hostId,
    bind: bind,
    hostStatic: hostStatic,
    hostName: hostName,
    deviceStaticKey: deviceStaticKey,
    deviceSignSeed: deviceSignSeed,
    credential: credential,
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
  };
}

abstract class RelayVault {
  Future<RelayBinding?> read(String userId, String computerId);
  Future<void> write(RelayBinding binding);
  Future<void> delete(String userId, String computerId);
}

class MemoryVault implements RelayVault {
  final Map<String, RelayBinding> bindings = {};

  @override
  Future<RelayBinding?> read(String userId, String computerId) async => bindings['$userId/$computerId'];

  @override
  Future<void> write(RelayBinding binding) async => bindings['${binding.userId}/${binding.computerId}'] = binding;

  @override
  Future<void> delete(String userId, String computerId) async => bindings.remove('$userId/$computerId');
}
