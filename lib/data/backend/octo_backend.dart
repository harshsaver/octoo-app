/// The October backend's Octo API (`/api/octo/*` in the saturday repo,
/// docs/OCTO_BACKEND.md), behind an interface: [FakeBackend] for fake mode
/// and tests, `HttpBackend` (http_backend.dart) for real mode.
library;

/// A computer this person helps with (`GET /api/octo/computers`).
class BackendComputer {
  const BackendComputer({
    required this.id,
    required this.name,
    required this.person,
    this.hostId,
    this.language,
    this.os,
    this.role = 'owner',
    this.lastSeenAt,
    this.octo,
    this.muted = false,
  });

  factory BackendComputer.fromJson(Map<String, Object?> json) {
    String? str(String key) =>
        json[key] is String ? json[key]! as String : null;
    final id = str('id');
    if (id == null) throw const FormatException('computer id');
    return BackendComputer(
      id: id,
      hostId: str('hostId'),
      name: str('name') ?? '',
      person: str('person') ?? '',
      language: str('language'),
      os: str('os'),
      role: str('role') ?? 'member',
      lastSeenAt: _epochMs(json['lastSeenAt']),
      octo: str('octo'),
      muted: json['muted'] == true,
    );
  }

  /// `cmp_…`.
  final String id;

  /// The relay host her computer registered (`h_…`).
  final String? hostId;

  /// The computer's name ("Mom's laptop").
  final String name;

  /// Her name ("Mom").
  final String person;
  final String? language;
  final String? os;

  /// `owner` or `member`.
  final String role;

  /// Epoch ms.
  final int? lastSeenAt;

  /// The Octo look id.
  final String? octo;

  /// This person muted it (055).
  final bool muted;

  BackendComputer copyWith({
    String? name,
    String? person,
    String? language,
    String? octo,
    bool? muted,
  }) => BackendComputer(
    id: id,
    hostId: hostId,
    name: name ?? this.name,
    person: person ?? this.person,
    language: language ?? this.language,
    os: os,
    role: role,
    lastSeenAt: lastSeenAt,
    octo: octo ?? this.octo,
    muted: muted ?? this.muted,
  );
}

int? _epochMs(Object? value) => switch (value) {
  final String s => DateTime.tryParse(s)?.millisecondsSinceEpoch,
  final num n => n.toInt(),
  _ => null,
};

/// What proves this person may claim a computer: the QR's enrollment id and
/// secret, or the code typed from her screen.
sealed class ClaimCredentials {
  const ClaimCredentials();

  Map<String, Object?> toJson();
}

final class ClaimByQr extends ClaimCredentials {
  const ClaimByQr({required this.enrollId, required this.claimSecret});

  final String enrollId;

  /// Held only in memory; never logged or stored.
  final String claimSecret;

  @override
  Map<String, Object?> toJson() => {
    'enrollId': enrollId,
    'claimSecret': claimSecret,
  };

  @override
  String toString() => 'ClaimByQr($enrollId)';
}

final class ClaimByCode extends ClaimCredentials {
  const ClaimByCode(this.code);

  /// Normalised Crockford base32, 8 characters.
  final String code;

  @override
  Map<String, Object?> toJson() => {'claimCode': code};

  @override
  String toString() => 'ClaimByCode';
}

/// `POST /api/octo/computers/claim` → the new computer.
class ClaimResult {
  const ClaimResult({this.computerId, this.hostId, this.name});

  /// Null from the fake backend: in fake mode the simulator's pairing
  /// decides the id.
  final String? computerId;
  final String? hostId;
  final String? name;
}

/// `GET /api/octo/usage`: this month's tasks, steps, questions and cost.
class Usage {
  const Usage({
    required this.tasks,
    required this.steps,
    required this.questions,
    required this.costAmount,
    required this.currency,
  });

  factory Usage.fromJson(Map<String, Object?> json) {
    int count(String key) => json[key] is num ? (json[key]! as num).toInt() : 0;
    final cost = json['cost'] is Map<String, Object?>
        ? json['cost']! as Map<String, Object?>
        : const <String, Object?>{};
    return Usage(
      tasks: count('tasks'),
      steps: count('steps'),
      questions: count('questions'),
      costAmount: cost['amount'] is num
          ? (cost['amount']! as num).toDouble()
          : 0,
      currency: cost['currency'] is String
          ? cost['currency']! as String
          : 'USD',
    );
  }

