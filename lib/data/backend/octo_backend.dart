/// The October backend (brief §8), behind an interface so the app runs end
/// to end with [FakeBackend] until the endpoints exist. `HttpBackend` comes
/// with stage 4.
library;

class BackendComputer {
  const BackendComputer({
    required this.id,
    required this.name,
    required this.person,
    this.language,
    this.os,
    this.role = 'owner',
    this.lastSeenAt,
    this.octo,
  });

  final String id;

  /// The computer's name ("Mom's laptop").
  final String name;

  /// Her name ("Mom").
  final String person;
  final String? language;
  final String? os;

  /// `owner` or `helper`.
  final String role;
  final int? lastSeenAt;

  /// The Octo look id.
  final String? octo;

  BackendComputer copyWith({
    String? name,
    String? person,
    String? language,
    String? octo,
  }) => BackendComputer(
    id: id,
    name: name ?? this.name,
    person: person ?? this.person,
    language: language ?? this.language,
    os: os,
    role: role,
    lastSeenAt: lastSeenAt,
    octo: octo ?? this.octo,
  );
}

/// `{"error":{"code","message"}}`. Show [message]; [code] is never shown.
class BackendException implements Exception {
  const BackendException(this.code, this.message);

  final String code;
  final String message;

  /// Link to the plan page on october.dev for these.
  bool get needsPlan => code == 'plan_required' || code == 'credit_exhausted';

  @override
  String toString() => 'BackendException($code)';
}

abstract class OctoBackend {
  /// `GET /api/octo/computers`.
  Future<List<BackendComputer>> listComputers();

  /// `POST /api/octo/computers/claim`: makes this person the owner.
  Future<void> claim({required String enrollId, required String secret});

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
}

/// In-memory backend for fake mode and tests. Computers appear on the first
/// `PATCH` after pairing (the real mapping between claim and the relay
/// pairing is contract question 1).
class FakeBackend implements OctoBackend {
  final Map<String, BackendComputer> _computers = {};

  /// Makes the next call fail with this (tests).
  BackendException? failNext;

  @override
  Future<List<BackendComputer>> listComputers() async {
    _maybeFail();
    return _computers.values.toList();
  }

  @override
  Future<void> claim({required String enrollId, required String secret}) async {
    _maybeFail();
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

  void _maybeFail() {
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }
}
