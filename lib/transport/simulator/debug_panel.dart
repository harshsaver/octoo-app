import 'dart:async';

import 'package:flutter/material.dart';

import 'simulated_computer.dart';
import 'simulator_link.dart';

/// Plays Mom (brief §7.1): answers her computer's questions and makes things
/// happen on it. Developer-only; exists in fake mode.
class DebugPanel extends StatefulWidget {
  const DebugPanel({
    super.key,
    required this.link,
    this.computerId,
    this.scrollController,
  });

  final SimulatorLink link;
  final ScrollController? scrollController;

  /// The computer to start on; defaults to the one being paired, else the
  /// first.
  final String? computerId;

  static Future<void> show(
    BuildContext context,
    SimulatorLink link, {
    String? computerId,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => DebugPanel(
        link: link,
        computerId: computerId,
        scrollController: controller,
      ),
    ),
  );

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  final _subs = <StreamSubscription<void>>[];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.computerId;
    _subs.add(widget.link.changes.listen((_) => _resubscribe()));
    _resubscribe();
  }

  void _resubscribe() {
    for (final s in _subs.skip(1)) {
      s.cancel();
    }
    _subs.removeRange(1, _subs.length);
    for (final c in _all) {
      _subs.add(
        c.changes.listen((_) {
          if (mounted) setState(() {});
        }),
      );
    }
    if (mounted) setState(() {});
  }

  List<SimulatedComputer> get _all => [
    ?widget.link.pairingComputer,
    ...widget.link.computers,
  ];

  SimulatedComputer? get _computer {
    final all = _all;
    if (all.isEmpty) return null;
    return all.firstWhere(
      (c) => c.computerId == _selectedId,
      orElse: () => widget.link.pairingComputer ?? all.first,
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.link.settings;
    final computer = _computer;
    final theme = Theme.of(context);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text('Simulator · play Mom', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (computer == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No simulated computers yet. Pair one first.'),
          )
        else ...[
          DropdownButton<String>(
            isExpanded: true,
            value: computer.computerId,
            items: [
              for (final c in _all)
                DropdownMenuItem(
                  value: c.computerId,
                  child: Text(
                    '${c.computerName}${c.isPairing ? ' (pairing)' : ''}'
                    '${c.online ? '' : ' · offline'}',
                  ),
                ),
            ],
            onChanged: (id) => setState(() => _selectedId = id),
          ),
          _Waiting(computer: computer),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _action(
                'Mom says OK',
                computer.consents.isEmpty ? null : computer.momSaysOk,
              ),
              _action(
                'Mom says no',
                computer.consents.isEmpty ? null : computer.momSaysNo,
              ),
              _action(
                'Mom approves the rules',
                computer.consents.any((c) => c.kind == ConsentKind.policy)
                    ? () => computer.momSaysOk(kind: ConsentKind.policy)
                    : null,
              ),
              _action(
                'Mom sends a to-do',
                computer.isPairing ? null : computer.sendTodo,
              ),
              _action(
                'Mom asks for help',
                computer.isPairing ? null : () => computer.askForHelp(),
              ),
              _action(
                computer.online
                    ? 'Computer goes offline'
                    : 'Computer comes back',
                computer.online ? computer.goOffline : computer.goOnline,
              ),
              _action(
                'Priya asks Octo',
                computer.isPairing ? null : () => computer.otherHelperAsks(),
              ),
              _action(
                'Mom removes you',
                computer.isPairing
                    ? null
                    : () => widget.link.removeMe(computer.computerId),
              ),
            ],
          ),
        ],
        const Divider(height: 32),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mom answers OK by herself'),
          subtitle: Text('After ${settings.momDelay.inMilliseconds / 1000} s'),
          value: settings.autopilot,
          onChanged: (v) => setState(() => settings.autopilot = v),
        ),
        const SizedBox(height: 8),
        Text('Next pairing', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<SimPairingScript>(
          segments: const [
            ButtonSegment(
              value: SimPairingScript.normal,
              label: Text('Normal'),
            ),
            ButtonSegment(
              value: SimPairingScript.wrongCode,
              label: Text('Wrong code'),
            ),
            ButtonSegment(
              value: SimPairingScript.codeExpires,
              label: Text('Expires'),
            ),
          ],
          selected: {settings.pairingScript},
          onSelectionChanged: (s) =>
              setState(() => settings.pairingScript = s.single),
        ),
        if (computer != null) ...[
          const Divider(height: 32),
          Text("Mom's screen", style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final line in computer.momScreen.reversed.take(12))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(line, style: theme.textTheme.bodyMedium),
            ),
        ],
      ],
    );
  }

  Widget _action(String label, VoidCallback? onPressed) =>
      FilledButton.tonal(onPressed: onPressed, child: Text(label));
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.computer});

  final SimulatedComputer computer;

  @override
  Widget build(BuildContext context) {
    final consents = computer.consents;
    if (consents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Nothing is waiting for Mom.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in consents)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('Waiting for Mom: ${c.prompt}'),
          ),
      ],
    );
  }
}
