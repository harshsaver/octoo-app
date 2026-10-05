/// The laptop the test Octo runs on: its screen, its network, and hands
/// (mouse, keyboard, opening links and apps) for the backend agent's steps.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Runs a program; output is trimmed to [limit] characters.
Future<({int code, String out})> runProcess(
  String executable,
  List<String> args, {
  Duration timeout = const Duration(seconds: 20),
  int limit = 8000,
}) async {
  try {
    final r = await Process.run(executable, args, stdoutEncoding: utf8, stderrEncoding: utf8).timeout(timeout);
    var out = '${r.stdout}${(r.stderr as String).isEmpty ? '' : '\n${r.stderr}'}'.trim();
    if (out.length > limit) out = '${out.substring(0, limit)}\n… (cut)';
    return (code: r.exitCode, out: out);
  } on TimeoutException {
    return (code: -1, out: 'timed out after ${timeout.inSeconds} s');
  } on ProcessException catch (e) {
    return (code: -1, out: '${e.executable} is not available: ${e.message}');
  }
}

/// A screenshot as the backend takes it: PNG, at most 1,600 px wide and
/// 4 MB.
class Shot {
  const Shot(this.png, this.width, this.height);

  final Uint8List png;
  final int width;
  final int height;

  String get dataUri => 'data:image/png;base64,${base64Encode(png)}';
}

const _maxBytes = 4 * 1024 * 1024;

/// The screen through the desktop portal; the portal's file is deleted.
Future<Shot> captureScreen(String helperScript) async {
  final shot = await runProcess('python3', [helperScript, '20'], timeout: const Duration(seconds: 30));
  final path = shot.out.split('\n').first.trim();
  if (shot.code != 0 || !path.endsWith('.png')) throw StateError('screenshot failed: ${shot.out}');
  final file = File(path);
  try {
    for (final width in [1600, 1280, 1024]) {
      final r = await Process.run('magick', [path, '-resize', '${width}x>', '-strip', 'png:-'], stdoutEncoding: null);
      if (r.exitCode != 0) throw StateError('could not resize the screenshot (ImageMagick)');
      final png = Uint8List.fromList(r.stdout as List<int>);
      if (png.length <= _maxBytes) {
        final view = ByteData.sublistView(png);
        return Shot(png, view.getUint32(16), view.getUint32(20));
      }
    }
    throw StateError('the screenshot stays over 4 MB');
  } finally {
    if (await file.exists()) await file.delete();
  }
}

/// A short, plain summary of the network for a `check: wifi` step.
Future<String> checkNetwork() async {
  final state = (await runProcess('nmcli', ['-t', '-f', 'STATE,CONNECTIVITY', 'general'])).out;
  final wifi = (await runProcess('bash', ['-c', r"nmcli -t -f IN-USE,SSID,SIGNAL dev wifi 2>/dev/null | grep '^\*' | head -1"])).out;
  final wired = (await runProcess('bash', ['-c', r"nmcli -t -f TYPE,STATE dev | grep '^ethernet:connected' | head -1"])).out;
  final ping = await runProcess('ping', ['-c', '2', '-W', '2', '1.1.1.1']);
  final dns = await runProcess('getent', ['hosts', 'october.dev']);
  final parts = <String>[
    'network: ${state.isEmpty ? 'unknown' : state}',
    if (wifi.isNotEmpty) 'Wi-Fi: ${wifi.split(':').skip(1).join(' signal ')}%' else 'not on Wi-Fi',
    if (wired.isNotEmpty) 'wired connection up',
    ping.code == 0 ? 'internet reachable' : 'internet NOT reachable',
    dns.code == 0 ? 'DNS works' : 'DNS fails',
  ];
  return parts.join('; ');
}

/// What the agent's `act` steps do. Coordinates are pixels in the
/// screenshot the agent was shown.
abstract class Hands {
  Future<void> click(int x, int y, {required Shot on, bool double = false});
  Future<void> type(String text);
  Future<void> keys(List<String> keys);
  Future<void> scroll(int dx, int dy);
  Future<void> openUrl(String url);
  Future<void> openApp(String name);
  Future<void> close();
}

/// Mouse and keyboard through bin/control.py (the RemoteDesktop portal);
/// links and apps through xdg-open and gtk-launch.
class PortalHands implements Hands {
  PortalHands(this.controlScript, this.tokenFile);

  final String controlScript;
  final String tokenFile;
  Process? _process;
  StreamIterator<String>? _replies;
  Future<void> _queue = Future.value();

  Future<Map<String, Object?>> _send(Map<String, Object?> command) {
    final done = Completer<Map<String, Object?>>();
    _queue = _queue.then((_) async {
      try {
        if (_process == null) {
          final p = _process = await Process.start('python3', [controlScript, tokenFile]);
          _replies = StreamIterator(p.stdout.transform(utf8.decoder).transform(const LineSplitter()));
          unawaited(p.stderr.drain<void>());
        }
        _process!.stdin.writeln(jsonEncode(command));
        // The first command may wait for "Allow remote interaction?".
        if (!await _replies!.moveNext().timeout(const Duration(minutes: 3))) throw StateError('control helper exited');
        final reply = jsonDecode(_replies!.current) as Map<String, Object?>;
        if (reply['ok'] != true) throw StateError('${reply['error']}');
        done.complete(reply);
      } on Object catch (e) {
        done.completeError(e);
      }
    });
    return done.future;
  }

  @override
  Future<void> click(int x, int y, {required Shot on, bool double = false}) =>
      _send({'op': 'click', 'fx': x / on.width, 'fy': y / on.height, 'double': double});

  @override
  Future<void> type(String text) => _send({'op': 'type', 'text': text});

  @override
  Future<void> keys(List<String> keys) => _send({'op': 'keys', 'keys': keys});

  @override
  Future<void> scroll(int dx, int dy) => _send({'op': 'scroll', 'dx': dx.sign * (dx.abs() / 100).ceil(), 'dy': dy.sign * (dy.abs() / 100).ceil()});

  @override
  Future<void> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) throw StateError('only web links can be opened');
    final r = await runProcess('xdg-open', [url]);
    if (r.code != 0) throw StateError(r.out);
  }

  @override
  Future<void> openApp(String name) async {
    // The installed app whose Name matches, by its .desktop file.
    final found = await runProcess('bash', [
      '-c',
      r'''
n="$1"
dirs="$HOME/.local/share/applications /usr/share/applications /var/lib/flatpak/exports/share/applications $HOME/.local/share/flatpak/exports/share/applications"
for pattern in "^Name=$n\$" "^Name=.*$n"; do
  for d in $dirs; do
    [ -d "$d" ] || continue
    f=$(grep -lis -- "$pattern" "$d"/*.desktop 2>/dev/null | head -1)
    [ -n "$f" ] && { echo "$f"; exit 0; }
  done
done
''',
      'find',
      name,
    ]);
    final path = found.out.split('\n').firstWhere((l) => l.endsWith('.desktop'), orElse: () => '');
    if (path.isEmpty) throw StateError('no app called "$name" is installed');
    final r = await runProcess('gtk-launch', [path.split('/').last.replaceAll('.desktop', '')]);
    if (r.code != 0) throw StateError(r.out);
  }

  @override
  Future<void> close() async {
    _process?.kill();
    _process = null;
  }
}
