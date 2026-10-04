import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

DateTime _local(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// The time on the right of a list row: "now", "9:41", "Yesterday", "Mon",
/// or a date.
String listTime(AppLocalizations l, int at, DateTime now) {
  final t = _local(at);
  if (now.difference(t).inSeconds.abs() < 60) return l.timeNow;
  if (_sameDay(t, now)) return DateFormat.jm(l.localeName).format(t);
  if (_sameDay(t, now.subtract(const Duration(days: 1)))) {
    return l.timeYesterday;
  }
  if (now.difference(t).inDays < 6) return DateFormat.E(l.localeName).format(t);
  return DateFormat.yMd(l.localeName).format(t);
}

/// "just now", "5 min ago", "2 h ago", "3 d ago".
String agoText(AppLocalizations l, int at, DateTime now) {
  final d = now.difference(_local(at));
  if (d.inMinutes < 1) return l.agoJustNow;
  if (d.inHours < 1) return l.agoMinutes(d.inMinutes);
  if (d.inDays < 1) return l.agoHours(d.inHours);
  return l.agoDays(d.inDays);
}

/// The grey line between groups in a thread.
String threadStamp(AppLocalizations l, int at, DateTime now) {
  final t = _local(at);
  final time = DateFormat.jm(l.localeName).format(t);
  if (_sameDay(t, now)) return time;
  if (_sameDay(t, now.subtract(const Duration(days: 1)))) {
    return '${l.timeYesterday} $time';
  }
  if (now.difference(t).inDays < 6) {
    return '${DateFormat.EEEE(l.localeName).format(t)} $time';
  }
  return '${DateFormat.yMMMd(l.localeName).format(t)} $time';
}
