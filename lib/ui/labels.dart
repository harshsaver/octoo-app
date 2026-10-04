import '../l10n/app_localizations.dart';
import '../protocol/models/task.dart';

/// How each task status reads (brief §7.2 table). [person] is her name.
String taskPhaseLabel(AppLocalizations l, TaskPhase phase, String person) =>
    switch (phase) {
      TaskPhase.queued => l.taskQueued,
      TaskPhase.waitingOk => l.taskWaitingOk(person),
      TaskPhase.running => l.taskRunning,
      TaskPhase.done => l.taskDone,
      TaskPhase.gaveUp => l.taskGaveUp,
      TaskPhase.blocked => l.taskBlocked,
      TaskPhase.refused => l.taskRefused,
      TaskPhase.declined => l.taskDeclined(person),
      TaskPhase.noAnswer => l.taskNoAnswer(person),
      TaskPhase.stopped => l.taskStopped,
      TaskPhase.failed => l.taskFailed,
      TaskPhase.unknown => l.taskUnknown,
    };

String changeKindLabel(AppLocalizations l, ChangeKind kind) => switch (kind) {
  ChangeKind.open => l.changeOpen,
  ChangeKind.install => l.changeInstall,
  ChangeKind.signIn => l.changeSignIn,
  ChangeKind.send => l.changeSend,
  ChangeKind.delete => l.changeDelete,
  ChangeKind.settings => l.changeSettings,
  ChangeKind.call => l.changeCall,
  ChangeKind.other => l.changeOther,
  ChangeKind.unknown => l.changeUnknown,
};

/// Octo's sentence for an ended task when her computer didn't send one.
String taskResultFallback(AppLocalizations l, TaskPhase phase, String person) =>
    switch (phase) {
      TaskPhase.done => l.resultDone,
      TaskPhase.gaveUp => l.resultGaveUp,
      TaskPhase.blocked => l.resultBlocked,
      TaskPhase.refused => l.resultRefused,
      TaskPhase.declined => l.resultDeclined(person),
      TaskPhase.noAnswer => l.resultNoAnswer(person),
      TaskPhase.stopped => l.resultStopped,
      TaskPhase.failed => l.resultFailed,
      _ => l.taskUnknown,
    };

String _mayVerb(AppLocalizations l, ChangeKind kind) => switch (kind) {
  ChangeKind.open => l.mayOpen,
  ChangeKind.install => l.mayInstall,
  ChangeKind.signIn => l.maySignIn,
  ChangeKind.send => l.maySend,
  ChangeKind.delete => l.mayDelete,
  ChangeKind.settings => l.maySettings,
  ChangeKind.call => l.mayCall,
  ChangeKind.other || ChangeKind.unknown => l.mayOther,
};

/// "Octo will ask Mom before it opens apps, installs apps and joins calls."
/// Null when the job changes nothing.
String? mayHint(AppLocalizations l, List<ChangeKind> kinds, String person) {
  final verbs = <String>[];
  for (final k in kinds) {
    final v = _mayVerb(l, k);
    if (!verbs.contains(v)) verbs.add(v);
  }
  if (verbs.isEmpty) return null;
  final actions = verbs.length == 1
      ? verbs.single
      : l.listAnd(verbs.sublist(0, verbs.length - 1).join(', '), verbs.last);
  return l.mayHint(person, actions);
}
