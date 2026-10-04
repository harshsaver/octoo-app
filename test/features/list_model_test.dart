import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/data/db/database.dart';
import 'package:octo_family/data/session/reducer.dart';
import 'package:octo_family/data/session/session_data.dart';
import 'package:octo_family/data/thread/projection.dart';
import 'package:octo_family/features/octos_list/list_model.dart';
import 'package:octo_family/l10n/app_localizations_en.dart';
import 'package:octo_family/protocol/models/task.dart';
import 'package:octo_family/transport/octo_link.dart';
import 'package:octo_family/ui/octo_avatar.dart';

final _l = AppLocalizationsEn();
final _now = DateTime(2026, 10, 5, 12);

ComputerRow _row(
  String id, {
  bool pinned = false,
  int sortOrder = 0,
  int lastReadAt = 0,
}) => ComputerRow(
  id: id,
  computerName: '$id laptop',
  person: id,
  look: 'orange',
  role: 'owner',
  pinned: pinned,
  muted: false,
  sortOrder: sortOrder,
  lastReadAt: lastReadAt,
  addedAt: 0,
  profileGen: 0,
  profileSyncedGen: 0,
  tombstone: false,
);

OctoRowModel _model(ComputerRow row, List<SessionEvent> events) {
  final data = events.fold(SessionData(computerId: row.id), reduce);
  return buildRowModel(
    computer: row,
    data: data,
    thread: projectThread(data, const MeIdentity(name: 'Harsh')),
    l: _l,
    now: _now,
  );
}

Task _task(String status, {int steps = 0, String? result}) => Task(
  id: 't1',
  text: 'Join the call',
  status: status,
  steps: [for (var i = 1; i <= steps; i++) TaskStep(n: i)],
  result: result,
  createdAt: _now.millisecondsSinceEpoch - 60000,
  endedAt: status == 'done' ? _now.millisecondsSinceEpoch - 1000 : null,
);

void main() {
  final mom = _row('Mom');

  test('live states replace the preview line', () {
    final working = _model(mom, [
      TaskReceived(_task('running', steps: 1), null),
    ]);
    expect(
      (working.kind, working.preview, working.mood),
      (PreviewKind.working, 'Working… step 2', OctoMood.working),
    );

    final waiting = _model(mom, [TaskReceived(_task('waitingOk'), null)]);
    expect(
      (waiting.kind, waiting.preview),
      (PreviewKind.waiting, 'Waiting for Mom to say OK'),
    );

    final offline = _model(mom, [
      LinkChanged(
        LinkState.connected,
        _now.millisecondsSinceEpoch - 2 * 3600 * 1000,
      ),
      LinkChanged(
        LinkState.offline,
        _now.millisecondsSinceEpoch - 2 * 3600 * 1000,
      ),
    ]);
    expect(
      (offline.kind, offline.preview, offline.mood),
      (PreviewKind.offline, 'Offline · last seen 2 h ago', OctoMood.sleepy),
    );

    final help = _model(mom, [
      HelpReceived(_now.millisecondsSinceEpoch, 'Printer'),
    ]);
    expect(
      (help.kind, help.preview, help.unread),
      (PreviewKind.needsHand, 'Mom needs a hand', true),
    );
  });

  test('otherwise the latest thing; the result beats its own screenshot', () {
    final done = _model(mom, [
      TaskReceived(
        _task('done', result: 'Done: text is bigger now.'),
        const LocalShot('x'),
      ),
    ]);
    expect(
      (done.kind, done.preview),
      (PreviewKind.latest, 'Done: text is bigger now.'),
    );
    expect(done.celebrateKey, 't1');
    expect(_model(mom, const []).kind, PreviewKind.empty);
  });

  test('unread is anything not from this phone after lastReadAt', () {
    final read = _model(_row('Mom', lastReadAt: _now.millisecondsSinceEpoch), [
      TaskReceived(_task('done', result: 'ok'), null),
    ]);
    expect(read.unread, isFalse);
    final unread = _model(_row('Mom', lastReadAt: 1), [
      TaskReceived(_task('done', result: 'ok'), null),
    ]);
    expect(unread.unread, isTrue);
  });

  test('ordering: pinned first, then help, then latest activity', () {
    final rows = orderRows([
      _model(_row('Old'), [TaskReceived(_task('done', result: 'ok'), null)]),
      _model(_row('Help'), [HelpReceived(1, 'x')]),
      _model(_row('Pinned', pinned: true), const []),
      _model(_row('New'), [
        TaskReceived(
          _task(
            'done',
            result: 'ok',
          ).copyWith(id: 't2', createdAt: _now.millisecondsSinceEpoch),
          null,
        ),
      ]),
    ]);
    expect(rows.map((r) => r.computer.id), ['Pinned', 'Help', 'New', 'Old']);
    expect(matchesSearch(rows[0], 'pinned lap'), isTrue);
    expect(matchesSearch(rows[0], 'zzz'), isFalse);
  });
}
