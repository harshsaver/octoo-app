import '../protocol/models/policy.dart';

/// How a changed rule moves (PLAN §3.8 Rules).
enum PolicyChange {
  /// Stricter: her computer applies it at once ("Applying change").
  tighten,

  /// Looser: she must approve it ("Waiting for Mom to approve").
  loosen,
}

/// Rule items, as keys: `askEveryChange`, `askBeforeLooking`,
/// `never:<value>`, `site:<domain>`.
abstract final class PolicyItems {
  static const askEveryChange = 'askEveryChange';
  static const askBeforeLooking = 'askBeforeLooking';

  static String never(String value) => 'never:$value';

  static String site(String domain) => 'site:$domain';
}

/// What each changed item does, from the policy her computer last reported
/// ([active]) to the one being sent ([proposed]).
Map<String, PolicyChange> diffPolicy(Policy active, Policy proposed) {
  final out = <String, PolicyChange>{};
  void flag(String key, bool before, bool after) {
    if (before == after) return;
    out[key] = after ? PolicyChange.tighten : PolicyChange.loosen;
  }

  flag(
    PolicyItems.askEveryChange,
    active.askEveryChange,
    proposed.askEveryChange,
  );
  flag(
    PolicyItems.askBeforeLooking,
    active.askBeforeLooking,
    proposed.askBeforeLooking,
  );
  for (final v in {...active.never, ...proposed.never}) {
    flag(
      PolicyItems.never(v),
      active.never.contains(v),
      proposed.never.contains(v),
    );
  }
  for (final d in {...active.blockedSites, ...proposed.blockedSites}) {
    flag(
      PolicyItems.site(d),
      active.blockedSites.contains(d),
      proposed.blockedSites.contains(d),
    );
  }
  return out;
}

/// Whether [reported] already shows [proposed]'s value for [item].
bool itemReported(String item, Policy reported, Policy proposed) {
  if (item == PolicyItems.askEveryChange) {
    return reported.askEveryChange == proposed.askEveryChange;
  }
  if (item == PolicyItems.askBeforeLooking) {
    return reported.askBeforeLooking == proposed.askBeforeLooking;
  }
  if (item.startsWith('never:')) {
    final v = item.substring(6);
    return reported.never.contains(v) == proposed.never.contains(v);
  }
  if (item.startsWith('site:')) {
    final d = item.substring(5);
    return reported.blockedSites.contains(d) ==
        proposed.blockedSites.contains(d);
  }
  return true;
}

/// One rules edit in flight. Nothing is applied optimistically: the
/// switches show the reported policy, and [pending] says what's on its way.
class PolicyEdit {
  const PolicyEdit({
    required this.proposed,
    required this.pending,
    required this.startedAt,
  });

  final Policy proposed;
  final Map<String, PolicyChange> pending;
  final int startedAt;

  /// What's still pending once her computer reports [reported]. A declined
  /// edit drops the loosened items (she kept the old rule). Null when done.
  PolicyEdit? after(Policy reported, {required bool declined}) {
    final left = <String, PolicyChange>{
      for (final MapEntry(:key, :value) in pending.entries)
        if (!itemReported(key, reported, proposed) &&
            !(declined && value == PolicyChange.loosen))
          key: value,
    };
    return left.isEmpty
        ? null
        : PolicyEdit(proposed: proposed, pending: left, startedAt: startedAt);
  }
}
