import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/policy_edit.dart';
import '../../data/session/computer_session.dart';
import '../../l10n/app_localizations.dart';
import '../../protocol/models/policy.dart';
import '../../protocol/models/task.dart';
import '../../transport/octo_link.dart';
import '../../ui/grouped_list.dart';
import '../../ui/labels.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

/// The categories offered under "Never…" (brief §5.5), in order.
const _neverChoices = [
  ChangeKind.install,
  ChangeKind.delete,
  ChangeKind.send,
  ChangeKind.settings,
  ChangeKind.signIn,
  ChangeKind.call,
];

final _domain = RegExp(r'^(?=.{1,253}$)([a-z0-9-]{1,63}\.)+[a-z]{2,63}$');

/// Her rules. The switches show only what her computer last reported; an
/// edit sends the whole proposed policy, and each changed item says whether
/// it's being applied or waiting for her.
class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key, required this.computerId});

  final String computerId;

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  final _site = TextEditingController();
  late final int _openedAt = DateTime.now().millisecondsSinceEpoch;

  @override
  void dispose() {
    _site.dispose();
    super.dispose();
  }

  Future<void> _send(Policy proposed, String person) async {
    final session = ref
        .read(sessionsControllerProvider)
        .session(widget.computerId);
    if (session == null) return;
    final l = AppLocalizations.of(context);
    final outcome = await session.setPolicy(proposed);
    if (!mounted) return;
    final message = switch (outcome) {
      PolicySent() || PolicyNotSent() => null,
      PolicyOffline() => l.rulesOffline(person),
      PolicyRefused(:final message) =>
        message == null || message.isEmpty ? l.ruleRefusedPlain : message,
      PolicyNoReply() => l.ruleNoReply,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = OctoTheme.of(context);
    final person = ref.watch(computerProvider(widget.computerId))?.person ?? '';
    final data = ref.watch(sessionDataProvider(widget.computerId)).value;
    final active = data?.policy ?? data?.status?.policy ?? const Policy();
    final edit = data?.policyEdit;
    final online = data?.link == LinkState.connected;
    final canEdit = online && edit == null;

    String? pendingLabel(String item) => switch (edit?.pending[item]) {
      PolicyChange.tighten => l.ruleApplying,
      PolicyChange.loosen => l.ruleWaiting(person),
      null => null,
    };

    Widget? subtitle(String item) {
      final label = pendingLabel(item);
      return label == null
          ? null
          : Text(label, style: TextStyle(color: colors.working));
    }

    final declinedAt = data?.policyDeclinedAt;
    final unknownNever = active.never
        .where((v) => ChangeKind.fromWire(v) == ChangeKind.unknown)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.rules)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: OctoSpace.xxl),
        children: [
          if (!online)
            Padding(
              padding: const EdgeInsets.all(OctoSpace.lg),
              child: Text(
                l.rulesOffline(person),
                style: TextStyle(color: colors.secondaryLabel),
              ),
            ),
          if (declinedAt != null && declinedAt >= _openedAt - 10 * 60 * 1000)
            Padding(
              padding: const EdgeInsets.all(OctoSpace.lg),
              child: Text(
                l.ruleKeptOld(person),
                style: TextStyle(color: colors.needsYou),
              ),
            ),
          GroupedSection(
            footer: l.rulesLooserNote(person),
            children: [
              SwitchListTile(
                title: Text(l.rulesAskEveryChange),
                subtitle: subtitle(PolicyItems.askEveryChange),
                value: active.askEveryChange,
                onChanged: canEdit
                    ? (v) => _send(active.copyWith(askEveryChange: v), person)
                    : null,
              ),
              SwitchListTile(
                title: Text(l.rulesAskBeforeLooking),
                subtitle: subtitle(PolicyItems.askBeforeLooking),
                value: active.askBeforeLooking,
                onChanged: canEdit
                    ? (v) => _send(active.copyWith(askBeforeLooking: v), person)
                    : null,
              ),
            ],
          ),
          GroupedSection(
            title: l.rulesNever,
            children: [
              for (final kind in _neverChoices)
                SwitchListTile(
                  title: Text(changeKindLabel(l, kind)),
                  subtitle: subtitle(PolicyItems.never(kind.name)),
                  value: active.never.contains(kind.name),
                  onChanged: canEdit
                      ? (on) => _send(
                          active.copyWith(
                            never: on
                                ? [...active.never, kind.name]
                                : [
                                    for (final v in active.never)
                                      if (v != kind.name) v,
                                  ],
                          ),
                          person,
                        )
                      : null,
                ),
              // Values this app doesn't know stay as they are; they show as
              // "Something else" and round-trip unchanged.
              for (final v in unknownNever)
                ListTile(
                  title: Text(changeKindLabel(l, ChangeKind.unknown)),
                  subtitle: Text(v),
                ),
            ],
          ),
          GroupedSection(
            title: l.rulesSites,
            children: [
              for (final site in active.blockedSites)
                ListTile(
                  title: Text(site),
                  subtitle: subtitle(PolicyItems.site(site)),
                  trailing: IconButton(
                    tooltip: l.removeSite(site),
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: canEdit
                        ? () => _send(
                            active.copyWith(
                              blockedSites: [
                                for (final s in active.blockedSites)
                                  if (s != site) s,
                              ],
                            ),
                            person,
                          )
                        : null,
                  ),
                ),
              for (final MapEntry(:key)
                  in (edit?.pending.entries ??
                      const <MapEntry<String, PolicyChange>>[]))
                if (key.startsWith('site:') &&
                    !active.blockedSites.contains(key.substring(5)))
                  ListTile(
                    title: Text(key.substring(5)),
                    subtitle: subtitle(key),
                  ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: OctoSpace.lg),
                child: TextField(
                  controller: _site,
                  enabled: canEdit,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l.addSite,
                    hintText: l.siteHint,
                  ),
                  onSubmitted: (value) {
                    final site = value
                        .trim()
                        .toLowerCase()
                        .replaceFirst(RegExp(r'^https?://'), '')
                        .split('/')
                        .first;
                    if (!_domain.hasMatch(site)) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(l.invalidSite)));
                      return;
                    }
                    _site.clear();
                    if (active.blockedSites.contains(site)) return;
                    _send(
                      active.copyWith(
                        blockedSites: [...active.blockedSites, site],
                      ),
                      person,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
