import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'relay_vault.dart';

/// The app's [RelayVault]: Keychain (this device only) on iOS, encrypted
/// storage on Android. Kept apart so the test Octo (plain Dart) can use the
/// relay code without Flutter.
class SecureVault implements RelayVault {
  SecureVault([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
          );

  final FlutterSecureStorage _storage;

  static String _key(String userId, String computerId) => 'octo.relay.$userId.$computerId';

  @override
  Future<RelayBinding?> read(String userId, String computerId) async {
    final raw = await _storage.read(key: _key(userId, computerId));
    if (raw == null) return null;
    try {
      return RelayBinding.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(RelayBinding binding) =>
      _storage.write(key: _key(binding.userId, binding.computerId), value: jsonEncode(binding.toJson()));

  @override
  Future<void> delete(String userId, String computerId) => _storage.delete(key: _key(userId, computerId));
}
