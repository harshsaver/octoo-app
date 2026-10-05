import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'octo_backend.dart';

/// The real Octo API on october.dev (saturday `api/lib/_octo/`,
/// docs/OCTO_BACKEND.md). Every call carries the signed-in person's October
/// access token as `Authorization: Bearer …`.
///
/// Errors arrive as `{"error":{"code","message"}}` and become a
/// [BackendException] whose message can be shown as-is. Anything else that
/// goes wrong (no network, a timeout, a body that isn't the contract)
/// becomes `unavailable` with a plain sentence.
class HttpBackend implements OctoBackend {
  HttpBackend({
    required this.baseUrl,
    required this.accessToken,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  /// `https://www.october.dev`.
  final Uri baseUrl;

  /// The current access token, refreshed by the auth layer; null if signed out.
  final Future<String?> Function() accessToken;
  final Duration timeout;
  final http.Client _client;

  static const _unavailable = BackendException(
    'unavailable',
    "Couldn't reach October. Check the connection and try again.",
  );

  @override
  Future<List<BackendComputer>> listComputers() async {
    final json = await _send('GET', 'computers');
    final list = json?['computers'];
    if (list is! List<Object?>) throw _unavailable;
    return [
      for (final item in list)
        if (item is Map<String, Object?>) _computer(item),
    ];
  }

  @override
  Future<ClaimResult> claim(
    ClaimCredentials credentials, {
    String? person,
    String? computerName,
    String? language,
  }) async {
    final json = await _send('POST', 'computers/claim', {
      ...credentials.toJson(),
      'person': ?person,
      'computerName': ?computerName,
      'language': ?language,
    });
    final id = json?['computerId'];
    if (id is! String) throw _unavailable;
    return ClaimResult(
      computerId: id,
      hostId: json!['hostId'] is String ? json['hostId']! as String : null,
      name: json['name'] is String ? json['name']! as String : null,
    );
  }

  @override
  Future<BackendComputer> patchComputer(
    String id, {
    String? name,
    String? person,
    String? language,
    String? octo,
  }) async {
    final json = await _send('PATCH', 'computers/${Uri.encodeComponent(id)}', {
      'name': ?name,
      'person': ?person,
      'language': ?language,
      'octo': ?octo,
    });
    if (json == null) throw _unavailable;
    return _computer(json);
  }

  @override
  Future<void> deleteComputer(String id) =>
      _send('DELETE', 'computers/${Uri.encodeComponent(id)}');

  @override
  Future<Usage> usage(String computerId, String month) async {
    final json = await _send('GET', 'usage', null, {
      'computerId': computerId,
      'month': month,
    });
    if (json == null) throw _unavailable;
    return Usage.fromJson(json);
  }

  @override
  Future<void> registerPush({
    required String token,
    required String platform,
    String? deviceLabel,
    String? appVersion,
  }) => _send('POST', 'push/register', {
    'token': token,
    'platform': platform,
    'deviceLabel': ?deviceLabel,
    'appVersion': ?appVersion,
  });

  @override
  Future<void> unregisterPush(String token) =>
      _send('DELETE', 'push/register', {'token': token});

  @override
  Future<void> setMuted(String computerId, bool muted) => _send(
    'PUT',
    'computers/${Uri.encodeComponent(computerId)}/mute',
    {'muted': muted},
  );

  @override
  Future<Set<String>> notifyPreferences() async {
    final json = await _send('GET', 'push/preferences');
    final off = json?['off'];
    if (off is! List<Object?>) throw _unavailable;
    return {
      for (final k in off)
        if (k is String) k,
    };
  }

  @override
  Future<void> setNotifyPreferences(Set<String> off) =>
      _send('PUT', 'push/preferences', {'off': off.toList()});

  // ---------------------------------------------------------------------

  BackendComputer _computer(Map<String, Object?> json) {
    try {
      return BackendComputer.fromJson(json);
    } on FormatException {
      throw _unavailable;
    }
  }

  /// Sends one request; returns the JSON body (null for 204).
  Future<Map<String, Object?>?> _send(
    String method,
    String path, [
    Map<String, Object?>? body,
    Map<String, String>? query,
  ]) async {
    final token = await accessToken();
    if (token == null) {
      throw const BackendException('unauthorized', 'Sign in to October again.');
    }
    final uri = baseUrl.replace(
      path: '${baseUrl.path.replaceAll(RegExp(r'/$'), '')}/api/octo/$path',
      queryParameters: query,
    );
    final request = http.Request(method, uri)
      ..headers['authorization'] = 'Bearer $token'
      ..headers['accept'] = 'application/json';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      );
    } on TimeoutException {
      throw _unavailable;
    } on http.ClientException {
      throw _unavailable;
    }

    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.statusCode == 204 || decoded == null) return null;
      if (decoded is Map<String, Object?>) return decoded;
      throw _unavailable;
    }
    throw _error(response, decoded);
  }

  static BackendException _error(http.Response response, Object? decoded) {
    final error = decoded is Map<String, Object?> ? decoded['error'] : null;
    final retry = int.tryParse(response.headers['retry-after'] ?? '');
    if (error is Map<String, Object?> && error['code'] is String) {
      final message = error['message'];
      return BackendException(
        error['code']! as String,
        message is String && message.isNotEmpty
            ? message
            : _unavailable.message,
        retryAfter: retry == null ? null : Duration(seconds: retry),
      );
    }
    return switch (response.statusCode) {
      401 => const BackendException(
        'unauthorized',
        'Sign in to October again.',
      ),
      404 => const BackendException(
        'not_found',
        "October doesn't know this computer.",
      ),
      _ => _unavailable,
    };
  }

  void close() => _client.close();
}
