/// What the test Octo's AI can do on the laptop it runs on. Looking is
/// free; anything run in a shell is shown to the person at the laptop first
/// and only runs on their OK.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// One tool the AI may call.
class OctoTool {
  const OctoTool({
    required this.name,
    required this.description,
    required this.properties,
    required this.run,
    this.required = const [],
  });

  final String name;
  final String description;

  /// JSON Schema properties of the input object.
  final Map<String, Object?> properties;
  final List<String> required;
  final Future<ToolOutput> Function(Map<String, Object?> input) run;

  /// The Messages API definition (strict: inputs always match the schema).
  Map<String, Object?> get definition => {
    'name': name,
    'description': description,
    'strict': true,
    'input_schema': {
      'type': 'object',
      'properties': properties,
      'required': required,
      'additionalProperties': false,
    },
  };
}

class ToolOutput {
  const ToolOutput({required this.did, required this.text, this.say, this.jpeg, this.ok = true});

  /// The step as the helper sees it ("Checked the Wi-Fi").
  final String did;
  final String? say;

  /// What the AI reads back.
  final String text;
  final Uint8List? jpeg;
  final bool ok;
}

/// Runs a program; output is trimmed to [limit] characters.
Future<({int code, String out})> runProcess(
  String executable,
  List<String> args, {
  Duration timeout = const Duration(seconds: 20),
  int limit = 8000,
}) async {
  try {
    final r = await Process.run(executable, args, stdoutEncoding: utf8, stderrEncoding: utf8).timeout(timeout);
    var out = '${r.stdout}${(r.stderr as String).isEmpty ? '' : '\n[stderr]\n${r.stderr}'}'.trim();
    if (out.length > limit) out = '${out.substring(0, limit)}\n… (cut)';
    return (code: r.exitCode, out: out);
  } on TimeoutException {
    return (code: -1, out: 'timed out after ${timeout.inSeconds} s');
  } on ProcessException catch (e) {
    return (code: -1, out: '${e.executable} is not available: ${e.message}');
  }
}

Future<String> _sh(String script) async => (await runProcess('bash', ['-c', script])).out;

/// The screen as a JPEG (≤ 1600 px, the size the AI reads best), through
/// the desktop portal; the portal's PNG is deleted afterwards.
Future<Uint8List> captureScreen(String helperScript) async {
  final shot = await runProcess('python3', [helperScript, '20'], timeout: const Duration(seconds: 30));
  final path = shot.out.split('\n').first.trim();
  if (shot.code != 0 || !path.endsWith('.png')) throw StateError('screenshot failed: ${shot.out}');
  final file = File(path);
  try {
    final jpeg = await Process.run('magick', [path, '-resize', '1600x1600>', '-quality', '80', 'jpg:-'], stdoutEncoding: null);
    if (jpeg.exitCode == 0) return Uint8List.fromList(jpeg.stdout as List<int>);
    return await file.readAsBytes();
  } finally {
    if (await file.exists()) await file.delete();
  }
}

String jpegDataUri(Uint8List jpeg) =>
    'data:image/${jpeg.length > 3 && jpeg[0] == 0x89 ? 'png' : 'jpeg'};base64,${base64Encode(jpeg)}';

