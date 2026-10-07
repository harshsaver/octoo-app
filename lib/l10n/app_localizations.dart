import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Octo'**
  String get appTitle;

  /// No description provided for @notConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'This build isn\'t configured'**
  String get notConfiguredTitle;

  /// No description provided for @notConfiguredBody.
  ///
  /// In en, this message translates to:
  /// **'This copy of Octo can\'t connect to October yet. Install Octo from the App Store or Google Play.'**
  String get notConfiguredBody;

  /// No description provided for @taskQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting its turn'**
  String get taskQueued;

  /// No description provided for @taskWaitingOk.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {person}'**
  String taskWaitingOk(String person);

  /// No description provided for @taskRunning.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get taskRunning;

  /// No description provided for @taskDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskDone;

  /// No description provided for @taskGaveUp.
  ///
  /// In en, this message translates to:
  /// **'Back with you'**
  String get taskGaveUp;

  /// No description provided for @taskBlocked.
  ///
  /// In en, this message translates to:
  /// **'Stopped by a safety rule'**
  String get taskBlocked;

  /// No description provided for @taskRefused.
  ///
  /// In en, this message translates to:
  /// **'Not allowed by your rules'**
  String get taskRefused;

  /// No description provided for @taskDeclined.
  ///
  /// In en, this message translates to:
  /// **'{person} said no'**
  String taskDeclined(String person);

  /// No description provided for @taskNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'{person} didn\'t answer'**
  String taskNoAnswer(String person);

  /// No description provided for @taskStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get taskStopped;

  /// No description provided for @taskFailed.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t work'**
  String get taskFailed;

  /// No description provided for @taskUnknown.
  ///
  /// In en, this message translates to:
  /// **'Octo sent an update this app can\'t show yet. Update the app.'**
  String get taskUnknown;

  /// No description provided for @changeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open apps'**
  String get changeOpen;

  /// No description provided for @changeInstall.
  ///
  /// In en, this message translates to:
  /// **'Install apps'**
  String get changeInstall;

  /// No description provided for @changeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get changeSignIn;

  /// No description provided for @changeSend.
  ///
  /// In en, this message translates to:
  /// **'Send messages'**
  String get changeSend;

  /// No description provided for @changeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete things'**
  String get changeDelete;

  /// No description provided for @changeSettings.
  ///
  /// In en, this message translates to:
  /// **'Change settings'**
  String get changeSettings;

  /// No description provided for @changeCall.
  ///
  /// In en, this message translates to:
  /// **'Join calls'**
  String get changeCall;

  /// No description provided for @changeOther.
  ///
  /// In en, this message translates to:
  /// **'Other changes'**
  String get changeOther;

  /// No description provided for @changeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get changeUnknown;

  /// No description provided for @screenshotOnHerComputer.
  ///
  /// In en, this message translates to:
  /// **'Screenshot on her computer'**
  String get screenshotOnHerComputer;

  /// No description provided for @screenshotUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Screenshot no longer available'**
  String get screenshotUnavailable;

  /// No description provided for @octosTitle.
  ///
  /// In en, this message translates to:
  /// **'Octos'**
  String get octosTitle;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @addOcto.
  ///
  /// In en, this message translates to:
  /// **'Add an Octo'**
  String get addOcto;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @playMom.
  ///
  /// In en, this message translates to:
  /// **'Play Mom (simulator)'**
  String get playMom;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first Octo'**
  String get emptyTitle;

  /// No description provided for @emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Open October on the family computer, go to Settings, then Phone access, and choose Add a phone.'**
  String get emptyHint;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No Octos match “{query}”'**
  String noMatches(String query);

  /// No description provided for @previewWorking.
  ///
  /// In en, this message translates to:
  /// **'Working… step {step}'**
  String previewWorking(int step);

  /// No description provided for @previewWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {person} to say OK'**
  String previewWaiting(String person);

  /// No description provided for @previewOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline · last seen {ago}'**
  String previewOffline(String ago);

  /// No description provided for @previewNeedsHand.
  ///
  /// In en, this message translates to:
  /// **'{person} needs a hand'**
  String previewNeedsHand(String person);

  /// No description provided for @previewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Ask Octo something'**
  String get previewEmpty;

  /// No description provided for @previewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get previewPhoto;

  /// No description provided for @previewYou.
  ///
  /// In en, this message translates to:
  /// **'You: {text}'**
  String previewYou(String text);

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get markRead;

  /// No description provided for @markUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get markUnread;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @removeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {person}\'s Octo?'**
  String removeTitle(String person);

  /// No description provided for @removeBodyOwner.
  ///
  /// In en, this message translates to:
  /// **'{computer} will be removed for everyone who helps with it, not just you.'**
  String removeBodyOwner(String computer);

  /// No description provided for @removeBodyHelper.
  ///
  /// In en, this message translates to:
  /// **'You\'ll stop helping with {computer} from this phone.'**
  String removeBodyHelper(String computer);

  /// No description provided for @removeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove it. {message}'**
  String removeFailed(String message);

  /// No description provided for @removedBanner.
  ///
  /// In en, this message translates to:
  /// **'{person}\'s computer removed you'**
  String removedBanner(String person);

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @muted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get muted;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String agoMinutes(int n);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String agoHours(int n);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String agoDays(int n);

  /// No description provided for @agoJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get agoJustNow;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get statusWorking;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get statusConnecting;

  /// No description provided for @statusLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {ago}'**
  String statusLastSeen(String ago);

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusNotOcto.
  ///
  /// In en, this message translates to:
  /// **'Not running Octo'**
  String get statusNotOcto;

  /// No description provided for @previewNotOcto.
  ///
  /// In en, this message translates to:
  /// **'This computer isn\'t running Octo. Remove it and pair with Octo\'s code.'**
  String get previewNotOcto;

  /// No description provided for @askOctoPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask Octo…'**
  String get askOctoPlaceholder;

  /// No description provided for @tellPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Tell {person}…'**
  String tellPlaceholder(String person);

  /// No description provided for @toggleAskOcto.
  ///
  /// In en, this message translates to:
  /// **'Ask Octo'**
  String get toggleAskOcto;

  /// No description provided for @toggleTell.
  ///
  /// In en, this message translates to:
  /// **'Tell {person}'**
  String toggleTell(String person);

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @quickJobs.
  ///
  /// In en, this message translates to:
  /// **'Quick jobs'**
  String get quickJobs;

  /// No description provided for @composerOffline.
  ///
  /// In en, this message translates to:
  /// **'{person}\'s computer is offline. We\'ll send this when it\'s back.'**
  String composerOffline(String person);

  /// No description provided for @composerRemoved.
  ///
  /// In en, this message translates to:
  /// **'{person}\'s computer removed you.'**
  String composerRemoved(String person);

  /// No description provided for @mayHint.
  ///
  /// In en, this message translates to:
  /// **'Octo will ask {person} before it {actions}.'**
  String mayHint(String person, String actions);

  /// No description provided for @charactersLeft.
  ///
  /// In en, this message translates to:
  /// **'{n} left'**
  String charactersLeft(int n);

  /// No description provided for @mayOpen.
  ///
  /// In en, this message translates to:
  /// **'opens apps'**
  String get mayOpen;

  /// No description provided for @mayInstall.
  ///
  /// In en, this message translates to:
  /// **'installs apps'**
  String get mayInstall;

  /// No description provided for @maySignIn.
  ///
  /// In en, this message translates to:
  /// **'signs in'**
  String get maySignIn;

  /// No description provided for @maySend.
  ///
  /// In en, this message translates to:
  /// **'sends messages'**
  String get maySend;

  /// No description provided for @mayDelete.
  ///
  /// In en, this message translates to:
  /// **'deletes things'**
  String get mayDelete;

  /// No description provided for @maySettings.
  ///
  /// In en, this message translates to:
  /// **'changes settings'**
  String get maySettings;

  /// No description provided for @mayCall.
  ///
  /// In en, this message translates to:
  /// **'joins calls'**
  String get mayCall;

  /// No description provided for @mayOther.
  ///
  /// In en, this message translates to:
  /// **'changes anything else'**
  String get mayOther;

  /// No description provided for @listAnd.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b}'**
  String listAnd(String a, String b);

  /// No description provided for @jobWifi.
  ///
  /// In en, this message translates to:
  /// **'Check Wi-Fi'**
  String get jobWifi;

  /// No description provided for @jobCall.
  ///
  /// In en, this message translates to:
  /// **'Join a call'**
  String get jobCall;

  /// No description provided for @jobFind.
  ///
  /// In en, this message translates to:
  /// **'Find an email or file'**
  String get jobFind;

  /// No description provided for @jobBigger.
  ///
  /// In en, this message translates to:
  /// **'Bigger text or sound'**
  String get jobBigger;

  /// No description provided for @jobInstall.
  ///
  /// In en, this message translates to:
  /// **'Install an app'**
  String get jobInstall;

  /// No description provided for @jobScreenDescribe.
  ///
  /// In en, this message translates to:
  /// **'What\'s on screen?'**
  String get jobScreenDescribe;

  /// No description provided for @jobSeeScreen.
  ///
  /// In en, this message translates to:
  /// **'See her screen'**
  String get jobSeeScreen;

  /// No description provided for @jobWifiText.
  ///
  /// In en, this message translates to:
  /// **'Check the Wi-Fi and internet'**
  String get jobWifiText;

  /// No description provided for @jobScreenDescribeText.
  ///
  /// In en, this message translates to:
  /// **'What\'s on the screen right now?'**
  String get jobScreenDescribeText;

  /// No description provided for @jobCallPrefill.
  ///
  /// In en, this message translates to:
  /// **'Join a call: '**
  String get jobCallPrefill;

  /// No description provided for @jobFindPrefill.
  ///
  /// In en, this message translates to:
  /// **'Find: '**
  String get jobFindPrefill;

  /// No description provided for @jobBiggerPrefill.
  ///
  /// In en, this message translates to:
  /// **'Make bigger: '**
  String get jobBiggerPrefill;

  /// No description provided for @jobInstallPrefill.
  ///
  /// In en, this message translates to:
  /// **'Install: '**
  String get jobInstallPrefill;

  /// No description provided for @lineWaitingTurn.
  ///
  /// In en, this message translates to:
  /// **'Waiting its turn'**
  String get lineWaitingTurn;

  /// No description provided for @lineWaitingForHer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {person} to say OK'**
  String lineWaitingForHer(String person);

  /// No description provided for @lineSheSaidOk.
  ///
  /// In en, this message translates to:
  /// **'{person} said OK'**
  String lineSheSaidOk(String person);

  /// No description provided for @deliveryPending.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet'**
  String get deliveryPending;

  /// No description provided for @deliverySending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get deliverySending;

  /// No description provided for @deliveryUncertain.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm it reached {person}\'s computer. Check the activity before trying again.'**
  String deliveryUncertain(String person);

  /// No description provided for @deliveryRejected.
  ///
  /// In en, this message translates to:
  /// **'Not sent: {message}'**
  String deliveryRejected(String message);

  /// No description provided for @deliveryRejectedPlain.
  ///
  /// In en, this message translates to:
  /// **'Her computer didn\'t take this.'**
  String get deliveryRejectedPlain;

  /// No description provided for @retryNote.
  ///
  /// In en, this message translates to:
  /// **'Sent again. It may run twice.'**
  String get retryNote;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @doIt.
  ///
  /// In en, this message translates to:
  /// **'Octo, do it'**
  String get doIt;

  /// No description provided for @seeHerScreen.
  ///
  /// In en, this message translates to:
  /// **'See her screen'**
  String get seeHerScreen;

  /// No description provided for @helpAsk.
  ///
  /// In en, this message translates to:
  /// **'Can you take a look?'**
  String get helpAsk;

  /// No description provided for @askedScreen.
  ///
  /// In en, this message translates to:
  /// **'Asked {person} to show her screen'**
  String askedScreen(String person);

  /// No description provided for @screenRefused.
  ///
  /// In en, this message translates to:
  /// **'{person} said no to showing her screen'**
  String screenRefused(String person);

  /// No description provided for @resultDone.
  ///
  /// In en, this message translates to:
  /// **'Done.'**
  String get resultDone;

  /// No description provided for @resultGaveUp.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t finish this. It\'s back with you.'**
  String get resultGaveUp;

  /// No description provided for @resultBlocked.
  ///
  /// In en, this message translates to:
  /// **'I stopped because of a safety rule.'**
  String get resultBlocked;

  /// No description provided for @resultRefused.
  ///
  /// In en, this message translates to:
  /// **'Your rules don\'t allow this.'**
  String get resultRefused;

  /// No description provided for @resultDeclined.
  ///
  /// In en, this message translates to:
  /// **'{person} said no.'**
  String resultDeclined(String person);

  /// No description provided for @resultNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'{person} didn\'t answer.'**
  String resultNoAnswer(String person);

  /// No description provided for @resultStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped.'**
  String get resultStopped;

  /// No description provided for @resultFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work.'**
  String get resultFailed;

  /// No description provided for @liveStep.
  ///
  /// In en, this message translates to:
  /// **'Step {n}'**
  String liveStep(int n);

  /// No description provided for @liveStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get liveStarting;

  /// No description provided for @octoToldHer.
  ///
  /// In en, this message translates to:
  /// **'Octo told her: {answer}'**
  String octoToldHer(String answer);

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to “{text}”'**
  String replyingTo(String text);

  /// No description provided for @fromName.
  ///
  /// In en, this message translates to:
  /// **'{name} → Octo'**
  String fromName(String name);

  /// No description provided for @stopOffline.
  ///
  /// In en, this message translates to:
  /// **'{person}\'s computer is offline.'**
  String stopOffline(String person);

  /// No description provided for @stopRefused.
  ///
  /// In en, this message translates to:
  /// **'That task already finished.'**
  String get stopRefused;

  /// No description provided for @stopNoReply.
  ///
  /// In en, this message translates to:
  /// **'No answer from her computer. It may still stop.'**
  String get stopNoReply;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Hi {helper}! I\'m {person}\'s Octo. Ask me to do something on her computer, like check the Wi-Fi or make the text bigger. I\'ll always ask her first before changing anything.'**
  String welcome(String helper, String person);

  /// No description provided for @bubbleLabel.
  ///
  /// In en, this message translates to:
  /// **'{sender}, {time}: {text}'**
  String bubbleLabel(String sender, String time, String text);

  /// No description provided for @octoName.
  ///
  /// In en, this message translates to:
  /// **'Octo'**
  String get octoName;

  /// No description provided for @youName.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youName;

  /// No description provided for @imageFromOcto.
  ///
  /// In en, this message translates to:
  /// **'Screenshot from Octo'**
  String get imageFromOcto;

  /// No description provided for @imageFromHer.
  ///
  /// In en, this message translates to:
  /// **'Screenshot from {person}'**
  String imageFromHer(String person);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineTitle;

  /// No description provided for @timelineAsked.
  ///
  /// In en, this message translates to:
  /// **'{name} asked'**
  String timelineAsked(String name);

  /// No description provided for @timelineStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get timelineStarted;

  /// No description provided for @timelineEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get timelineEnded;

  /// No description provided for @activityMayBeMissing.
  ///
  /// In en, this message translates to:
  /// **'Older activity may be missing'**
  String get activityMayBeMissing;

  /// No description provided for @scanCaption.
  ///
  /// In en, this message translates to:
  /// **'On the family computer, open October, go to Settings, then Phone access, and choose Add a phone. Point your camera at the code.'**
  String get scanCaption;

  /// No description provided for @typeCodeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type the code instead'**
  String get typeCodeInstead;

  /// No description provided for @smallPrint.
  ///
  /// In en, this message translates to:
  /// **'Only add a family member\'s computer while you\'re with them, or on a call with them.'**
  String get smallPrint;

  /// No description provided for @useSimulator.
  ///
  /// In en, this message translates to:
  /// **'Use a simulated computer'**
  String get useSimulator;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera isn\'t available. You can type the code instead.'**
  String get cameraUnavailable;

  /// No description provided for @typeCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Type the code'**
  String get typeCodeTitle;

  /// No description provided for @typeCodeHint.
  ///
  /// In en, this message translates to:
  /// **'8 letters or numbers'**
  String get typeCodeHint;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @codeNotRecognised.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t an Octo code. Check it and try again.'**
  String get codeNotRecognised;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @compareKeyBody.
  ///
  /// In en, this message translates to:
  /// **'{computer} shows the same key. Check they match, and ask them to tap OK.'**
  String compareKeyBody(String computer);

  /// No description provided for @theyMatch.
  ///
  /// In en, this message translates to:
  /// **'They match'**
  String get theyMatch;

  /// No description provided for @theyDontMatch.
  ///
  /// In en, this message translates to:
  /// **'They don\'t match'**
  String get theyDontMatch;

  /// No description provided for @mismatchExplain.
  ///
  /// In en, this message translates to:
  /// **'The keys didn\'t match, so we stopped. Someone else may be trying to add this computer.'**
  String get mismatchExplain;

  /// No description provided for @waitingForOk.
  ///
  /// In en, this message translates to:
  /// **'Waiting for someone to tap OK on {computer}…'**
  String waitingForOk(String computer);

  /// No description provided for @pairNotOcto.
  ///
  /// In en, this message translates to:
  /// **'{computer} isn\'t running Octo. That code is for October\'s phone access; scan the code Octo shows instead.'**
  String pairNotOcto(String computer);

  /// No description provided for @pairOffline.
  ///
  /// In en, this message translates to:
  /// **'{computer} went offline. Try again when it\'s back.'**
  String pairOffline(String computer);

  /// No description provided for @pairTimedOut.
  ///
  /// In en, this message translates to:
  /// **'No one answered on {computer}.'**
  String pairTimedOut(String computer);

  /// No description provided for @pairNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get pairNotAdded;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @nameTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is it for?'**
  String get nameTitle;

  /// No description provided for @nameOther.
  ///
  /// In en, this message translates to:
  /// **'Their name'**
  String get nameOther;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Their language'**
  String get languageTitle;

  /// No description provided for @computerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'The computer\'s name'**
  String get computerNameLabel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @lookTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick their Octo'**
  String get lookTitle;

  /// No description provided for @setupFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t finish setting up. {message}'**
  String setupFailed(String message);

  /// No description provided for @notificationsWhy.
  ///
  /// In en, this message translates to:
  /// **'So you know when {person} needs you.'**
  String notificationsWhy(String person);

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTitle;

  /// No description provided for @changeOcto.
  ///
  /// In en, this message translates to:
  /// **'Change Octo'**
  String get changeOcto;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{person}\'s computer will update when it\'s back.'**
  String syncPending(String person);

  /// No description provided for @rules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rules;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @helpers.
  ///
  /// In en, this message translates to:
  /// **'Helpers'**
  String get helpers;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @usageTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get usageTasks;

  /// No description provided for @usageQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get usageQuestions;

  /// No description provided for @usageCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get usageCost;

  /// No description provided for @usageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this month.'**
  String get usageUnavailable;

  /// No description provided for @muteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get muteNotifications;

  /// No description provided for @removeOcto.
  ///
  /// In en, this message translates to:
  /// **'Remove this Octo'**
  String get removeOcto;

  /// No description provided for @removeForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Remove for everyone'**
  String get removeForEveryone;

  /// No description provided for @removeFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Remove from my phone'**
  String get removeFromPhone;

  /// No description provided for @youSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youSuffix(String name);

  /// No description provided for @helpersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Helpers show up once her computer is reachable.'**
  String get helpersEmpty;

  /// No description provided for @rulesAskEveryChange.
  ///
  /// In en, this message translates to:
  /// **'Ask before every change'**
  String get rulesAskEveryChange;

  /// No description provided for @rulesAskBeforeLooking.
  ///
  /// In en, this message translates to:
  /// **'Ask before looking at the screen'**
  String get rulesAskBeforeLooking;

  /// No description provided for @rulesNever.
  ///
  /// In en, this message translates to:
  /// **'Never…'**
  String get rulesNever;

  /// No description provided for @rulesSites.
  ///
  /// In en, this message translates to:
  /// **'Sites to stay off'**
  String get rulesSites;

  /// No description provided for @addSite.
  ///
  /// In en, this message translates to:
  /// **'Add a site'**
  String get addSite;

  /// No description provided for @siteHint.
  ///
  /// In en, this message translates to:
  /// **'example.com'**
  String get siteHint;

  /// No description provided for @invalidSite.
  ///
  /// In en, this message translates to:
  /// **'Type a site like example.com'**
  String get invalidSite;

  /// No description provided for @ruleApplying.
  ///
  /// In en, this message translates to:
  /// **'Applying change'**
  String get ruleApplying;

  /// No description provided for @ruleWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {person} to approve'**
  String ruleWaiting(String person);

  /// No description provided for @ruleKeptOld.
  ///
  /// In en, this message translates to:
  /// **'{person} kept the old rule'**
  String ruleKeptOld(String person);

  /// No description provided for @rulesOffline.
  ///
  /// In en, this message translates to:
  /// **'{person}\'s computer is offline. Rules can change when it\'s back.'**
  String rulesOffline(String person);

  /// No description provided for @ruleNoReply.
  ///
  /// In en, this message translates to:
  /// **'No answer from her computer. Nothing changed.'**
  String get ruleNoReply;

  /// No description provided for @ruleRefusedPlain.
  ///
  /// In en, this message translates to:
  /// **'Her computer didn\'t take that change.'**
  String get ruleRefusedPlain;

  /// No description provided for @rulesLooserNote.
  ///
  /// In en, this message translates to:
  /// **'Making a rule looser waits for {person} to approve it.'**
  String rulesLooserNote(String person);

  /// No description provided for @removeSite.
  ///
  /// In en, this message translates to:
  /// **'Remove {site}'**
  String removeSite(String site);

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get activityEmpty;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @kindTask.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get kindTask;

  /// No description provided for @kindStep.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get kindStep;

  /// No description provided for @kindConsent.
  ///
  /// In en, this message translates to:
  /// **'OKs'**
  String get kindConsent;

  /// No description provided for @kindLimit.
  ///
  /// In en, this message translates to:
  /// **'Safety stops'**
  String get kindLimit;

  /// No description provided for @kindTodo.
  ///
  /// In en, this message translates to:
  /// **'To-dos'**
  String get kindTodo;

  /// No description provided for @kindHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get kindHelp;

  /// No description provided for @kindScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get kindScreen;

  /// No description provided for @kindMessage.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get kindMessage;

  /// No description provided for @kindPairing.
  ///
  /// In en, this message translates to:
  /// **'Helpers'**
  String get kindPairing;

  /// No description provided for @kindPolicy.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get kindPolicy;

  /// No description provided for @kindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get kindOther;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountFake.
  ///
  /// In en, this message translates to:
  /// **'Simulated account. This copy plays the family computers itself.'**
  String get accountFake;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// No description provided for @appLockDetail.
  ///
  /// In en, this message translates to:
  /// **'Ask for Face ID, fingerprint or your passcode after a minute away.'**
  String get appLockDetail;

  /// No description provided for @appLockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This phone has no screen lock set up.'**
  String get appLockUnavailable;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notifyHelp.
  ///
  /// In en, this message translates to:
  /// **'Someone needs a hand'**
  String get notifyHelp;

  /// No description provided for @notifyTodo.
  ///
  /// In en, this message translates to:
  /// **'Something is sent to you'**
  String get notifyTodo;

  /// No description provided for @notifyConsent.
  ///
  /// In en, this message translates to:
  /// **'Octo is waiting for an OK'**
  String get notifyConsent;

  /// No description provided for @notifyTaskEnded.
  ///
  /// In en, this message translates to:
  /// **'A task finishes'**
  String get notifyTaskEnded;

  /// No description provided for @notifyPairing.
  ///
  /// In en, this message translates to:
  /// **'A helper is added'**
  String get notifyPairing;

  /// No description provided for @notificationsLater.
  ///
  /// In en, this message translates to:
  /// **'Notifications arrive once you\'re signed in with October.'**
  String get notificationsLater;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Octo by October. Tasks, to-dos and screenshots travel end to end encrypted. Screenshots stay on this phone for 7 days.'**
  String get aboutBody;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @showSimulator.
  ///
  /// In en, this message translates to:
  /// **'Show simulator controls'**
  String get showSimulator;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'Octo is locked'**
  String get lockTitle;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Octo'**
  String get unlockReason;

  /// No description provided for @welcomeLine.
  ///
  /// In en, this message translates to:
  /// **'Help your family\'s computers, from your phone'**
  String get welcomeLine;

  /// No description provided for @signInWithOctober.
  ///
  /// In en, this message translates to:
  /// **'Sign in with October'**
  String get signInWithOctober;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Email me a link'**
  String get sendLink;

  /// No description provided for @linkSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email at {email}. Tap the link on this phone, or type the code from the email.'**
  String linkSent(String email);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get codeLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @continueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueApple;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Octo?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your Octos stay on October. This phone forgets their conversations until you sign in again.'**
  String get signOutBody;

  /// No description provided for @signOutUnsent.
  ///
  /// In en, this message translates to:
  /// **'Some things you typed haven\'t reached the computer yet. Signing out deletes them.'**
  String get signOutUnsent;

  /// No description provided for @signOutRemovals.
  ///
  /// In en, this message translates to:
  /// **'A computer you removed is still being disconnected. Signing out stops that.'**
  String get signOutRemovals;

  /// No description provided for @pairNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This version of Octo can\'t connect to a computer yet.'**
  String get pairNotAvailable;

  /// No description provided for @pushOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get pushOpen;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @pairAgainSection.
  ///
  /// In en, this message translates to:
  /// **'On your October account'**
  String get pairAgainSection;

  /// No description provided for @pairAgain.
  ///
  /// In en, this message translates to:
  /// **'Pair again on this phone'**
  String get pairAgain;

  /// No description provided for @ntfyTitle.
  ///
  /// In en, this message translates to:
  /// **'One more step for notifications'**
  String get ntfyTitle;

  /// No description provided for @ntfyBody.
  ///
  /// In en, this message translates to:
  /// **'On Android, Octo\'s notifications come through the free ntfy app. Install ntfy from Google Play or F-Droid, then open Octo again.'**
  String get ntfyBody;

  /// No description provided for @allowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get allowNotifications;

  /// No description provided for @planNeeded.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get planNeeded;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @usePassword.
  ///
  /// In en, this message translates to:
  /// **'Use a password instead'**
  String get usePassword;

  /// No description provided for @useEmailLink.
  ///
  /// In en, this message translates to:
  /// **'Email me a link instead'**
  String get useEmailLink;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
