/// The test Octo, run on a laptop:
///
///     dart run tool/test_octo/main.dart --email you@example.com
///
/// Signs in to October with email and password (the same account as the
/// phone), connects to October's relay as a computer, and plays "Mom's
/// laptop" with the app's simulated computer. Type `pair` to show a QR code
/// for the app to scan. See tool/test_octo/README.md.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:octo_family/transport/relay/control_plane.dart';
import 'package:octo_family/transport/relay/encoding.dart';
import 'package:octo_family/transport/relay/noise.dart';
import 'package:octo_family/transport/simulator/simulated_computer.dart';
import 'package:qr/qr.dart';

import 'host_relay.dart';
import 'october_cloud.dart';
import 'test_octo.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('email', help: 'Your October account (the one signed in on the phone).')
    ..addOption('config', defaultsTo: 'config/real.json', help: 'Reads SUPABASE_URL and SUPABASE_ANON_KEY.')
    ..addOption('relay', defaultsTo: 'https://relay.afteroctober.xyz')
    ..addOption('state', help: 'Where this computer keeps its keys (default ~/.config/octo-test-host/state.json).')
    ..addOption('name', defaultsTo: "Mom's laptop", help: 'The computer name the phone sees.')
    ..addOption('person', defaultsTo: 'Mom')
    ..addFlag('autopilot', help: 'Mom answers every question by herself after a moment.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final args = parser.parse(arguments);
  if (args.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }

  final config = _readConfig(args.option('config')!);
  final authOrigin = Uri.parse(Platform.environment['SUPABASE_URL'] ?? config['SUPABASE_URL'] ?? 'https://auth.october.dev');
  final apiKey = Platform.environment['SUPABASE_ANON_KEY'] ?? config['SUPABASE_ANON_KEY'];
  if (apiKey == null) {
    stderr.writeln('No SUPABASE_ANON_KEY: pass --config or set the environment variable.');
    exit(64);
  }

  final lines = stdin.transform(utf8.decoder).transform(const LineSplitter()).asBroadcastStream();
  final email = args.option('email') ?? await _prompt(lines, 'October email: ');
  final password = Platform.environment['OCTO_TEST_PASSWORD'] ?? await _prompt(lines, 'Password: ', secret: true);

  final session = PasswordSession(authOrigin: authOrigin, apiKey: apiKey);
  try {
    await session.signIn(email, password);
  } on ControlPlaneException catch (e) {
    stderr.writeln('Sign-in failed: ${e.message}');
    exit(1);
  }
  _say('Signed in as $email.');

  final home = Platform.environment['HOME'] ?? '.';
  final stateFile = File(args.option('state') ?? '$home/.config/octo-test-host/state.json');
  final state = HostState.load(stateFile)..save(stateFile);
  final staticKey = await NoiseKeyPair.fromPrivateKey(b64urlDecode(state.staticKey));
  final sign = await SigningKey.fromSeed(b64urlDecode(state.signSeed));
  final control = ControlPlane(authOrigin: authOrigin, accessToken: session.accessToken, apiKey: apiKey);
  final platform = Platform.isMacOS ? 'mac' : (Platform.isWindows ? 'win' : 'linux');
  final cloud = OctoberHostCloud(
    control: control,
    hostId: state.hostId,
    sign: sign,
    staticPub: b64url(staticKey.publicKey),
    name: args.option('name')!,
    platform: platform,
  );

  final settings = SimulatorSettings(autopilot: args.flag('autopilot'));
  final computer = SimulatedComputer(
    computerId: 'test-octo',
    hostId: state.hostId,
    computerName: args.option('name')!,
    person: args.option('person')!,
    settings: settings,
  );

  final questions = <Completer<bool>>[];
  final octo = TestOcto(
    cloud: cloud,
    computer: computer,
    state: state,
    say: _say,
    save: () => state.save(stateFile),
    approve: (label, code) {
      _say('Let "$label" help on this computer? Check the phone shows $code. Type y or n.');
      final answer = Completer<bool>();
      questions.add(answer);
      return answer.future;
    },
  );
  octo.relay = HostRelay(
    relay: Uri.parse(args.option('relay')!),
    hostId: state.hostId,
    staticKey: staticKey,
    ticket: cloud.hostTicket,
    delegate: octo,
  );

  // Mom's screen: questions to answer, and what Octo shows her.
  final shownConsents = <Object>{};
  var screenLines = computer.momScreen.length;
  computer.changes.listen((_) {
    for (final c in computer.consents) {
      if (shownConsents.add(c)) _say('Mom is asked: "${c.prompt}" — type ok or no.');
    }
    shownConsents.retainAll(computer.consents);
    while (screenLines < computer.momScreen.length) {
      _say('Mom\'s screen: ${computer.momScreen[screenLines++]}');
    }
  });

  _say('Computer id ${state.hostId} (keys in ${stateFile.path}).');
  if (state.devices.isEmpty) {
    _say('Creating the first pairing code…');
    await _pair(cloud);
  } else {
    _say('${state.devices.length} phone(s) paired. Type pair to add another.');
  }
  await octo.relay.start();
  _help();

  await for (final raw in lines) {
    final line = raw.trim();
    final word = line.split(' ').first.toLowerCase();
    final rest = line.substring(word.length).trim();
    try {
      switch (word) {
        case 'y' || 'yes' || 'n' || 'no' when questions.isNotEmpty:
          questions.removeAt(0).complete(word.startsWith('y'));
        case 'ok' || 'no':
          if (computer.consents.isEmpty) {
            _say('Nothing to answer.');
          } else {
            word == 'ok' ? computer.momSaysOk() : computer.momSaysNo();
          }
        case 'pair':
          await _pair(cloud);
        case 'todo':
          computer.sendTodo();
          _say('Sent a to-do.');
        case 'help':
          if (rest.isEmpty) {
            _help();
          } else {
            computer.askForHelp(rest);
            _say('Mom asked for help.');
          }
        case 'sos':
          computer.askForHelp();
          _say('Mom asked for help.');
        case 'offline':
          computer.goOffline();
          await octo.relay.stop();
          _say('Offline.');
        case 'online':
          computer.goOnline();
          await octo.relay.start();
        case 'remove':
          await octo.removeAll();
          _say('Removed every phone.');
        case 'status':
          _say('Relay ${octo.relay.connected ? 'connected' : 'not connected'}; '
              '${state.devices.length} paired; ${octo.relay.sessions.length} connected now; '
              '${computer.tasks.length} task(s); autopilot ${settings.autopilot ? 'on' : 'off'}.');
        case 'auto':
          settings.autopilot = !settings.autopilot;
          _say('Autopilot ${settings.autopilot ? 'on' : 'off'}.');
        case 'quit' || 'exit':
          await octo.dispose();
          exit(0);
        case '':
          break;
        default:
          _say('Unknown command. Type help.');
      }
    } on Object catch (e) {
      _say('Error: $e');
    }
  }
  await octo.dispose();
}