  final int tasks;
  final int steps;
  final int questions;
  final double costAmount;
  final String currency;
}

/// `{"error":{"code","message"}}`. Show [message]; [code] is never shown.
class BackendException implements Exception {
  const BackendException(this.code, this.message, {this.retryAfter});

  final String code;
  final String message;
  final Duration? retryAfter;

  /// Link to the plan page on october.dev for these.
  bool get needsPlan => code == 'plan_required' || code == 'credit_exhausted';

  @override
  String toString() => 'BackendException($code)';
}

abstract class OctoBackend {
  /// `GET /api/octo/computers`.
  Future<List<BackendComputer>> listComputers();

  /// `POST /api/octo/computers/claim`: makes this person the owner.
  Future<ClaimResult> claim(
    ClaimCredentials credentials, {
    String? person,
    String? computerName,
    String? language,
  });

  /// `PATCH /api/octo/computers/{id}`.
  Future<BackendComputer> patchComputer(
    String id, {
    String? name,
    String? person,
    String? language,
    String? octo,
  });

  /// `DELETE /api/octo/computers/{id}` (owner).
  Future<void> deleteComputer(String id);

  /// `GET /api/octo/usage?computerId=&month=` (month as `YYYY-MM`).
  Future<Usage> usage(String computerId, String month);

  /// `POST /api/octo/push/register`.
  Future<void> registerPush({
    required String token,
    required String platform,
    String? deviceLabel,
    String? appVersion,
  });

  /// `DELETE /api/octo/push/register`.
  Future<void> unregisterPush(String token);

  /// `PUT /api/octo/computers/{id}/mute`: this person's phones only.
  Future<void> setMuted(String computerId, bool muted);

  /// `GET /api/octo/push/preferences`: kinds turned off.
  Future<Set<String>> notifyPreferences();

  /// `PUT /api/octo/push/preferences`.
  Future<void> setNotifyPreferences(Set<String> off);
}

/// In-memory backend for fake mode and tests. Computers appear on the first
/// `PATCH` after pairing (in fake mode the simulator's pairing makes the id).
class FakeBackend implements OctoBackend {
  final Map<String, BackendComputer> _computers = {};
  final Set<String> pushTokens = {};
  Set<String> off = {};

  /// Makes the next call fail with this (tests).
  BackendException? failNext;

  @override
  Future<List<BackendComputer>> listComputers() async {
    _maybeFail();
    return _computers.values.toList();
  }

  @override
  Future<ClaimResult> claim(
    ClaimCredentials credentials, {
    String? person,
    String? computerName,
    String? language,
  }) async {
    _maybeFail();
    return ClaimResult(name: computerName);
  }

  @override
  Future<BackendComputer> patchComputer(
    String id, {
    String? name,
    String? person,
    String? language,
    String? octo,
  }) async {
    _maybeFail();
    final current =
        _computers[id] ??
        BackendComputer(id: id, name: name ?? '', person: person ?? '');
    return _computers[id] = current.copyWith(
      name: name,
      person: person,
      language: language,
      octo: octo,
    );
  }

  @override
  Future<void> deleteComputer(String id) async {
    _maybeFail();
    _computers.remove(id);
  }

  /// A made-up month, like the simulator's results.
  @override
  Future<Usage> usage(String computerId, String month) async {
    _maybeFail();
    return const Usage(
      tasks: 12,
      steps: 57,
      questions: 4,
      costAmount: 1.8,
      currency: 'USD',
    );
  }

  @override
  Future<void> registerPush({
    required String token,
    required String platform,
    String? deviceLabel,
    String? appVersion,
  }) async {
    _maybeFail();
    pushTokens.add(token);
  }

  @override
  Future<void> unregisterPush(String token) async {
    _maybeFail();
    pushTokens.remove(token);
  }

  @override
  Future<void> setMuted(String computerId, bool muted) async {
    _maybeFail();
    final c = _computers[computerId];
    if (c != null) _computers[computerId] = c.copyWith(muted: muted);
  }

  @override
  Future<Set<String>> notifyPreferences() async {
    _maybeFail();
    return {...off};
  }

  @override
  Future<void> setNotifyPreferences(Set<String> off) async {
    _maybeFail();
    this.off = {...off};
  }

  void _maybeFail() {
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }
}
