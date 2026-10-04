import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../protocol/app_message.dart';
import '../../protocol/host_message.dart';
import '../octo_link.dart';
import 'simulated_computer.dart';

/// An [OctoLink] to computers simulated in the app (brief §7.1), for
/// development, demos and tests. Only built in fake mode.
///
/// Every message crosses a JSON encode/decode with [latency], so the app sees
/// exactly what a wire would carry. Messages her computer sends while the
/// link is down are lost, as they would be over the relay.
class SimulatorLink implements OctoLink {
  SimulatorLink({
    SimulatorSettings? settings,
    Random? random,
    this.latency = const Duration(milliseconds: 150),
    this.reconnectDelay = const Duration(seconds: 1),
  }) : settings = settings ?? SimulatorSettings(),
       _random = random ?? Random();

  final SimulatorSettings settings;
  final Duration latency;
  final Duration reconnectDelay;
  final Random _random;

  final Map<String, _Endpoint> _endpoints = {};

  /// Computers whose pairing failed in a way that allows another try, by
  /// payload: scanning the same code again reaches the same computer, so
  /// wrong tries add up.
  final Map<String, SimulatedComputer> _retryable = {};
  final _changes = StreamController<void>.broadcast(sync: true);
  SimulatedComputer? _pairingComputer;

  /// Paired computers, in pairing order.
  List<SimulatedComputer> get computers => [
    for (final e in _endpoints.values) e.computer,
  ];

  /// The computer being paired right now, if any.
  SimulatedComputer? get pairingComputer => _pairingComputer;

  /// This app's helper id on [computerId] (what `task.from` says for tasks
  /// sent from here).
  String? helperIdFor(String computerId) => _endpoints[computerId]?.helperId;

  /// Fires when computers are added or removed.
  Stream<void> get changes => _changes.stream;

  // ---------------------------------------------------------------------
  // OctoLink

  @override
  Stream<PairingProgress> pair(
    String qrPayloadOrCode, {
    required String helperName,
    required String deviceLabel,
  }) {
    late final StreamController<PairingProgress> out;
    SimulatedComputer? computer;
    final subs = <StreamSubscription<Object?>>[];
    final timers = <Timer>[];
    var finished = false;
    var paired = false;
    var retryable = false;

    void cleanUp() {
      for (final s in subs) {
        s.cancel();
      }
      for (final t in timers) {
        t.cancel();
      }
      if (!paired) {
        computer?.cancelPairing();
        if (retryable && computer != null) {
          _retryable.remove(qrPayloadOrCode)?.dispose();
          _retryable[qrPayloadOrCode] = computer!;
        } else if (computer != null) {
          // Not synchronously: this can run inside one of its own events.
          scheduleMicrotask(computer!.dispose);
        }
      }
      if (_pairingComputer == computer) {
        _pairingComputer = null;
        _changes.add(null);
      }
    }

    void finish(PairingProgress last) {
      if (finished) return;
      finished = true;
      out.add(last);
      cleanUp();
      out.close();
    }

    void later(void Function() action) {
      timers.add(
        Timer(latency, () {
          if (!finished) action();
        }),
      );
    }

    out = StreamController<PairingProgress>(
      onListen: () {
        final name = _computerNameFrom(qrPayloadOrCode);
        if (name == null) {
          finish(
            const PairingFailed(
              kind: PairingFailureKind.invalidCode,
              isFinal: false,
            ),
          );
          return;
        }
        final c = computer =
            _retryable.remove(qrPayloadOrCode) ??
            SimulatedComputer(
              computerId: 'c_${_hex(8)}',
              hostId: 'h_${_hex(12)}',
              computerName: name.computer,
              person: name.person,
              settings: settings,
              random: _random,
            );
        _pairingComputer = c;
        _changes.add(null);
        final helperId = 'u_${_hex(8)}';
        out.add(PairingScanned(name.computer));

        subs.add(
          c.outbound.listen((raw) {
            final message = parseHostMessage(_wire(raw));
            later(() {
              switch (message) {
                case PairCodeMessage(:final code):
                  out.add(
                    PairingCompareCode(code, (match) async {
                      if (finished) return;
                      if (!match) {
                        finish(
                          const PairingFailed(
                            kind: PairingFailureKind.codeMismatch,
                            isFinal: true,
                          ),
                        );
                        return;
                      }
                      out.add(const PairingWaitingForHer());
                      later(
                        () => c.receive(
                          _wire(PairConfirm(code: code).toJson()),
                          from: helperId,
                        ),
                      );
                    }),
                  );
                case PairDoneMessage():
                  paired = true;
                  _register(
                    _Endpoint(
                      computer: c,
                      helperId: helperId,
                      helperName: helperName,
                      device: deviceLabel,
                    ),
                  );
                  finish(
                    PairingPaired(
                      PairedComputer(
                        computerId: c.computerId,
                        hostId: message.hostId,
                        computerName: message.computer ?? c.computerName,
                        person: message.person,
                      ),
                    ),
                  );
                case PairFailedMessage():
                  retryable = !message.isFinal;
                  finish(
                    PairingFailed(
                      kind: PairingFailureKind.reportedByComputer,
                      isFinal: message.isFinal,
                      reason: message.reason,
                    ),
                  );
                default:
                  break;
              }
            });
          }),
        );
        subs.add(
          c.onlineChanges.listen((online) {
            if (!online) {
              finish(
                const PairingFailed(
                  kind: PairingFailureKind.offline,
                  isFinal: false,
                ),
              );
            }
          }),
        );
        timers.add(
          Timer(const Duration(minutes: 6), () {
            finish(
              const PairingFailed(
                kind: PairingFailureKind.timedOut,
                isFinal: false,
              ),
            );
          }),
        );
        later(
          () => c.receive(
            _wire(
              PairRequest(
                token: qrPayloadOrCode,
                name: helperName,
                device: deviceLabel,
              ).toJson(),
            ),
            from: helperId,
          ),
        );
      },
      onCancel: () {
        if (finished) return;
        finished = true;
        cleanUp();
      },
    );
    return out.stream;
  }

