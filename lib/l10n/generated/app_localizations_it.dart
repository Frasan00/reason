// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get settings => 'Impostazioni';

  @override
  String get tabRecording => 'Registrazione';

  @override
  String get tabSafety => 'Sicurezza';

  @override
  String get tabCar => 'Auto';

  @override
  String get tabStorage => 'Archiviazione';

  @override
  String get tabSystem => 'Sistema';

  @override
  String get resolution => 'Risoluzione';

  @override
  String get dataSaver => 'Risparmio spazio';

  @override
  String get dataSaverDetail => 'Stessa risoluzione, file più piccoli';

  @override
  String get dataSaverInfo =>
      'Registra con un bitrate più basso: il file è circa un terzo del normale. L\'immagine resta alla risoluzione che hai scelto.';

  @override
  String get segmentLength => 'Durata segmenti';

  @override
  String get burnTimestamp => 'Data e ora nel video';

  @override
  String get burnTimestampDetail => 'Data e ora nell\'angolo di ogni clip';

  @override
  String get timeZone => 'Fuso orario';

  @override
  String get timeZoneSystem => 'Sistema';

  @override
  String get timeZoneSearch => 'Cerca un fuso orario';

  @override
  String get recordAudio => 'Registra l\'audio';

  @override
  String get recordAudioDetail => 'Il suono del microfono insieme al video';

  @override
  String get microphoneNeeded => 'Serve il permesso per il microfono';

  @override
  String get custom => 'Personalizzato';

  @override
  String get minutesUnit => 'min';

  @override
  String get customTitle => 'Valore personalizzato';

  @override
  String get camera => 'Fotocamera';

  @override
  String get rear => 'Posteriore';

  @override
  String get front => 'Anteriore';

  @override
  String get crashSensitivity => 'Sensibilità agli urti';

  @override
  String get crashLow => 'Bassa';

  @override
  String get crashNormal => 'Normale';

  @override
  String get crashHigh => 'Alta';

  @override
  String get carStart => 'Avvio in auto';

  @override
  String get carStartDetail =>
      'Registra da sola quando compare un segnale qui sotto, a volte con una notifica da toccare';

  @override
  String get carBluetooth => 'Bluetooth dell\'auto';

  @override
  String get carBluetoothDetail => 'Si collega un dispositivo audio dell\'auto';

  @override
  String get carBluetoothInfo =>
      'Parte quando un dispositivo audio dell\'auto si collega e si ferma quando si scollega. Non usa sensori, quindi non consuma batteria. Serve il permesso Dispositivi nelle vicinanze. Anche un paio di cuffie Bluetooth può farla partire.';

  @override
  String get carMotion => 'Carica e movimento';

  @override
  String get carMotionDetail => 'Il telefono è in carica e si muove';

  @override
  String get carMotionInfo =>
      'Parte quando il telefono è in carica e il sensore di movimento rileva spostamenti, e si ferma dieci minuti dopo l\'ultimo movimento. Non serve nessun permesso. Anche urtare il telefono sul caricatore può farla partire.';

  @override
  String get carVehicle => 'Rilevamento veicolo di Google';

  @override
  String get carVehicleDetail => 'Il telefono segnala di essere in un veicolo';

  @override
  String get carVehicleInfo =>
      'Usa il riconoscimento delle attività di Google Play services, che legge i dati a intervalli e consuma pochissima batteria. Si accorge di un viaggio dopo circa un minuto. Serve il permesso Attività fisica.';

  @override
  String get applyNextRecording => 'Vale dalla registrazione successiva';

  @override
  String get destination => 'Destinazione';

  @override
  String get appStorage => 'Memoria dell\'app';

  @override
  String get choose => 'Scegli';

  @override
  String get change => 'Cambia';

  @override
  String get useAppStorage => 'Usa la memoria dell\'app';

  @override
  String get clipsGrouped => 'Le clip sono divise per anno, mese e giorno';

  @override
  String get storageBudget => 'Budget di spazio';

  @override
  String get destroyAfter => 'Elimina dopo';

  @override
  String get destroyAfterDetail => 'Le clip vecchie vengono cancellate da sole';

  @override
  String get destroyOff => 'Mai';

  @override
  String get destroyHours => '1 ora';

  @override
  String get destroyDay => '1 giorno';

  @override
  String get destroyWeek => '7 giorni';

  @override
  String get destroyKeepsProtected =>
      'Le clip protette restano finché non togli la protezione dalla libreria';

  @override
  String get destroyUnit => 'Unità';

  @override
  String get unitMinutes => 'Minuti';

  @override
  String get unitHours => 'Ore';

  @override
  String get unitDays => 'Giorni';

  @override
  String get language => 'Lingua';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get batteryOptimization => 'Ottimizzazione batteria';

  @override
  String get batteryExempt => 'Esente';

  @override
  String get batteryNotExempt => 'Non esente';

  @override
  String get checking => 'Controllo';

  @override
  String get allow => 'Consenti';

  @override
  String get clipsTooltip => 'Clip';

  @override
  String get settingsTooltip => 'Impostazioni';

  @override
  String get startRecording => 'Avvia la registrazione';

  @override
  String get stopRecording => 'Ferma la registrazione';

  @override
  String get recordingLabel => 'Registrazione';

  @override
  String get startingCamera => 'Avvio della fotocamera';

  @override
  String get warningLowStorage =>
      'Registrazione fermata. Meno di 500 MB liberi';

  @override
  String get warningStorageError =>
      'Registrazione fermata. La memoria non è disponibile';

  @override
  String get warningCameraError =>
      'Registrazione fermata. Errore della fotocamera';

  @override
  String get warningRecorderError =>
      'Registrazione fermata. Errore di registrazione';

  @override
  String get warningGeneric => 'Registrazione fermata';

  @override
  String get batteryDialogTitle => 'Continua a registrare a schermo spento';

  @override
  String get batteryDialogBody =>
      'Android può fermare la registrazione quando lo schermo è spento. Vuoi permettere a reason di funzionare senza ottimizzazione della batteria?';

  @override
  String get notNow => 'Non ora';

  @override
  String get notificationsOff =>
      'Le notifiche sono disattivate: il pulsante per fermare non comparirà';

  @override
  String get cameraNeededTitle => 'Serve l\'accesso alla fotocamera';

  @override
  String get cameraNeededBody =>
      'reason registra con la fotocamera: senza il permesso non può funzionare';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get openSettings => 'Apri le impostazioni';

  @override
  String get noCameraTitle => 'Nessuna fotocamera utilizzabile';

  @override
  String get noCameraBody =>
      'Questo telefono non ha una fotocamera posteriore o anteriore che possa registrare video';

  @override
  String get checkAgain => 'Ricontrolla';

  @override
  String get couldNotStartCamera =>
      'Non è stato possibile avviare la fotocamera';

  @override
  String get clipsTitle => 'Clip';

  @override
  String get noClipsTitle => 'Nessuna clip';

  @override
  String get noClipsBody => 'Le clip registrate compaiono qui';

  @override
  String get couldNotReadClips => 'Non è stato possibile leggere le clip';

  @override
  String get deleteClipTitle => 'Eliminare la clip?';

  @override
  String get deleteClipProtectedBody =>
      'La clip è protetta. Eliminandola sparisce anche il segno di protezione.';

  @override
  String get deleteClipBody => 'La clip viene rimossa dal telefono.';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get clipDeleted => 'Clip eliminata';

  @override
  String get clearProtectionTitle => 'Togliere la protezione?';

  @override
  String get clearProtectionBody =>
      'Il loop potrà eliminare questa clip quando serve spazio.';

  @override
  String get clear => 'Togli';

  @override
  String get protectionCleared => 'Protezione tolta';

  @override
  String get share => 'Condividi';

  @override
  String get clearProtection => 'Togli la protezione';

  @override
  String get clipActions => 'Azioni sulla clip';

  @override
  String get protected => 'Protetta';

  @override
  String get couldNotPlayClip => 'Non è stato possibile riprodurre la clip';

  @override
  String get play => 'Riproduci';

  @override
  String get pause => 'Pausa';

  @override
  String get errorCameraPermission => 'Serve il permesso per la fotocamera';

  @override
  String get errorLowStorage =>
      'Meno di 500 MB liberi. Libera spazio e riprova';

  @override
  String get errorStorageUnavailable =>
      'La memoria per le clip non è disponibile';

  @override
  String get errorServiceFailed => 'Il servizio di registrazione non è partito';

  @override
  String get errorRecordingInProgress =>
      'Ferma prima la registrazione in corso';

  @override
  String get errorInvalidArgs => 'Queste impostazioni non sono valide';

  @override
  String get errorClipNotFound => 'Quella clip non c\'è più';

  @override
  String get errorShareFailed => 'Non è stato possibile aprire la condivisione';

  @override
  String get errorFolder => 'Non è stato possibile usare quella cartella';

  @override
  String get errorPickerBusy => 'La scelta della cartella è già aperta';

  @override
  String get errorRecordingFailed => 'Registrazione non riuscita';

  @override
  String get today => 'Oggi';

  @override
  String get set => 'Imposta';

  @override
  String numberRange(int min, int max) {
    return 'Da $min a $max';
  }

  @override
  String get crashSensitivityInfo =>
      'Un urto forte segna come protetta la clip in corso, così il loop la conserva';
}
