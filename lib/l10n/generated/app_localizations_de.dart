// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settings => 'Einstellungen';

  @override
  String get tabRecording => 'Aufnahme';

  @override
  String get tabSafety => 'Sicherheit';

  @override
  String get tabCar => 'Auto';

  @override
  String get tabStorage => 'Speicher';

  @override
  String get tabSystem => 'System';

  @override
  String get resolution => 'Auflösung';

  @override
  String get dataSaver => 'Speicher sparen';

  @override
  String get dataSaverDetail => 'Gleiche Auflösung, kleinere Dateien';

  @override
  String get dataSaverInfo =>
      'Nimmt mit niedrigerer Bitrate auf: die Datei ist etwa ein Drittel der normalen Größe. Das Bild behält die gewählte Auflösung.';

  @override
  String get segmentLength => 'Segmentlänge';

  @override
  String get burnTimestamp => 'Datum und Uhrzeit einbrennen';

  @override
  String get burnTimestampDetail =>
      'Datum und Uhrzeit in der Ecke jeder Aufnahme';

  @override
  String get timeZone => 'Zeitzone';

  @override
  String get timeZoneSystem => 'System';

  @override
  String get timeZoneSearch => 'Zeitzone suchen';

  @override
  String get recordAudio => 'Ton aufnehmen';

  @override
  String get recordAudioDetail => 'Mikrofonton zum Video';

  @override
  String get microphoneNeeded => 'Mikrofon-Berechtigung nötig';

  @override
  String get custom => 'Eigener Wert';

  @override
  String get minutesUnit => 'Min.';

  @override
  String get customTitle => 'Eigener Wert';

  @override
  String get camera => 'Kamera';

  @override
  String get rear => 'Hinten';

  @override
  String get front => 'Vorne';

  @override
  String get crashSensitivity => 'Aufprallempfindlichkeit';

  @override
  String get crashLow => 'Niedrig';

  @override
  String get crashNormal => 'Normal';

  @override
  String get crashHigh => 'Hoch';

  @override
  String get carStart => 'Im Auto starten';

  @override
  String get carStartDetail =>
      'Nimmt von selbst auf, sobald ein Signal unten erscheint, manchmal per Benachrichtigung zum Antippen';

  @override
  String get carBluetooth => 'Bluetooth im Auto';

  @override
  String get carBluetoothDetail => 'Ein Auto-Audiogerät verbindet sich';

  @override
  String get carBluetoothInfo =>
      'Startet, wenn sich ein gekoppeltes Auto-Audiogerät verbindet, und stoppt, wenn es sich trennt. Nutzt keine Sensoren und kostet daher keinen Akku. Braucht die Berechtigung Geräte in der Nähe. Auch ein Bluetooth-Kopfhörer kann die Aufnahme auslösen.';

  @override
  String get carMotion => 'Laden und Bewegung';

  @override
  String get carMotionDetail => 'Das Telefon lädt und bewegt sich';

  @override
  String get carMotionInfo =>
      'Startet, wenn das Telefon lädt und der Bewegungssensor Bewegung erkennt, und stoppt zehn Minuten nach der letzten Bewegung. Braucht keine Berechtigungen. Ein Stoß auf dem Schreibtisch-Ladegerät kann sie ebenfalls auslösen.';

  @override
  String get carVehicle => 'Google-Fahrzeugenkennung';

  @override
  String get carVehicleDetail =>
      'Das Telefon meldet, dass es in einem Fahrzeug ist';

  @override
  String get carVehicleInfo =>
      'Nutzt die Aktivitätserkennung der Google Play-Dienste, die Messwerte bündelt und sehr wenig Akku kostet. Sie erkennt eine Fahrt nach etwa einer Minute. Braucht die Berechtigung Körperliche Aktivität.';

  @override
  String get applyNextRecording => 'Gilt ab der nächsten Aufnahme';

  @override
  String get destination => 'Zielordner';

  @override
  String get appStorage => 'App-Speicher';

  @override
  String get choose => 'Wählen';

  @override
  String get change => 'Ändern';

  @override
  String get useAppStorage => 'App-Speicher verwenden';

  @override
  String get clipsGrouped => 'Clips liegen in Ordnern nach Jahr, Monat und Tag';

  @override
  String get storageBudget => 'Speicherplatz-Limit';

  @override
  String get destroyAfter => 'Löschen nach';

  @override
  String get destroyAfterDetail => 'Alte Clips werden von selbst gelöscht';

  @override
  String get destroyOff => 'Nie';

  @override
  String get destroyHours => '1 Stunde';

  @override
  String get destroyDay => '1 Tag';

  @override
  String get destroyWeek => '7 Tage';

  @override
  String get destroyKeepsProtected =>
      'Geschützte Clips bleiben, bis du den Schutz in der Bibliothek aufhebst';

  @override
  String get destroyUnit => 'Einheit';

  @override
  String get unitMinutes => 'Minuten';

  @override
  String get unitHours => 'Stunden';

  @override
  String get unitDays => 'Tage';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get batteryOptimization => 'Akku-Optimierung';

  @override
  String get batteryExempt => 'Ausgenommen';

  @override
  String get batteryNotExempt => 'Nicht ausgenommen';

  @override
  String get checking => 'Wird geprüft';

  @override
  String get allow => 'Erlauben';

  @override
  String get clipsTooltip => 'Clips';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String get startRecording => 'Aufnahme starten';

  @override
  String get stopRecording => 'Aufnahme stoppen';

  @override
  String get recordingLabel => 'Aufnahme';

  @override
  String get startingCamera => 'Kamera startet';

  @override
  String get warningLowStorage => 'Aufnahme gestoppt. Weniger als 500 MB frei';

  @override
  String get warningStorageError =>
      'Aufnahme gestoppt. Speicher nicht verfügbar';

  @override
  String get warningCameraError => 'Aufnahme gestoppt. Kamerafehler';

  @override
  String get warningRecorderError => 'Aufnahme gestoppt. Aufnahmefehler';

  @override
  String get warningGeneric => 'Aufnahme gestoppt';

  @override
  String get batteryDialogTitle =>
      'Bei ausgeschaltetem Bildschirm weiter aufnehmen';

  @override
  String get batteryDialogBody =>
      'Android kann die Aufnahme stoppen, wenn der Bildschirm aus ist. Darf reason ohne Akku-Optimierung laufen?';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get notificationsOff =>
      'Benachrichtigungen sind aus: die Stopp-Taste erscheint nicht';

  @override
  String get cameraNeededTitle => 'Kamerazugriff nötig';

  @override
  String get cameraNeededBody =>
      'reason nimmt über die Kamera auf und kann ohne Berechtigung nicht laufen';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get noCameraTitle => 'Keine nutzbare Kamera';

  @override
  String get noCameraBody =>
      'Dieses Telefon meldet keine Rück- oder Frontkamera, die Video aufnehmen kann';

  @override
  String get checkAgain => 'Erneut prüfen';

  @override
  String get couldNotStartCamera => 'Die Kamera konnte nicht starten';

  @override
  String get clipsTitle => 'Clips';

  @override
  String get noClipsTitle => 'Noch keine Clips';

  @override
  String get noClipsBody => 'Aufgenommene Clips erscheinen hier';

  @override
  String get couldNotReadClips => 'Clips konnten nicht gelesen werden';

  @override
  String get deleteClipTitle => 'Clip löschen?';

  @override
  String get deleteClipProtectedBody =>
      'Dieser Clip ist geschützt. Beim Löschen verschwindet auch die Schutzmarkierung.';

  @override
  String get deleteClipBody => 'Der Clip wird vom Telefon entfernt.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get clipDeleted => 'Clip gelöscht';

  @override
  String get clearProtectionTitle => 'Schutz aufheben?';

  @override
  String get clearProtectionBody =>
      'Die Schleife kann diesen Clip löschen, wenn Platz gebraucht wird.';

  @override
  String get clear => 'Aufheben';

  @override
  String get protectionCleared => 'Schutz aufgehoben';

  @override
  String get share => 'Teilen';

  @override
  String get clearProtection => 'Schutz aufheben';

  @override
  String get clipActions => 'Clip-Aktionen';

  @override
  String get protected => 'Geschützt';

  @override
  String get couldNotPlayClip => 'Dieser Clip lässt sich nicht abspielen';

  @override
  String get play => 'Abspielen';

  @override
  String get pause => 'Pause';

  @override
  String get errorCameraPermission => 'Kamera-Berechtigung nötig';

  @override
  String get errorLowStorage =>
      'Weniger als 500 MB frei. Platz schaffen und erneut versuchen';

  @override
  String get errorStorageUnavailable => 'Der Clip-Speicher ist nicht verfügbar';

  @override
  String get errorServiceFailed => 'Der Aufnahmedienst konnte nicht starten';

  @override
  String get errorRecordingInProgress => 'Stoppe zuerst die laufende Aufnahme';

  @override
  String get errorInvalidArgs => 'Diese Aufnahmeeinstellungen sind ungültig';

  @override
  String get errorClipNotFound => 'Diesen Clip gibt es nicht mehr';

  @override
  String get errorShareFailed => 'Teilen-Menü konnte nicht geöffnet werden';

  @override
  String get errorFolder => 'Dieser Ordner lässt sich nicht verwenden';

  @override
  String get errorPickerBusy => 'Die Ordnerauswahl ist bereits offen';

  @override
  String get errorRecordingFailed => 'Aufnahme fehlgeschlagen';

  @override
  String get today => 'Heute';

  @override
  String get set => 'Übernehmen';

  @override
  String numberRange(int min, int max) {
    return '$min bis $max';
  }

  @override
  String get crashSensitivityInfo =>
      'Ein harter Stoß markiert den laufenden Clip als geschützt, so behält die Schleife ihn';
}
