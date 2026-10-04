import '../../protocol/models/status.dart';

/// How the simulator plays one job: its steps and how it ends.
class SimJob {
  const SimJob({
    required this.job,
    required this.steps,
    required this.result,
    this.resultForHer,
    this.keywords = const [],
  });

  final Job job;
  final List<({String say, String did})> steps;
  final String result;
  final String? resultForHer;

  /// Words that make the simulator pick this job when none is given.
  final List<String> keywords;
}

const simJobs = <SimJob>[
  SimJob(
    job: Job(
      id: 'wifi.check',
      title: 'Check the Wi-Fi and internet',
      scope: 'look',
    ),
    keywords: ['wifi', 'wi-fi', 'internet', 'router'],
    steps: [
      (say: 'Checking the Wi-Fi connection', did: 'Read the network status'),
      (say: 'Testing the internet speed', did: 'Ran a speed test: 48 Mbps'),
      (say: 'Checking the router', did: 'The router answers'),
    ],
    result: 'Wi-Fi looks fine right now. The internet is fast.',
    resultForHer: 'Your Wi-Fi is working well.',
  ),
  SimJob(
    job: Job(
      id: 'call.join',
      title: 'Join a call',
      scope: 'change',
      may: ['open', 'call'],
    ),
    keywords: ['call', 'zoom', 'discord', 'meet', 'join'],
    steps: [
      (say: 'Opening the invite', did: 'Opened the invite link'),
      (say: 'Opening the call app', did: 'Opened the app'),
      (say: 'Joining the call', did: 'Joined the call'),
    ],
    result: "Joined. She's in the call.",
    resultForHer: "You're in the call.",
  ),
  SimJob(
    job: Job(
      id: 'find.show',
      title: 'Find an email or file',
      scope: 'change',
      may: ['open'],
    ),
    keywords: ['find', 'email', 'file', 'photo', 'document'],
    steps: [
      (say: 'Searching her email and files', did: 'Searched for it'),
      (say: 'Opening what I found', did: 'Opened it on her screen'),
    ],
    result: 'Found it and left it open on her screen.',
    resultForHer: "It's open on your screen.",
  ),
  SimJob(
    job: Job(
      id: 'make.bigger',
      title: 'Make text or sound bigger',
      scope: 'change',
      may: ['settings'],
    ),
    keywords: ['bigger', 'larger', 'louder', 'volume', 'text size', 'zoom in'],
    steps: [
      (say: 'Opening display settings', did: 'Opened Settings'),
      (say: 'Making the text bigger', did: 'Set text size to 125%'),
    ],
    result: 'Done: text is bigger now.',
    resultForHer: 'I made the text bigger.',
  ),
  SimJob(
    job: Job(
      id: 'app.install',
      title: 'Install an app',
      scope: 'change',
      may: ['open', 'install'],
    ),
    keywords: ['install', 'download'],
    steps: [
      (say: 'Opening the app store', did: 'Opened the store'),
      (say: 'Downloading the app', did: 'Downloaded it'),
      (say: 'Installing', did: 'Installed it'),
    ],
    result: "Installed. It's on her desktop.",
    resultForHer: 'The new app is on your desktop.',
  ),
  SimJob(
    job: Job(
      id: 'screen.describe',
      title: "Say what's on screen",
      scope: 'look',
    ),
    keywords: ['screen', "what's on", 'what is on', 'looking at'],
    steps: [(say: 'Looking at her screen', did: 'Read the screen')],
    result: 'Her email is open. Nothing looks wrong.',
  ),
];

/// Used when no curated job fits the words.
const generalJob = SimJob(
  job: Job(
    id: 'general',
    title: 'Something else',
    scope: 'change',
    may: ['other'],
  ),
  steps: [
    (say: 'Looking at her screen', did: 'Read the screen'),
    (say: 'Working on it', did: 'Did what was asked'),
  ],
  result: 'Done.',
);

SimJob? simJobById(String id) {
  if (id == generalJob.job.id) return generalJob;
  for (final j in simJobs) {
    if (j.job.id == id) return j;
  }
  return null;
}

/// Picks a job from the words, checking the most specific jobs first
/// ("Install Zoom" is an install, not a call).
SimJob guessSimJob(String text) {
  const priority = [
    'app.install',
    'make.bigger',
    'call.join',
    'wifi.check',
    'find.show',
    'screen.describe',
  ];
  final lower = text.toLowerCase();
  for (final id in priority) {
    final j = simJobById(id)!;
    if (j.keywords.any(lower.contains)) return j;
  }
  return generalJob;
}

/// A hard limit the simulator enforces, with Octo's sentence for the family.
({String result, String forHer})? hardLimitFor(String text, String person) {
  final lower = text.toLowerCase();
  if (RegExp(r'password|passcode|one-time code|\botp\b|2fa').hasMatch(lower)) {
    return (
      result:
          'I stopped: this needs her password. I never type passwords. '
          'You could call $person and help her sign in.',
      forHer: 'I stopped: this needs your password.',
    );
  }
  if (RegExp(r'\bbank|credit card|card number|payment').hasMatch(lower)) {
    return (
      result:
          'I stopped: this is a bank or payment page. I never work on '
          'those. You could look at it together on a call.',
      forHer: 'I stopped: I never work on bank or payment pages.',
    );
  }
  if (RegExp(r'\bbuy\b|\bpay\b|purchase|\bsign the\b').hasMatch(lower)) {
    return (
      result:
          'I stopped: this would pay for or sign something. '
          'I never pay, buy or sign anything.',
      forHer: 'I stopped: I never pay, buy or sign anything.',
    );
  }
  return null;
}