Future<void> _pair(HostCloud cloud) async {
  final intent = await cloud.createPairing();
  final o = cloud as OctoberHostCloud;
  final payload = {
    'v': 2,
    'hostId': o.hostId,
    'hostStatic': o.staticPub,
    'intentId': intent.intentId,
    'secret': intent.secret,
    'exp': intent.expiresAt,
  };
  final link = 'https://october.dev/pair#${b64url(utf8.encode(jsonEncode(payload)))}';
  stdout.writeln();
  stdout.writeln(_qr(link));
  _say('Scan this in the app (Add an Octo). It works for 5 minutes. Link: $link');
}

/// The QR code in half-block characters, light on dark terminals.
String _qr(String text) {
  final code = QrImage(QrCode(payload: QrPayload.fromString(text), errorCorrectLevel: QrErrorCorrectLevel.low));
  const quiet = 2;
  final size = code.moduleCount;
  bool light(int x, int y) => x < 0 || y < 0 || x >= size || y >= size || !code.isDark(y, x);
  final out = StringBuffer();
  for (var y = -quiet; y < size + quiet; y += 2) {
    for (var x = -quiet; x < size + quiet; x++) {
      final top = light(x, y);
      final bottom = light(x, y + 1);
      out.write(top && bottom ? '█' : top ? '▀' : bottom ? '▄' : ' ');
    }
    out.writeln();
  }
  return out.toString();
}

void _help() => _say('''Commands:
  pair            new QR code for the app
  y / n           answer a pairing request
  ok / no         Mom answers the question on her screen
  todo            Mom saves a to-do for you
  sos | help <t>  Mom asks for help
  offline/online  the computer goes away / comes back
  remove          Mom removes every phone
  auto            toggle autopilot (Mom answers by herself)
  status, quit''');

void _say(String line) {
  final t = DateTime.now();
  final ts = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';
  stdout.writeln('[$ts] $line');
}

Map<String, String> _readConfig(String path) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return {for (final e in json.entries) e.key: '${e.value}'};
}

Future<String> _prompt(Stream<String> lines, String label, {bool secret = false}) async {
  stdout.write(label);
  if (secret && stdin.hasTerminal) stdin.echoMode = false;
  final value = await lines.first;
  if (secret && stdin.hasTerminal) {
    stdin.echoMode = true;
    stdout.writeln();
  }
  return value.trim();
}