/// The tools. [approveCommand] asks the person at the laptop before any
/// shell command runs; [showOnScreen] puts a line on her screen.
List<OctoTool> laptopTools({
  required String screenshotScript,
  required Future<bool> Function(String command, String why) approveCommand,
  required void Function(String line) showOnScreen,
}) => [
  OctoTool(
    name: 'take_screenshot',
    description: 'Capture what is on the computer screen right now. Use it to see what she sees.',
    properties: const {},
    run: (_) async {
      final jpeg = await captureScreen(screenshotScript);
      return ToolOutput(did: 'Looked at the screen', say: 'Looking at the screen…', text: 'Screenshot attached.', jpeg: jpeg);
    },
  ),
  OctoTool(
    name: 'check_network',
    description:
        'Network health: connection state, Wi-Fi name and signal, default route, DNS, and a ping to the internet.',
    properties: const {},
    run: (_) async => ToolOutput(
      did: 'Checked the network',
      say: 'Checking the Wi-Fi…',
      text: await _sh(r'''
echo "== state"; nmcli -t general status 2>&1
echo "== wifi (in use)"; nmcli -t -f IN-USE,SSID,SIGNAL,RATE,SECURITY dev wifi 2>&1 | grep '^\*' || echo "not on Wi-Fi"
echo "== devices"; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev 2>&1
echo "== route"; ip route show default 2>&1
echo "== dns"; getent hosts example.com 2>&1 || echo "DNS lookup failed"
echo "== ping"; ping -c 3 -W 2 1.1.1.1 2>&1 | tail -2
'''),
    ),
  ),
  OctoTool(
    name: 'system_overview',
    description: 'The computer at a glance: OS, uptime, CPU load, memory, disk space, battery.',
    properties: const {},
    run: (_) async => ToolOutput(
      did: 'Checked the computer',
      say: 'Checking the computer…',
      text: await _sh(r'''
echo "== os"; . /etc/os-release 2>/dev/null; echo "$PRETTY_NAME"; uname -r
echo "== host"; hostname
echo "== uptime"; uptime
echo "== memory"; free -h
echo "== disk"; df -h / /home 2>/dev/null | uniq
echo "== battery"; b=$(upower -e 2>/dev/null | grep -m1 BAT); [ -n "$b" ] && upower -i "$b" | grep -E "state|percentage|time to" || echo "no battery"
'''),
    ),
  ),
  OctoTool(
    name: 'list_processes',
    description: 'The programs using the most CPU or memory right now.',
    properties: const {
      'sort_by': {
        'type': 'string',
        'enum': ['cpu', 'memory'],
      },
    },
    required: const ['sort_by'],
    run: (input) async {
      final key = input['sort_by'] == 'memory' ? '-%mem' : '-%cpu';
      return ToolOutput(
        did: 'Looked at the running programs',
        say: 'Looking at what’s running…',
        text: (await runProcess('ps', ['-eo', 'pid,comm,%cpu,%mem,etime', '--sort=$key'])).out.split('\n').take(25).join('\n'),
      );
    },
  ),
  OctoTool(
    name: 'run_command',
    description:
        'Run one bash command on the computer (Linux, GNOME). The person at the computer sees the command and '
        'your reason, and it only runs if they say OK. Use it for anything the other tools do not cover, '
        'including changes such as settings (gsettings), opening apps or pages (xdg-open), or diagnostics. '
        'Prefer one clear command over chains.',
    properties: const {
      'command': {'type': 'string', 'description': 'The bash command.'},
      'why': {'type': 'string', 'description': 'One short sentence, in plain words, for the person approving it.'},
    },
    required: const ['command', 'why'],
    run: (input) async {
      final command = input['command']! as String;
      final why = input['why']! as String;
      if (!await approveCommand(command, why)) {
        return ToolOutput(did: 'Asked to run a command; she said no', text: 'Not run: the person said no.', ok: false);
      }
      final r = await runProcess('bash', ['-c', command], timeout: const Duration(seconds: 60));
      return ToolOutput(
        did: why,
        say: 'Working on it…',
        text: 'exit code ${r.code}\n${r.out}',
        ok: r.code == 0,
      );
    },
  ),
  OctoTool(
    name: 'tell_her',
    description: 'Show a short, friendly message on her screen (for example what you are about to do, or what to click).',
    properties: const {
      'text': {'type': 'string'},
    },
    required: const ['text'],
    run: (input) async {
      showOnScreen('Octo: ${input['text']}');
      return ToolOutput(did: 'Told her: ${input['text']}', text: 'Shown.');
    },
  ),
];
