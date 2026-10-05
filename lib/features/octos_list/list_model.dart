import '../../data/db/database.dart';
import '../../data/session/session_data.dart';
import '../../data/thread/projection.dart';
import '../../l10n/app_localizations.dart';
import '../../protocol/models/task.dart';
import '../../transport/octo_link.dart';
import '../../ui/labels.dart';
import '../../ui/octo_avatar.dart';
import '../../ui/time_format.dart';

/// What the preview line is showing.
enum PreviewKind {
  /// The latest thing in the thread.
  latest,

  /// "Working… step 2", in the working colour, with a pulse.
  working,

  /// "Waiting for Mom to say OK".
  waiting,

  /// "Offline · last seen 2 h ago", in grey.
  offline,

  /// "Mom needs a hand", with a red dot; the row moves to the top.
  needsHand,

  /// Nothing yet.
  empty,
}

class OctoRowModel {
  const OctoRowModel({
    required this.computer,
    required this.kind,
    required this.preview,
    required this.mood,
    required this.unread,
    this.latestAt,
    this.latestIncomingAt,
    this.celebrateKey,
  });

  final ComputerRow computer;
  final PreviewKind kind;
  final String preview;
  final OctoMood mood;
  final bool unread;

  /// The newest thing in the thread (orders the list; the time on the right).
  final int? latestAt;

  /// The newest thing not from this phone (unread state).
  final int? latestIncomingAt;

  /// Changes when a task finishes done (the avatar wiggles).
  final String? celebrateKey;

  bool get needsHand => kind == PreviewKind.needsHand;
}

/// The row for one computer (brief §5.2). Pure.
OctoRowModel buildRowModel({
  required ComputerRow computer,
  required SessionData? data,
  required List<ThreadEntry> thread,
  required AppLocalizations l,
  required DateTime now,
}) {
  final person = computer.person;
  ThreadItem? latest;
  int? latestIncomingAt;
  for (final e in thread.reversed) {
    final item = e.item;
    if (item is TimestampItem) continue;
    // Octo's own screenshot follows its result; the result reads better.
    if (item is ImageItem && item.source == ImageSource.octo) continue;
    latest ??= item;
    if (latestIncomingAt == null && item.side == ThreadSide.left) {
      latestIncomingAt = item.at;
    }
    if (latestIncomingAt != null) break;
  }

  Task? running;
  Task? waiting;
  for (final t in data?.tasks.values ?? const <TrackedTask>[]) {
    if (t.task.phase == TaskPhase.running) running = t.task;
    if (t.task.phase == TaskPhase.waitingOk) waiting = t.task;
  }
  final link = data?.link;
  final offline = link == LinkState.offline && data?.lastSeenAt != null;

  final (
    PreviewKind kind,
    String text,
    OctoMood mood,
  ) = data?.activeHelp != null
      ? (PreviewKind.needsHand, l.previewNeedsHand(person), OctoMood.idle)
      : running != null
      ? (
          PreviewKind.working,
          l.previewWorking(running.steps.length + 1),
          OctoMood.working,
        )
      : waiting != null
      ? (PreviewKind.waiting, l.previewWaiting(person), OctoMood.waiting)
      : link == LinkState.notOcto
      ? (PreviewKind.offline, l.previewNotOcto, OctoMood.sleepy)
      : offline
      ? (
          PreviewKind.offline,
          l.previewOffline(agoText(l, data!.lastSeenAt!, now)),
          OctoMood.sleepy,
        )
      : latest == null
      ? (PreviewKind.empty, l.previewEmpty, OctoMood.idle)
      : (PreviewKind.latest, _latestText(l, latest, person), OctoMood.idle);

  final helpAt = data?.activeHelp?.since;
  final incoming = [
    ?latestIncomingAt,
    ?helpAt,
  ].fold<int?>(null, (m, v) => m == null || v > m ? v : m);
  return OctoRowModel(
    computer: computer,
    kind: kind,
    preview: text,
    mood: offline && kind != PreviewKind.needsHand ? OctoMood.sleepy : mood,
    unread: incoming != null && incoming > computer.lastReadAt,
    latestAt: latest?.at ?? helpAt,
    latestIncomingAt: incoming,
    celebrateKey: lastDoneKey(data),
  );
}

/// An id for the most recent task that finished done; a new one means
/// "wiggle". Null when none has.
String? lastDoneKey(SessionData? data) {
  Task? last;
  for (final t in data?.tasks.values ?? const <TrackedTask>[]) {
    final task = t.task;
    if (task.phase != TaskPhase.done) continue;
    if (last == null || (task.endedAt ?? 0) > (last.endedAt ?? 0)) last = task;
  }
  return last == null ? 'none' : last.id;
}

String _latestText(AppLocalizations l, ThreadItem item, String person) =>
    switch (item) {
      RequestItem(:final text, :final mine) =>
        mine == true ? l.previewYou(text) : text,
      OctoTaskItem(:final task) =>
        task.phase == TaskPhase.running
            ? (task.say ?? l.statusWorking)
            : task.phase.isEnded
            ? (task.result ?? taskResultFallback(l, task.phase, person))
            : taskPhaseLabel(l, task.phase, person),
      OctoNoteItem(:final text) => text,
      ImageItem() => l.previewPhoto,
      TodoItem(:final todo) => todo.text,
      HelpItem() => l.previewNeedsHand(person),
      MessageItem(:final text, :final mine) => mine ? l.previewYou(text) : text,
      SystemItem(:final kind, :final text) => switch (kind) {
        SystemKind.log => text ?? '',
        SystemKind.askedScreen => l.askedScreen(person),
        SystemKind.screenRefused => l.screenRefused(person),
      },
      TimestampItem() => '',
    };

/// Pinned first (in their order), then help requests, then latest activity.
List<OctoRowModel> orderRows(List<OctoRowModel> rows) {
  int rank(OctoRowModel r) => r.computer.pinned ? 0 : (r.needsHand ? 1 : 2);
  final sorted = [...rows];
  sorted.sort((a, b) {
    final c = rank(a).compareTo(rank(b));
    if (c != 0) return c;
    if (a.computer.pinned) {
      return a.computer.sortOrder.compareTo(b.computer.sortOrder);
    }
    final at = (b.latestAt ?? b.computer.addedAt).compareTo(
      a.latestAt ?? a.computer.addedAt,
    );
    return at;
  });
  return sorted;
}

/// Matches the search field against her name and the computer's name.
bool matchesSearch(OctoRowModel row, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return row.computer.person.toLowerCase().contains(q) ||
      row.computer.computerName.toLowerCase().contains(q);
}
