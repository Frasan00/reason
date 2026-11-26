// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get tabRecording => 'Recording';

  @override
  String get tabSafety => 'Safety';

  @override
  String get tabCar => 'Car';

  @override
  String get tabStorage => 'Storage';

  @override
  String get tabSystem => 'System';

  @override
  String get resolution => 'Resolution';

  @override
  String get dataSaver => 'Data saver';

  @override
  String get dataSaverDetail => 'Same resolution, smaller files';

  @override
  String get dataSaverInfo =>
      'Records at a lower bitrate, so a file is about a third of the default size. The picture keeps the resolution you picked.';

  @override
  String get segmentLength => 'Segment length';

  @override
  String get custom => 'Custom';

  @override
  String get minutesUnit => 'min';

  @override
  String get customTitle => 'Custom value';

  @override
  String get camera => 'Camera';

  @override
  String get rear => 'Rear';

  @override
  String get front => 'Front';

  @override
  String get crashSensitivity => 'Crash sensitivity';

  @override
  String get crashLow => 'Low';

  @override
  String get crashNormal => 'Normal';

  @override
  String get crashHigh => 'High';

  @override
  String get carStart => 'Start in the car';

  @override
  String get carStartDetail =>
      'Records on its own when a signal below shows up, sometimes with a notification to tap';

  @override
  String get carBluetooth => 'Bluetooth car link';

  @override
  String get carBluetoothDetail => 'A car audio device connects';

  @override
  String get carBluetoothInfo =>
      'Starts when a paired car audio device connects and stops when it disconnects. Uses no sensors, so it costs no battery. Needs the Nearby devices permission. A Bluetooth headset can trigger it too.';

  @override
  String get carMotion => 'Charging and motion';

  @override
  String get carMotionDetail => 'The phone charges and moves';

  @override
  String get carMotionInfo =>
      'Starts when the phone is charging and the motion sensor feels movement, and stops ten minutes after the last movement. Needs no permissions. Bumping a phone on a desk charger can trigger it.';

  @override
  String get carVehicle => 'Google vehicle detection';

  @override
  String get carVehicleDetail => 'The phone reports that it is in a vehicle';

  @override
  String get carVehicleInfo =>
      'Uses Google Play services activity recognition, which batches its readings and costs very little battery. It notices a drive after about a minute. Needs the Physical activity permission.';

  @override
  String get applyNextRecording => 'Applies to the next recording';

  @override
  String get destination => 'Destination';

  @override
  String get appStorage => 'App storage';

  @override
  String get choose => 'Choose';

  @override
  String get change => 'Change';

  @override
  String get useAppStorage => 'Use app storage';

  @override
  String get clipsGrouped => 'Clips are grouped by year, month and day';

  @override
  String get storageBudget => 'Storage budget';

  @override
  String get destroyAfter => 'Destroy after';

  @override
  String get destroyAfterDetail => 'Old clips are deleted on their own';

  @override
  String get destroyOff => 'Never';

  @override
  String get destroyHours => '1 hour';

  @override
  String get destroyDay => '1 day';

  @override
  String get destroyWeek => '7 days';

  @override
  String get destroyKeepsProtected =>
      'Protected clips stay until you clear their protection in the library';

  @override
  String get destroyUnit => 'Unit';

  @override
  String get unitMinutes => 'Minutes';

  @override
  String get unitHours => 'Hours';

  @override
  String get unitDays => 'Days';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get batteryOptimization => 'Battery optimization';

  @override
  String get batteryExempt => 'Exempt';

  @override
  String get batteryNotExempt => 'Not exempt';

  @override
  String get checking => 'Checking';

  @override
  String get allow => 'Allow';

  @override
  String get clipsTooltip => 'Clips';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get startRecording => 'Start recording';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get recordingLabel => 'Recording';

  @override
  String get startingCamera => 'Starting the camera';

  @override
  String get warningLowStorage => 'Recording stopped. Less than 500 MB free';

  @override
  String get warningStorageError => 'Recording stopped. Storage is unavailable';

  @override
  String get warningCameraError => 'Recording stopped. Camera error';

  @override
  String get warningRecorderError => 'Recording stopped. Recorder error';

  @override
  String get warningGeneric => 'Recording stopped';

  @override
  String get batteryDialogTitle => 'Keep recording with the screen off';

  @override
  String get batteryDialogBody =>
      'Android may stop the recorder while the screen is off. Allow reason to run without battery optimization?';

  @override
  String get notNow => 'Not now';

  @override
  String get notificationsOff =>
      'Notifications are off. The stop action will not appear';

  @override
  String get cameraNeededTitle => 'Camera access is needed';

  @override
  String get cameraNeededBody =>
      'reason records through the camera, so it cannot run without permission';

  @override
  String get tryAgain => 'Try again';

  @override
  String get openSettings => 'Open settings';

  @override
  String get noCameraTitle => 'No usable camera found';

  @override
  String get noCameraBody =>
      'This phone does not report a rear or front camera that can record video';

  @override
  String get checkAgain => 'Check again';

  @override
  String get couldNotStartCamera => 'Could not start the camera';

  @override
  String get clipsTitle => 'Clips';

  @override
  String get noClipsTitle => 'No clips yet';

  @override
  String get noClipsBody => 'Recorded clips appear here';

  @override
  String get couldNotReadClips => 'Could not read the clips';

  @override
  String get deleteClipTitle => 'Delete clip?';

  @override
  String get deleteClipProtectedBody =>
      'This clip is protected. Deleting removes the clip and its protection marker.';

  @override
  String get deleteClipBody => 'This removes the clip from the phone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get clipDeleted => 'Clip deleted';

  @override
  String get clearProtectionTitle => 'Clear protection?';

  @override
  String get clearProtectionBody =>
      'The loop can delete this clip when space is needed.';

  @override
  String get clear => 'Clear';

  @override
  String get protectionCleared => 'Protection cleared';

  @override
  String get share => 'Share';

  @override
  String get clearProtection => 'Clear protection';

  @override
  String get clipActions => 'Clip actions';

  @override
  String get protected => 'Protected';

  @override
  String get couldNotPlayClip => 'Could not play this clip';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get errorCameraPermission => 'Camera permission is required';

  @override
  String get errorLowStorage =>
      'Less than 500 MB free. Free up space and try again';

  @override
  String get errorStorageUnavailable => 'Clip storage is not available';

  @override
  String get errorServiceFailed => 'The recording service could not start';

  @override
  String get errorRecordingInProgress => 'Stop the current recording first';

  @override
  String get errorInvalidArgs => 'These recording settings are not valid';

  @override
  String get errorClipNotFound => 'That clip is gone';

  @override
  String get errorShareFailed => 'Could not open the share sheet';

  @override
  String get errorFolder => 'Could not use that folder';

  @override
  String get errorPickerBusy => 'The folder picker is already open';

  @override
  String get errorRecordingFailed => 'Recording failed';

  @override
  String get today => 'Today';

  @override
  String get set => 'Set';

  @override
  String numberRange(int min, int max) {
    return '$min to $max';
  }

  @override
  String get crashSensitivityInfo =>
      'A hard jolt marks the clip being recorded as protected, so the loop keeps it';
}