  @override
  Stream<LinkState> connect(String computerId) {
    late final StreamController<LinkState> out;
    final endpoint = _endpointFor(computerId);
    StreamSubscription<bool>? onlineSub;
    void Function()? onRemoved;
    Timer? attempt;
    var attached = false;

    void detach() {
      if (attached) {
        attached = false;
        endpoint.attached--;
      }
    }

    void tryConnect(Duration delay) {
      attempt?.cancel();
      out.add(LinkState.connecting);
      attempt = Timer(delay, () {
        if (endpoint.computer.online && !endpoint.removed) {
          if (!attached) {
            attached = true;
            endpoint.attached++;
          }
          out.add(LinkState.connected);
        } else {
          out.add(LinkState.offline);
        }
      });
    }

    out = StreamController<LinkState>(
      onListen: () {
        onlineSub = endpoint.computer.onlineChanges.listen((online) {
          if (online) {
            tryConnect(reconnectDelay);
          } else {
            attempt?.cancel();
            detach();
            out.add(LinkState.offline);
          }
        });
        endpoint.onRemoved.add(
          onRemoved = () {
            attempt?.cancel();
            detach();
            out.add(LinkState.offline);
          },
        );
        tryConnect(latency);
      },
      onCancel: () {
        attempt?.cancel();
        onlineSub?.cancel();
        endpoint.onRemoved.remove(onRemoved);
        detach();
        out.close();
      },
    );
    return out.stream;
  }

  @override
  Future<void> send(String computerId, Map<String, Object?> message) async {
    final endpoint = _endpoints[computerId];
    if (endpoint == null || !endpoint.connected) {
      throw LinkUnavailableException(computerId);
    }
    final copy = _wire(message);
    Timer(latency, () {
      if (endpoint.computer.online && !endpoint.removed) {
        endpoint.computer.receive(copy, from: endpoint.helperId);
        if (copy['type'] == 'leave') endpoint.markRemoved();
      }
    });
  }

  @override
  Stream<Map<String, Object?>> messages(String computerId) =>
      _endpointFor(computerId).messages.stream;

  @override
  Future<void> unpair(String computerId) async {
    final endpoint = _endpoints.remove(computerId);
    if (endpoint == null) return;
    endpoint.dispose();
    endpoint.computer.dispose();
    _changes.add(null);
  }

  // ---------------------------------------------------------------------
  // Debug panel helpers

  SimulatedComputer? computer(String computerId) =>
      _endpoints[computerId]?.computer;

