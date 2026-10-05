/// The test Octo's side of October's control plane: password sign-in and
/// the host's signed requests (october-desktop `src/main/remote-pairing.ts`,
/// `remote-devices.ts`).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:octo_family/transport/relay/control_plane.dart';
import 'package:octo_family/transport/relay/encoding.dart';

import 'host_relay.dart';

/// Sign-in with email and password against October's Supabase auth, with
/// token refresh.
class PasswordSession {
  PasswordSession({required this.authOrigin, required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  final Uri authOrigin;
  final String apiKey;
  final http.Client _client;
  String? _access;
  String? _refresh;
  DateTime _expires = DateTime.fromMillisecondsSinceEpoch(0);

  String? get email => _email;
  String? _email;

  Future<void> signIn(String email, String password) async {
    await _token({'email': email, 'password': password}, 'password');
    _email = email;
  }

  Future<void> _token(Map<String, String> body, String grant) async {
    final response = await _client.post(
      authOrigin.replace(path: '/auth/v1/token', queryParameters: {'grant_type': grant}),
      headers: {'apikey': apiKey, 'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    final json = jsonDecode(response.body) as Map<String, Object?>;
    if (response.statusCode != 200) {
      throw ControlPlaneException(
        response.statusCode,
        json['error_code'] as String? ?? json['error'] as String?,
        json['msg'] as String? ?? json['error_description'] as String? ?? 'sign-in failed',
      );
    }
    _access = json['access_token']! as String;
    _refresh = json['refresh_token']! as String;
    _expires = DateTime.now().add(Duration(seconds: (json['expires_in'] as num? ?? 3600).toInt()));
  }

  Future<String?> accessToken() async {
    if (_access == null) return null;
    if (DateTime.now().isAfter(_expires.subtract(const Duration(minutes: 2)))) {
      await _token({'refresh_token': _refresh!}, 'refresh_token');
    }
    return _access;
  }
}

/// What the test Octo asks of October's cloud (a fake in tests).
abstract class HostCloud {
  Future<String> hostTicket();

  /// A pairing intent; registers this host on first use.
  Future<({String intentId, String secret, int expiresAt})> createPairing();

  Future<HostBinding?> lookupBinding(String bind);

  /// Approves or denies; returns the new state version.
  Future<int> decide(HostBinding binding, {required bool approve});

  /// Returns the final state version.
  Future<int> finalize(String intentId, int stateVersion);

  /// Mom removed this phone.
  Future<void> revokeDevice(String bind);
}

class OctoberHostCloud implements HostCloud {
  OctoberHostCloud({
    required this.control,
    required this.hostId,
    required this.sign,
    required this.staticPub,
    required this.name,
    required this.platform,
    this.machine = 'laptop',
  });

  final ControlPlane control;
  final String hostId;
  final SigningKey sign;
  final String staticPub;
  final String name;

  /// `mac`, `win` or `linux`.
  final String platform;
  final String machine;

  Future<Map<String, Object?>> _post(String function, String operation, Map<String, Object?> body) =>
      control.post(function, body, signer: sign, operation: operation);

  @override
  Future<String> hostTicket() async {
    final r = await _post('mobile-relay-ticket', 'ticket-host', {'role': 'host', 'hostId': hostId, 'key': staticPub});
    return r['ticket']! as String;
  }

  @override
  Future<({String intentId, String secret, int expiresAt})> createPairing() async {
    final r = await _post('mobile-pair-create', 'pair-create', {
      'hostId': hostId,
      'hostSignPub': b64url(sign.publicKey),
      'hostStaticPub': staticPub,
      'name': name,
      'platform': platform,
      'machine': machine,
    });
    return (
      intentId: r['intentId']! as String,
      secret: r['secret']! as String,
      expiresAt: (r['expiresAt']! as num).toInt(),
    );
  }

  @override
  Future<HostBinding?> lookupBinding(String bind) async {
    final devices = await control.select('mobile_devices', {
      'select': 'bind,device_static_pub,device_sign_pub,label,platform,revoked_at',
      'host_id': 'eq.$hostId',
      'bind': 'eq.$bind',
      'limit': '1',
    });
    if (devices.isNotEmpty && devices.first['revoked_at'] == null) {
      final d = devices.first;
      return HostBinding(
        bind: bind,
        pairing: false,
        deviceStatic: b64urlDecode(d['device_static_pub']! as String),
        label: d['label'] as String? ?? '',
        platform: d['platform'] as String?,
      );
    }
    final intents = await control.select('mobile_pair_intents', {
      'select': 'intent_id,bind,device_static_pub,device_sign_pub,label,platform,state,state_version,expires_at',
      'host_id': 'eq.$hostId',
      'bind': 'eq.$bind',
      'state': 'in.(pending,approved)',
      'expires_at': 'gt.${DateTime.now().toUtc().toIso8601String()}',
      'limit': '1',
    });
    if (intents.isEmpty) return null;
    final i = intents.first;
    return HostBinding(
      bind: bind,
      pairing: true,
      deviceStatic: b64urlDecode(i['device_static_pub']! as String),
      label: i['label'] as String? ?? '',
      platform: i['platform'] as String?,
      intentId: i['intent_id']! as String,
      stateVersion: (i['state_version']! as num).toInt(),
      deviceSignPub: i['device_sign_pub'] as String?,
    );
  }

  @override
  Future<int> decide(HostBinding binding, {required bool approve}) async {
    final r = await _post('mobile-pair-decide', 'pair-decide', {
      'intentId': binding.intentId,
      'bind': binding.bind,
      'deviceStaticPub': b64url(binding.deviceStatic),
      'deviceSignPub': binding.deviceSignPub,
      'decision': approve ? 'approve' : 'deny',
      'stateVersion': binding.stateVersion,
    });
    return (r['stateVersion']! as num).toInt();
  }

  @override
  Future<int> finalize(String intentId, int stateVersion) async {
    final r = await _post('mobile-pair-finalize', 'pair-finalize', {'intentId': intentId, 'stateVersion': stateVersion});
    return (r['stateVersion']! as num).toInt();
  }

  @override
  Future<void> revokeDevice(String bind) =>
      _post('mobile-device-revoke', 'device-revoke', {'hostId': hostId, 'bind': bind});
}
