import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../app/app_settings.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/octo_avatar.dart';
import '../../ui/tokens.dart';

/// Face ID, fingerprint or the phone's passcode.
abstract class DeviceAuth {
  Future<bool> isAvailable();

  Future<bool> authenticate(String reason);
}

class LocalDeviceAuth implements DeviceAuth {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } on Object {
      return false;
    }
  }
}

final deviceAuthProvider = Provider<DeviceAuth>((ref) => LocalDeviceAuth());

/// How long the app may be in the background before it locks again.
const lockAfter = Duration(minutes: 1);

/// Covers the app with a lock screen when the app lock is on: at a cold
/// start, and on resume after [lockAfter] in the background.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late bool _locked = ref.read(appSettingsProvider).appLock;
  DateTime? _backgroundSince;
  bool _authenticating = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () {
        if (!_authenticating) _backgroundSince ??= clock.now();
      },
      onShow: () {
        final since = _backgroundSince;
        _backgroundSince = null;
        if (_authenticating || since == null) return;
        if (ref.read(appSettingsProvider).appLock &&
            clock.now().difference(since) >= lockAfter) {
          setState(() => _locked = true);
          _promptSoon();
        }
      },
    );
    if (_locked) _promptSoon();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _promptSoon() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());

  Future<void> _unlock() async {
    if (_authenticating || !mounted) return;
    _authenticating = true;
    final ok = await ref
        .read(deviceAuthProvider)
        .authenticate(AppLocalizations.of(context).unlockReason);
    _authenticating = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    // Turning the lock off in Settings unlocks at once.
    ref.listen(appSettingsProvider.select((s) => s.appLock), (_, on) {
      if (!on && _locked) setState(() => _locked = false);
    });
    if (!_locked) return widget.child;
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        Offstage(child: widget.child),
        Positioned.fill(
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OctoAvatar(size: 120, mood: OctoMood.sleepy),
                    const SizedBox(height: OctoSpace.xl),
                    Text(
                      l.lockTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: OctoSpace.xl),
                    FilledButton.icon(
                      onPressed: _unlock,
                      icon: const Icon(Icons.lock_open),
                      label: Text(l.unlock),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