  /// Mom removes this phone from [computerId].
  void removeMe(String computerId) {
    final endpoint = _endpoints[computerId];
    if (endpoint == null) return;
    endpoint.computer.removeHelper(endpoint.helperId);
  }

  void dispose() {
    for (final c in _retryable.values) {
      c.dispose();
    }
    for (final e in _endpoints.values) {
      e.dispose();
      e.computer.dispose();
    }
    _endpoints.clear();
    _changes.close();
  }

  // ---------------------------------------------------------------------

  void _register(_Endpoint endpoint) {
    _endpoints[endpoint.computer.computerId] = endpoint;
    endpoint.outboundSub = endpoint.computer.outbound.listen((raw) {
      if (!endpoint.connected) return; // lost, as over the relay
      final copy = _wire(raw);
      Timer(latency, () {
        if (!endpoint.connected || endpoint.messages.isClosed) return;
        endpoint.messages.add(copy);
        if (copy['type'] == 'removed') endpoint.markRemoved();
      });
    });
    _changes.add(null);
  }

  /// The endpoint for [computerId], recreating a computer the simulator has
  /// forgotten (the app restarted; the simulator keeps nothing on disk).
  _Endpoint _endpointFor(String computerId) {
    final existing = _endpoints[computerId];
    if (existing != null) return existing;
    final computer = SimulatedComputer(
      computerId: computerId,
      hostId: 'h_${_hex(12)}',
      computerName: "Mom's laptop",
      settings: settings,
      random: _random,
    );
    final helperId = 'u_${_hex(8)}';
    final name = settings.helperName;
    final device = "$name's phone";
    computer.helpers[helperId] = SimHelper(
      id: helperId,
      name: name,
      device: device,
    );
    final endpoint = _Endpoint(
      computer: computer,
      helperId: helperId,
      helperName: name,
      device: device,
    );
    _register(endpoint);
    return endpoint;
  }

  static const _defaults = [
    (computer: "Mom's laptop", person: 'Mom'),
    (computer: "Dad's PC", person: 'Dad'),
    (computer: "Grandma's iMac", person: 'Grandma'),
  ];

  /// Accepts `octo-sim:<computer name>`, an October enrollment link, or an
  /// 8-character code. Anything else is not a code this simulator knows.
  ({String computer, String person})? _computerNameFrom(String payload) {
    final p = payload.trim();
    final fallback = _defaults[_endpoints.length % _defaults.length];
    if (p.startsWith('octo-sim:')) {
      final name = p.substring('octo-sim:'.length).trim();
      if (name.isEmpty) return fallback;
      final possessive = RegExp(r"^(.+?)'s ").firstMatch(name);
      return (computer: name, person: possessive?.group(1) ?? fallback.person);
    }
    final uri = Uri.tryParse(p);
    if (uri != null &&
        uri.scheme == 'https' &&
        (uri.host == 'www.october.dev' || uri.host == 'october.dev') &&
        uri.path == '/octo/add' &&
        RegExp(r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$').hasMatch(uri.fragment)) {
      return fallback;
    }
    if (RegExp(r'^[A-Za-z0-9]{8}$').hasMatch(p)) return fallback;
    return null;
  }

  String _hex(int length) => List.generate(
    length,
    (_) => _random.nextInt(16).toRadixString(16),
  ).join();

  static Map<String, Object?> _wire(Map<String, Object?> message) =>
      jsonDecode(jsonEncode(message)) as Map<String, Object?>;
}

class _Endpoint {
  _Endpoint({
    required this.computer,
    required this.helperId,
    required this.helperName,
    required this.device,
  });

  final SimulatedComputer computer;
  final String helperId;
  final String helperName;
  final String device;
  final messages = StreamController<Map<String, Object?>>.broadcast();
  StreamSubscription<Map<String, Object?>>? outboundSub;
  final List<void Function()> onRemoved = [];

  /// Open `connect` streams currently attached.
  int attached = 0;

  /// Her computer removed this phone (`removed`) or it left.
  bool removed = false;

  bool get connected => attached > 0 && computer.online && !removed;

  void markRemoved() {
    if (removed) return;
    removed = true;
    for (final f in onRemoved.toList()) {
      f();
    }
  }

  void dispose() {
    outboundSub?.cancel();
    messages.close();
  }
}
