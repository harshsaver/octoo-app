// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Octo';

  @override
  String get notConfiguredTitle => 'This build isn\'t configured';

  @override
  String get notConfiguredBody =>
      'This copy of Octo can\'t connect to October yet. Install Octo from the App Store or Google Play.';

  @override
  String get taskQueued => 'Waiting its turn';

  @override
  String taskWaitingOk(String person) {
    return 'Waiting for $person';
  }

  @override
  String get taskRunning => 'Working';

  @override
  String get taskDone => 'Done';

  @override
  String get taskGaveUp => 'Back with you';

  @override
  String get taskBlocked => 'Stopped by a safety rule';

  @override
  String get taskRefused => 'Not allowed by your rules';

  @override
  String taskDeclined(String person) {
    return '$person said no';
  }

  @override
  String taskNoAnswer(String person) {
    return '$person didn\'t answer';
  }

  @override
  String get taskStopped => 'Stopped';

  @override
  String get taskFailed => 'Didn\'t work';

  @override
  String get taskUnknown =>
      'Octo sent an update this app can\'t show yet. Update the app.';

  @override
  String get changeOpen => 'Open apps';

  @override
  String get changeInstall => 'Install apps';

  @override
  String get changeSignIn => 'Sign in';

  @override
  String get changeSend => 'Send messages';

  @override
  String get changeDelete => 'Delete things';

  @override
  String get changeSettings => 'Change settings';

  @override
  String get changeCall => 'Join calls';

  @override
  String get changeOther => 'Other changes';

  @override
  String get changeUnknown => 'Something else';

  @override
  String get screenshotOnHerComputer => 'Screenshot on her computer';

  @override
  String get screenshotUnavailable => 'Screenshot no longer available';

  @override
  String get octosTitle => 'Octos';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get search => 'Search';

  @override
  String get addOcto => 'Add an Octo';

  @override
  String get settings => 'Settings';

  @override
  String get playMom => 'Play Mom (simulator)';

  @override
  String get emptyTitle => 'Add your first Octo';

  @override
  String get emptyHint =>
      'Open October on the family computer, go to Settings, then Phone access, and choose Add a phone.';

  @override
  String noMatches(String query) {
    return 'No Octos match “$query”';
  }

  @override
  String previewWorking(int step) {
    return 'Working… step $step';
  }

  @override
  String previewWaiting(String person) {
    return 'Waiting for $person to say OK';
  }

  @override
  String previewOffline(String ago) {
    return 'Offline · last seen $ago';
  }

  @override
  String previewNeedsHand(String person) {
    return '$person needs a hand';
  }

  @override
  String get previewEmpty => 'Ask Octo something';

  @override
  String get previewPhoto => 'Photo';

  @override
  String previewYou(String text) {
    return 'You: $text';
  }

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get remove => 'Remove';

  @override
  String get markRead => 'Read';

  @override
  String get markUnread => 'Unread';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String removeTitle(String person) {
    return 'Remove $person\'s Octo?';
  }

  @override
  String removeBodyOwner(String computer) {
    return '$computer will be removed for everyone who helps with it, not just you.';
  }

  @override
  String removeBodyHelper(String computer) {
    return 'You\'ll stop helping with $computer from this phone.';
  }

  @override
  String removeFailed(String message) {
    return 'Couldn\'t remove it. $message';
  }

  @override
  String removedBanner(String person) {
    return '$person\'s computer removed you';
  }

  @override
  String get unread => 'Unread';

  @override
  String get muted => 'Muted';

  @override
  String get pinned => 'Pinned';

  @override
  String get timeNow => 'now';

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String agoMinutes(int n) {
    return '$n min ago';
  }

  @override
  String agoHours(int n) {
    return '$n h ago';
  }

  @override
  String agoDays(int n) {
    return '$n d ago';
  }

  @override
  String get agoJustNow => 'just now';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusWorking => 'Working…';

  @override
  String get statusConnecting => 'Connecting…';

  @override
  String statusLastSeen(String ago) {
    return 'Last seen $ago';
  }

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusNotOcto => 'Not running Octo';

  @override
  String get previewNotOcto =>
      'This computer isn\'t running Octo. Remove it and pair with Octo\'s code.';

  @override
  String get askOctoPlaceholder => 'Ask Octo…';

  @override
  String tellPlaceholder(String person) {
    return 'Tell $person…';
  }

  @override
  String get toggleAskOcto => 'Ask Octo';

  @override
  String toggleTell(String person) {
    return 'Tell $person';
  }

  @override
  String get send => 'Send';

  @override
  String get quickJobs => 'Quick jobs';

  @override
  String composerOffline(String person) {
    return '$person\'s computer is offline. We\'ll send this when it\'s back.';
  }

  @override
  String composerRemoved(String person) {
    return '$person\'s computer removed you.';
  }

  @override
  String mayHint(String person, String actions) {
    return 'Octo will ask $person before it $actions.';
  }

  @override
  String charactersLeft(int n) {
    return '$n left';
  }

  @override
  String get mayOpen => 'opens apps';

  @override
  String get mayInstall => 'installs apps';

  @override
  String get maySignIn => 'signs in';

  @override
  String get maySend => 'sends messages';

  @override
  String get mayDelete => 'deletes things';

  @override
  String get maySettings => 'changes settings';

  @override
  String get mayCall => 'joins calls';

  @override
  String get mayOther => 'changes anything else';

  @override
  String listAnd(String a, String b) {
    return '$a and $b';
  }

  @override
  String get jobWifi => 'Check Wi-Fi';

  @override
  String get jobCall => 'Join a call';

  @override
  String get jobFind => 'Find an email or file';

  @override
  String get jobBigger => 'Bigger text or sound';

  @override
  String get jobInstall => 'Install an app';

  @override
  String get jobScreenDescribe => 'What\'s on screen?';

  @override
  String get jobSeeScreen => 'See her screen';

  @override
  String get jobWifiText => 'Check the Wi-Fi and internet';

  @override
  String get jobScreenDescribeText => 'What\'s on the screen right now?';

  @override
  String get jobCallPrefill => 'Join a call: ';

  @override
  String get jobFindPrefill => 'Find: ';

  @override
  String get jobBiggerPrefill => 'Make bigger: ';

  @override
  String get jobInstallPrefill => 'Install: ';

  @override
  String get lineWaitingTurn => 'Waiting its turn';

  @override
  String lineWaitingForHer(String person) {
    return 'Waiting for $person to say OK';
  }

  @override
  String lineSheSaidOk(String person) {
    return '$person said OK';
  }

  @override
  String get deliveryPending => 'Not sent yet';

  @override
  String get deliverySending => 'Sending…';

  @override
  String deliveryUncertain(String person) {
    return 'Couldn\'t confirm it reached $person\'s computer. Check the activity before trying again.';
  }

  @override
  String deliveryRejected(String message) {
    return 'Not sent: $message';
  }

  @override
  String get deliveryRejectedPlain => 'Her computer didn\'t take this.';

  @override
  String get retryNote => 'Sent again. It may run twice.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get stop => 'Stop';

  @override
  String get details => 'Details';

  @override
  String get reply => 'Reply';

  @override
  String get doIt => 'Octo, do it';

  @override
  String get seeHerScreen => 'See her screen';

  @override
  String get helpAsk => 'Can you take a look?';

  @override
  String askedScreen(String person) {
    return 'Asked $person to show her screen';
  }

  @override
  String screenRefused(String person) {
    return '$person said no to showing her screen';
  }

  @override
  String get resultDone => 'Done.';

  @override
  String get resultGaveUp => 'I couldn\'t finish this. It\'s back with you.';

  @override
  String get resultBlocked => 'I stopped because of a safety rule.';

  @override
  String get resultRefused => 'Your rules don\'t allow this.';

  @override
  String resultDeclined(String person) {
    return '$person said no.';
  }

  @override
  String resultNoAnswer(String person) {
    return '$person didn\'t answer.';
  }

  @override
  String get resultStopped => 'Stopped.';

  @override
  String get resultFailed => 'That didn\'t work.';

  @override
  String liveStep(int n) {
    return 'Step $n';
  }

  @override
  String get liveStarting => 'Starting…';

  @override
  String octoToldHer(String answer) {
    return 'Octo told her: $answer';
  }

  @override
  String replyingTo(String text) {
    return 'Replying to “$text”';
  }

  @override
  String fromName(String name) {
    return '$name → Octo';
  }

  @override
  String stopOffline(String person) {
    return '$person\'s computer is offline.';
  }

  @override
  String get stopRefused => 'That task already finished.';

  @override
  String get stopNoReply => 'No answer from her computer. It may still stop.';

  @override
  String welcome(String helper, String person) {
    return 'Hi $helper! I\'m $person\'s Octo. Ask me to do something on her computer, like check the Wi-Fi or make the text bigger. I\'ll always ask her first before changing anything.';
  }

  @override
  String bubbleLabel(String sender, String time, String text) {
    return '$sender, $time: $text';
  }

  @override
  String get octoName => 'Octo';

  @override
  String get youName => 'You';

  @override
  String get imageFromOcto => 'Screenshot from Octo';

  @override
  String imageFromHer(String person) {
    return 'Screenshot from $person';
  }

  @override
  String get share => 'Share';

  @override
  String get close => 'Close';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String timelineAsked(String name) {
    return '$name asked';
  }

  @override
  String get timelineStarted => 'Started';

  @override
  String get timelineEnded => 'Ended';

  @override
  String get activityMayBeMissing => 'Older activity may be missing';

  @override
  String get scanCaption =>
      'On the family computer, open October, go to Settings, then Phone access, and choose Add a phone. Point your camera at the code.';

  @override
  String get typeCodeInstead => 'Type the code instead';

  @override
  String get smallPrint =>
      'Only add a family member\'s computer while you\'re with them, or on a call with them.';

  @override
  String get useSimulator => 'Use a simulated computer';

  @override
  String get cameraUnavailable =>
      'The camera isn\'t available. You can type the code instead.';

  @override
  String get typeCodeTitle => 'Type the code';

  @override
  String get typeCodeHint => '8 letters or numbers';

  @override
  String get continueLabel => 'Continue';

  @override
  String get codeNotRecognised =>
      'That isn\'t an Octo code. Check it and try again.';

  @override
  String get connecting => 'Connecting…';

  @override
  String compareKeyBody(String computer) {
    return '$computer shows the same key. Check they match, and ask them to tap OK.';
  }

  @override
  String get theyMatch => 'They match';

  @override
  String get theyDontMatch => 'They don\'t match';

  @override
  String get mismatchExplain =>
      'The keys didn\'t match, so we stopped. Someone else may be trying to add this computer.';

  @override
  String waitingForOk(String computer) {
    return 'Waiting for someone to tap OK on $computer…';
  }

  @override
  String pairNotOcto(String computer) {
    return '$computer isn\'t running Octo. That code is for October\'s phone access; scan the code Octo shows instead.';
  }

  @override
  String pairOffline(String computer) {
    return '$computer went offline. Try again when it\'s back.';
  }

  @override
  String pairTimedOut(String computer) {
    return 'No one answered on $computer.';
  }

  @override
  String get pairNotAdded => 'Not added';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get nameTitle => 'Who is it for?';

  @override
  String get nameOther => 'Their name';

  @override
  String get languageTitle => 'Their language';

  @override
  String get computerNameLabel => 'The computer\'s name';

  @override
  String get next => 'Next';

  @override
  String get lookTitle => 'Pick their Octo';

  @override
  String setupFailed(String message) {
    return 'Couldn\'t finish setting up. $message';
  }

  @override
  String notificationsWhy(String person) {
    return 'So you know when $person needs you.';
  }

  @override
  String get detailsTitle => 'Details';

  @override
  String get changeOcto => 'Change Octo';

  @override
  String get rename => 'Rename';

  @override
  String get nameLabel => 'Name';

  @override
  String get languageLabel => 'Language';

  @override
  String get save => 'Save';

  @override
  String syncPending(String person) {
    return '$person\'s computer will update when it\'s back.';
  }

  @override
  String get rules => 'Rules';

  @override
  String get activity => 'Activity';

  @override
  String get helpers => 'Helpers';

  @override
  String get thisMonth => 'This month';

  @override
  String get usageTasks => 'Tasks';

  @override
  String get usageQuestions => 'Questions';

  @override
  String get usageCost => 'Cost';

  @override
  String get usageUnavailable => 'Couldn\'t load this month.';

  @override
  String get muteNotifications => 'Mute notifications';

  @override
  String get removeOcto => 'Remove this Octo';

  @override
  String get removeForEveryone => 'Remove for everyone';

  @override
  String get removeFromPhone => 'Remove from my phone';

  @override
  String youSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get helpersEmpty => 'Helpers show up once her computer is reachable.';

  @override
  String get rulesAskEveryChange => 'Ask before every change';

  @override
  String get rulesAskBeforeLooking => 'Ask before looking at the screen';

  @override
  String get rulesNever => 'Never…';

  @override
  String get rulesSites => 'Sites to stay off';

  @override
  String get addSite => 'Add a site';

  @override
  String get siteHint => 'example.com';

  @override
  String get invalidSite => 'Type a site like example.com';

  @override
  String get ruleApplying => 'Applying change';

  @override
  String ruleWaiting(String person) {
    return 'Waiting for $person to approve';
  }

  @override
  String ruleKeptOld(String person) {
    return '$person kept the old rule';
  }

  @override
  String rulesOffline(String person) {
    return '$person\'s computer is offline. Rules can change when it\'s back.';
  }

  @override
  String get ruleNoReply => 'No answer from her computer. Nothing changed.';

  @override
  String get ruleRefusedPlain => 'Her computer didn\'t take that change.';

  @override
  String rulesLooserNote(String person) {
    return 'Making a rule looser waits for $person to approve it.';
  }

  @override
  String removeSite(String site) {
    return 'Remove $site';
  }

  @override
  String get activityEmpty => 'Nothing here yet.';

  @override
  String get filterAll => 'All';

  @override
  String get today => 'Today';

  @override
  String get kindTask => 'Tasks';

  @override
  String get kindStep => 'Steps';

  @override
  String get kindConsent => 'OKs';

  @override
  String get kindLimit => 'Safety stops';

  @override
  String get kindTodo => 'To-dos';

  @override
  String get kindHelp => 'Help';

  @override
  String get kindScreen => 'Screen';

  @override
  String get kindMessage => 'Messages';

  @override
  String get kindPairing => 'Helpers';

  @override
  String get kindPolicy => 'Rules';

  @override
  String get kindOther => 'Other';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get accountFake =>
      'Simulated account. This copy plays the family computers itself.';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockDetail =>
      'Ask for Face ID, fingerprint or your passcode after a minute away.';

  @override
  String get appLockUnavailable => 'This phone has no screen lock set up.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifyHelp => 'Someone needs a hand';

  @override
  String get notifyTodo => 'Something is sent to you';

  @override
  String get notifyConsent => 'Octo is waiting for an OK';

  @override
  String get notifyTaskEnded => 'A task finishes';

  @override
  String get notifyPairing => 'A helper is added';

  @override
  String get notificationsLater =>
      'Notifications arrive once you\'re signed in with October.';

  @override
  String get about => 'About';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get aboutBody =>
      'Octo by October. Tasks, to-dos and screenshots travel end to end encrypted. Screenshots stay on this phone for 7 days.';

  @override
  String get developer => 'Developer';

  @override
  String get showSimulator => 'Show simulator controls';

  @override
  String get lockTitle => 'Octo is locked';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockReason => 'Unlock Octo';

  @override
  String get welcomeLine => 'Help your family\'s computers, from your phone';

  @override
  String get signInWithOctober => 'Sign in with October';

  @override
  String get emailLabel => 'Email';

  @override
  String get sendLink => 'Email me a link';

  @override
  String linkSent(String email) {
    return 'Check your email at $email. Tap the link on this phone, or type the code from the email.';
  }

  @override
  String get codeLabel => '6-digit code';

  @override
  String get signInButton => 'Sign in';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get continueApple => 'Continue with Apple';

  @override
  String get orDivider => 'or';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out of Octo?';

  @override
  String get signOutBody =>
      'Your Octos stay on October. This phone forgets their conversations until you sign in again.';

  @override
  String get signOutUnsent =>
      'Some things you typed haven\'t reached the computer yet. Signing out deletes them.';

  @override
  String get signOutRemovals =>
      'A computer you removed is still being disconnected. Signing out stops that.';

  @override
  String get pairNotAvailable =>
      'This version of Octo can\'t connect to a computer yet.';

  @override
  String get pushOpen => 'Open';

  @override
  String get notNow => 'Not now';

  @override
  String get gotIt => 'Got it';

  @override
  String get pairAgainSection => 'On your October account';

  @override
  String get pairAgain => 'Pair again on this phone';

  @override
  String get ntfyTitle => 'One more step for notifications';

  @override
  String get ntfyBody =>
      'On Android, Octo\'s notifications come through the free ntfy app. Install ntfy from Google Play or F-Droid, then open Octo again.';

  @override
  String get allowNotifications => 'Allow notifications';

  @override
  String get planNeeded => 'See plans';

  @override
  String get passwordLabel => 'Password';

  @override
  String get usePassword => 'Use a password instead';

  @override
  String get useEmailLink => 'Email me a link instead';
}
