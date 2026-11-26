import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @tabRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get tabRecording;

  /// No description provided for @tabSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get tabSafety;

  /// No description provided for @tabCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get tabCar;

  /// No description provided for @tabStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get tabStorage;

  /// No description provided for @tabSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get tabSystem;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @dataSaver.
  ///
  /// In en, this message translates to:
  /// **'Data saver'**
  String get dataSaver;

  /// No description provided for @dataSaverDetail.
  ///
  /// In en, this message translates to:
  /// **'Same resolution, smaller files'**
  String get dataSaverDetail;

  /// No description provided for @dataSaverInfo.
  ///
  /// In en, this message translates to:
  /// **'Records at a lower bitrate, so a file is about a third of the default size. The picture keeps the resolution you picked.'**
  String get dataSaverInfo;

  /// No description provided for @segmentLength.
  ///
  /// In en, this message translates to:
  /// **'Segment length'**
  String get segmentLength;

  /// No description provided for @burnTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Burn in the timestamp'**
  String get burnTimestamp;

  /// No description provided for @burnTimestampDetail.
  ///
  /// In en, this message translates to:
  /// **'Date and time in the corner of every clip'**
  String get burnTimestampDetail;

  /// No description provided for @timeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timeZone;

  /// No description provided for @timeZoneSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get timeZoneSystem;

  /// No description provided for @timeZoneSearch.
  ///
  /// In en, this message translates to:
  /// **'Search a time zone'**
  String get timeZoneSearch;

  /// No description provided for @recordAudio.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get recordAudio;

  /// No description provided for @recordAudioDetail.
  ///
  /// In en, this message translates to:
  /// **'Microphone sound together with the video'**
  String get recordAudioDetail;

  /// No description provided for @microphoneNeeded.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is needed'**
  String get microphoneNeeded;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesUnit;

  /// No description provided for @customTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom value'**
  String get customTitle;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @rear.
  ///
  /// In en, this message translates to:
  /// **'Rear'**
  String get rear;

  /// No description provided for @front.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get front;

  /// No description provided for @crashSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Crash sensitivity'**
  String get crashSensitivity;

  /// No description provided for @crashLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get crashLow;

  /// No description provided for @crashNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get crashNormal;

  /// No description provided for @crashHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get crashHigh;

  /// No description provided for @carStart.
  ///
  /// In en, this message translates to:
  /// **'Start in the car'**
  String get carStart;

  /// No description provided for @carStartDetail.
  ///
  /// In en, this message translates to:
  /// **'Records on its own when a signal below shows up, sometimes with a notification to tap'**
  String get carStartDetail;

  /// No description provided for @carBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth car link'**
  String get carBluetooth;

  /// No description provided for @carBluetoothDetail.
  ///
  /// In en, this message translates to:
  /// **'A car audio device connects'**
  String get carBluetoothDetail;

  /// No description provided for @carBluetoothInfo.
  ///
  /// In en, this message translates to:
  /// **'Starts when a paired car audio device connects and stops when it disconnects. Uses no sensors, so it costs no battery. Needs the Nearby devices permission. A Bluetooth headset can trigger it too.'**
  String get carBluetoothInfo;

  /// No description provided for @carMotion.
  ///
  /// In en, this message translates to:
  /// **'Charging and motion'**
  String get carMotion;

  /// No description provided for @carMotionDetail.
  ///
  /// In en, this message translates to:
  /// **'The phone charges and moves'**
  String get carMotionDetail;

  /// No description provided for @carMotionInfo.
  ///
  /// In en, this message translates to:
  /// **'Starts when the phone is charging and the motion sensor feels movement, and stops ten minutes after the last movement. Needs no permissions. Bumping a phone on a desk charger can trigger it.'**
  String get carMotionInfo;

  /// No description provided for @carVehicle.
  ///
  /// In en, this message translates to:
  /// **'Google vehicle detection'**
  String get carVehicle;

  /// No description provided for @carVehicleDetail.
  ///
  /// In en, this message translates to:
  /// **'The phone reports that it is in a vehicle'**
  String get carVehicleDetail;

  /// No description provided for @carVehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Uses Google Play services activity recognition, which batches its readings and costs very little battery. It notices a drive after about a minute. Needs the Physical activity permission.'**
  String get carVehicleInfo;

  /// No description provided for @applyNextRecording.
  ///
  /// In en, this message translates to:
  /// **'Applies to the next recording'**
  String get applyNextRecording;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @appStorage.
  ///
  /// In en, this message translates to:
  /// **'App storage'**
  String get appStorage;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @useAppStorage.
  ///
  /// In en, this message translates to:
  /// **'Use app storage'**
  String get useAppStorage;

  /// No description provided for @clipsGrouped.
  ///
  /// In en, this message translates to:
  /// **'Clips are grouped by year, month and day'**
  String get clipsGrouped;

  /// No description provided for @storageBudget.
  ///
  /// In en, this message translates to:
  /// **'Storage budget'**
  String get storageBudget;

  /// No description provided for @destroyAfter.
  ///
  /// In en, this message translates to:
  /// **'Destroy after'**
  String get destroyAfter;

  /// No description provided for @destroyAfterDetail.
  ///
  /// In en, this message translates to:
  /// **'Old clips are deleted on their own'**
  String get destroyAfterDetail;

  /// No description provided for @destroyOff.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get destroyOff;

  /// No description provided for @destroyHours.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get destroyHours;

  /// No description provided for @destroyDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get destroyDay;

  /// No description provided for @destroyWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get destroyWeek;

  /// No description provided for @destroyKeepsProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected clips stay until you clear their protection in the library'**
  String get destroyKeepsProtected;

  /// No description provided for @destroyUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get destroyUnit;

  /// No description provided for @unitMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get unitMinutes;

  /// No description provided for @unitHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get unitHours;

  /// No description provided for @unitDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get unitDays;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @batteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization'**
  String get batteryOptimization;

  /// No description provided for @batteryExempt.
  ///
  /// In en, this message translates to:
  /// **'Exempt'**
  String get batteryExempt;

  /// No description provided for @batteryNotExempt.
  ///
  /// In en, this message translates to:
  /// **'Not exempt'**
  String get batteryNotExempt;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get checking;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @clipsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clips'**
  String get clipsTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get startRecording;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @recordingLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingLabel;

  /// No description provided for @startingCamera.
  ///
  /// In en, this message translates to:
  /// **'Starting the camera'**
  String get startingCamera;

  /// No description provided for @warningLowStorage.
  ///
  /// In en, this message translates to:
  /// **'Recording stopped. Less than 500 MB free'**
  String get warningLowStorage;

  /// No description provided for @warningStorageError.
  ///
  /// In en, this message translates to:
  /// **'Recording stopped. Storage is unavailable'**
  String get warningStorageError;

  /// No description provided for @warningCameraError.
  ///
  /// In en, this message translates to:
  /// **'Recording stopped. Camera error'**
  String get warningCameraError;

  /// No description provided for @warningRecorderError.
  ///
  /// In en, this message translates to:
  /// **'Recording stopped. Recorder error'**
  String get warningRecorderError;

  /// No description provided for @warningGeneric.
  ///
  /// In en, this message translates to:
  /// **'Recording stopped'**
  String get warningGeneric;

  /// No description provided for @batteryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep recording with the screen off'**
  String get batteryDialogTitle;

  /// No description provided for @batteryDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Android may stop the recorder while the screen is off. Allow reason to run without battery optimization?'**
  String get batteryDialogBody;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. The stop action will not appear'**
  String get notificationsOff;

  /// No description provided for @cameraNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed'**
  String get cameraNeededTitle;

  /// No description provided for @cameraNeededBody.
  ///
  /// In en, this message translates to:
  /// **'reason records through the camera, so it cannot run without permission'**
  String get cameraNeededBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @noCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'No usable camera found'**
  String get noCameraTitle;

  /// No description provided for @noCameraBody.
  ///
  /// In en, this message translates to:
  /// **'This phone does not report a rear or front camera that can record video'**
  String get noCameraBody;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @couldNotStartCamera.
  ///
  /// In en, this message translates to:
  /// **'Could not start the camera'**
  String get couldNotStartCamera;

  /// No description provided for @clipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clips'**
  String get clipsTitle;

  /// No description provided for @noClipsTitle.
  ///
  /// In en, this message translates to:
  /// **'No clips yet'**
  String get noClipsTitle;

  /// No description provided for @noClipsBody.
  ///
  /// In en, this message translates to:
  /// **'Recorded clips appear here'**
  String get noClipsBody;

  /// No description provided for @couldNotReadClips.
  ///
  /// In en, this message translates to:
  /// **'Could not read the clips'**
  String get couldNotReadClips;

  /// No description provided for @deleteClipTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete clip?'**
  String get deleteClipTitle;

  /// No description provided for @deleteClipProtectedBody.
  ///
  /// In en, this message translates to:
  /// **'This clip is protected. Deleting removes the clip and its protection marker.'**
  String get deleteClipProtectedBody;

  /// No description provided for @deleteClipBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the clip from the phone.'**
  String get deleteClipBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @clipDeleted.
  ///
  /// In en, this message translates to:
  /// **'Clip deleted'**
  String get clipDeleted;

  /// No description provided for @clearProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear protection?'**
  String get clearProtectionTitle;

  /// No description provided for @clearProtectionBody.
  ///
  /// In en, this message translates to:
  /// **'The loop can delete this clip when space is needed.'**
  String get clearProtectionBody;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @protectionCleared.
  ///
  /// In en, this message translates to:
  /// **'Protection cleared'**
  String get protectionCleared;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @clearProtection.
  ///
  /// In en, this message translates to:
  /// **'Clear protection'**
  String get clearProtection;

  /// No description provided for @clipActions.
  ///
  /// In en, this message translates to:
  /// **'Clip actions'**
  String get clipActions;

  /// No description provided for @protected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get protected;

  /// No description provided for @couldNotPlayClip.
  ///
  /// In en, this message translates to:
  /// **'Could not play this clip'**
  String get couldNotPlayClip;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @errorCameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get errorCameraPermission;

  /// No description provided for @errorLowStorage.
  ///
  /// In en, this message translates to:
  /// **'Less than 500 MB free. Free up space and try again'**
  String get errorLowStorage;

  /// No description provided for @errorStorageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Clip storage is not available'**
  String get errorStorageUnavailable;

  /// No description provided for @errorServiceFailed.
  ///
  /// In en, this message translates to:
  /// **'The recording service could not start'**
  String get errorServiceFailed;

  /// No description provided for @errorRecordingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Stop the current recording first'**
  String get errorRecordingInProgress;

  /// No description provided for @errorInvalidArgs.
  ///
  /// In en, this message translates to:
  /// **'These recording settings are not valid'**
  String get errorInvalidArgs;

  /// No description provided for @errorClipNotFound.
  ///
  /// In en, this message translates to:
  /// **'That clip is gone'**
  String get errorClipNotFound;

  /// No description provided for @errorShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the share sheet'**
  String get errorShareFailed;

  /// No description provided for @errorFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not use that folder'**
  String get errorFolder;

  /// No description provided for @errorPickerBusy.
  ///
  /// In en, this message translates to:
  /// **'The folder picker is already open'**
  String get errorPickerBusy;

  /// No description provided for @errorRecordingFailed.
  ///
  /// In en, this message translates to:
  /// **'Recording failed'**
  String get errorRecordingFailed;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @numberRange.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max}'**
  String numberRange(int min, int max);

  /// No description provided for @crashSensitivityInfo.
  ///
  /// In en, this message translates to:
  /// **'A hard jolt marks the clip being recorded as protected, so the loop keeps it'**
  String get crashSensitivityInfo;
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
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
