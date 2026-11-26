// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settings => 'Réglages';

  @override
  String get tabRecording => 'Enregistrement';

  @override
  String get tabSafety => 'Sécurité';

  @override
  String get tabCar => 'Voiture';

  @override
  String get tabStorage => 'Stockage';

  @override
  String get tabSystem => 'Système';

  @override
  String get resolution => 'Résolution';

  @override
  String get dataSaver => 'Économie d\'espace';

  @override
  String get dataSaverDetail => 'Même résolution, fichiers plus légers';

  @override
  String get dataSaverInfo =>
      'Enregistre avec un débit plus faible : le fichier fait environ un tiers de la taille normale. L\'image garde la résolution choisie.';

  @override
  String get segmentLength => 'Durée des segments';

  @override
  String get custom => 'Personnalisé';

  @override
  String get minutesUnit => 'min';

  @override
  String get customTitle => 'Valeur personnalisée';

  @override
  String get camera => 'Caméra';

  @override
  String get rear => 'Arrière';

  @override
  String get front => 'Avant';

  @override
  String get crashSensitivity => 'Sensibilité aux chocs';

  @override
  String get crashLow => 'Faible';

  @override
  String get crashNormal => 'Normale';

  @override
  String get crashHigh => 'Élevée';

  @override
  String get carStart => 'Démarrer en voiture';

  @override
  String get carStartDetail =>
      'Enregistre toute seule quand un signal ci-dessous apparaît, parfois avec une notification à toucher';

  @override
  String get carBluetooth => 'Bluetooth de la voiture';

  @override
  String get carBluetoothDetail =>
      'Un appareil audio de la voiture se connecte';

  @override
  String get carBluetoothInfo =>
      'Démarre quand un appareil audio de voiture appairé se connecte et s\'arrête quand il se déconnecte. Aucun capteur n\'est utilisé, donc pas de batterie consommée. Nécessite l\'autorisation Appareils à proximité. Un casque Bluetooth peut aussi la déclencher.';

  @override
  String get carMotion => 'Charge et mouvement';

  @override
  String get carMotionDetail => 'Le téléphone charge et bouge';

  @override
  String get carMotionInfo =>
      'Démarre quand le téléphone charge et que le capteur de mouvement détecte un déplacement, et s\'arrête dix minutes après le dernier mouvement. Aucune autorisation nécessaire. Heurter le téléphone posé sur un chargeur de bureau peut la déclencher.';

  @override
  String get carVehicle => 'Détection véhicule de Google';

  @override
  String get carVehicleDetail =>
      'Le téléphone signale qu\'il est dans un véhicule';

  @override
  String get carVehicleInfo =>
      'Utilise la reconnaissance d\'activité des services Google Play, qui regroupe ses relevés et consomme très peu de batterie. Elle repère un trajet au bout d\'une minute environ. Nécessite l\'autorisation Activité physique.';

  @override
  String get applyNextRecording => 'S\'applique au prochain enregistrement';

  @override
  String get destination => 'Destination';

  @override
  String get appStorage => 'Stockage de l\'app';

  @override
  String get choose => 'Choisir';

  @override
  String get change => 'Changer';

  @override
  String get useAppStorage => 'Utiliser le stockage de l\'app';

  @override
  String get clipsGrouped => 'Les clips sont rangés par année, mois et jour';

  @override
  String get storageBudget => 'Budget de stockage';

  @override
  String get destroyAfter => 'Supprimer après';

  @override
  String get destroyAfterDetail =>
      'Les vieux clips sont supprimés automatiquement';

  @override
  String get destroyOff => 'Jamais';

  @override
  String get destroyHours => '1 heure';

  @override
  String get destroyDay => '1 jour';

  @override
  String get destroyWeek => '7 jours';

  @override
  String get destroyKeepsProtected =>
      'Les clips protégés restent jusqu\'à ce que la protection soit retirée depuis la bibliothèque';

  @override
  String get destroyUnit => 'Unité';

  @override
  String get unitMinutes => 'Minutes';

  @override
  String get unitHours => 'Heures';

  @override
  String get unitDays => 'Jours';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Système';

  @override
  String get batteryOptimization => 'Optimisation de la batterie';

  @override
  String get batteryExempt => 'Exemptée';

  @override
  String get batteryNotExempt => 'Non exemptée';

  @override
  String get checking => 'Vérification';

  @override
  String get allow => 'Autoriser';

  @override
  String get clipsTooltip => 'Clips';

  @override
  String get settingsTooltip => 'Réglages';

  @override
  String get startRecording => 'Démarrer l\'enregistrement';

  @override
  String get stopRecording => 'Arrêter l\'enregistrement';

  @override
  String get recordingLabel => 'Enregistrement';

  @override
  String get startingCamera => 'Démarrage de la caméra';

  @override
  String get warningLowStorage =>
      'Enregistrement arrêté. Moins de 500 Mo libres';

  @override
  String get warningStorageError =>
      'Enregistrement arrêté. Stockage indisponible';

  @override
  String get warningCameraError => 'Enregistrement arrêté. Erreur de la caméra';

  @override
  String get warningRecorderError =>
      'Enregistrement arrêté. Erreur d\'enregistrement';

  @override
  String get warningGeneric => 'Enregistrement arrêté';

  @override
  String get batteryDialogTitle => 'Continuer à enregistrer écran éteint';

  @override
  String get batteryDialogBody =>
      'Android peut arrêter l\'enregistreur quand l\'écran est éteint. Autoriser reason à fonctionner sans optimisation de la batterie ?';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get notificationsOff =>
      'Les notifications sont désactivées : le bouton d\'arrêt n\'apparaîtra pas';

  @override
  String get cameraNeededTitle => 'L\'accès à la caméra est nécessaire';

  @override
  String get cameraNeededBody =>
      'reason enregistre avec la caméra : sans autorisation, il ne peut pas fonctionner';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get openSettings => 'Ouvrir les réglages';

  @override
  String get noCameraTitle => 'Aucune caméra utilisable';

  @override
  String get noCameraBody =>
      'Ce téléphone n\'a pas de caméra arrière ou avant capable d\'enregistrer une vidéo';

  @override
  String get checkAgain => 'Vérifier à nouveau';

  @override
  String get couldNotStartCamera => 'Impossible de démarrer la caméra';

  @override
  String get clipsTitle => 'Clips';

  @override
  String get noClipsTitle => 'Aucun clip';

  @override
  String get noClipsBody => 'Les clips enregistrés apparaissent ici';

  @override
  String get couldNotReadClips => 'Impossible de lire les clips';

  @override
  String get deleteClipTitle => 'Supprimer le clip ?';

  @override
  String get deleteClipProtectedBody =>
      'Ce clip est protégé. Le supprimer retire aussi sa marque de protection.';

  @override
  String get deleteClipBody => 'Le clip est retiré du téléphone.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get clipDeleted => 'Clip supprimé';

  @override
  String get clearProtectionTitle => 'Retirer la protection ?';

  @override
  String get clearProtectionBody =>
      'La boucle pourra supprimer ce clip quand de l\'espace sera nécessaire.';

  @override
  String get clear => 'Retirer';

  @override
  String get protectionCleared => 'Protection retirée';

  @override
  String get share => 'Partager';

  @override
  String get clearProtection => 'Retirer la protection';

  @override
  String get clipActions => 'Actions du clip';

  @override
  String get protected => 'Protégé';

  @override
  String get couldNotPlayClip => 'Impossible de lire ce clip';

  @override
  String get play => 'Lire';

  @override
  String get pause => 'Pause';

  @override
  String get errorCameraPermission => 'L\'autorisation caméra est nécessaire';

  @override
  String get errorLowStorage =>
      'Moins de 500 Mo libres. Libérer de l\'espace et réessayer';

  @override
  String get errorStorageUnavailable =>
      'Le stockage des clips n\'est pas disponible';

  @override
  String get errorServiceFailed =>
      'Le service d\'enregistrement n\'a pas démarré';

  @override
  String get errorRecordingInProgress =>
      'Arrêter d\'abord l\'enregistrement en cours';

  @override
  String get errorInvalidArgs =>
      'Ces réglages d\'enregistrement ne sont pas valides';

  @override
  String get errorClipNotFound => 'Ce clip n\'existe plus';

  @override
  String get errorShareFailed => 'Impossible d\'ouvrir le partage';

  @override
  String get errorFolder => 'Impossible d\'utiliser ce dossier';

  @override
  String get errorPickerBusy => 'Le choix du dossier est déjà ouvert';

  @override
  String get errorRecordingFailed => 'Échec de l\'enregistrement';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get set => 'Définir';

  @override
  String numberRange(int min, int max) {
    return 'De $min à $max';
  }

  @override
  String get crashSensitivityInfo =>
      'Un choc violent marque le clip en cours comme protégé, et la boucle le garde';
}
