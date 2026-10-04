import 'dart:async';

/// The push kinds (brief §9, saturday `api/lib/_octo/push.js` KINDS).
const pushKinds = ['help', 'todo', 'consentWaiting', 'taskEnded', 'pairing'];

/// A push as it arrives: content-free. [title]/[body] are the server's fixed
/// sentences ("Mom needs a hand"); [computerId] and [kind] route a tap.
class PushMessage {
  const PushMessage({
    required this.computerId,
    required this.kind,
    this.taskId,
    this.title,
    this.body,
  });

  /// Reads the data payload `{computerId, kind, taskId?, title?, body?}`.
  /// Null when it isn't an Octo push.
  static PushMessage? fromData(Map<String, Object?> data) {
    final computerId = data['computerId'];
    final kind = data['kind'];
    if (computerId is! String ||
        computerId.isEmpty ||
        kind is! String ||
        !pushKinds.contains(kind)) {
      return null;
    }
    String? str(String key) =>
        data[key] is String && (data[key]! as String).isNotEmpty
        ? data[key]! as String
        : null;
    return PushMessage(
      computerId: computerId,
      kind: kind,
      taskId: str('taskId'),
      title: str('title'),
      body: str('body'),
    );
  }

  final String computerId;
  final String kind;
  final String? taskId;
  final String? title;
  final String? body;

  Map<String, String> toData() => {
    'computerId': computerId,
    'kind': kind,
    'taskId': ?taskId,
    'title': ?title,
    'body': ?body,
  };
}

/// Notifications on this phone (PLAN §3.10). Registration with October is
/// [PushRegistrar]'s job; this only talks to the platform.
abstract class PushService {
  /// Whether this build can receive pushes at all.
  bool get available;

  /// Prepares channels and listeners. Never asks for permission.
  Future<void> start();

  /// Asks once (the first time an Octo is added). True if allowed.
  Future<bool> requestPermission();

  /// This phone's push token, or null if push isn't available.
  Future<String?> token();

  /// New tokens (rotation).
  Stream<String> get tokenRefresh;

  /// A push arrived while the app is open: shown as an in-app banner.
  Stream<PushMessage> get foreground;

  /// A notification was tapped (cold start, background, or a local one).
  Stream<PushMessage> get taps;

  Future<void> dispose();
}

/// Fake mode, or a build without Firebase settings: no pushes.
class NoPush implements PushService {
  @override
  bool get available => false;

  final _taps = StreamController<PushMessage>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();

  @override
  Future<void> start() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<PushMessage> get foreground => _foreground.stream;

  @override
  Stream<PushMessage> get taps => _taps.stream;

  /// Simulates a push (tests and the simulator).
  void deliver(PushMessage message, {bool tapped = false}) =>
      (tapped ? _taps : _foreground).add(message);

  @override
  Future<void> dispose() async {
    await _taps.close();
    await _foreground.close();
  }
}
