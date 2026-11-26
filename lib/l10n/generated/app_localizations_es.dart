// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settings => 'Ajustes';

  @override
  String get tabRecording => 'Grabación';

  @override
  String get tabSafety => 'Seguridad';

  @override
  String get tabCar => 'Coche';

  @override
  String get tabStorage => 'Almacenamiento';

  @override
  String get tabSystem => 'Sistema';

  @override
  String get resolution => 'Resolución';

  @override
  String get dataSaver => 'Ahorro de espacio';

  @override
  String get dataSaverDetail => 'Misma resolución, archivos más pequeños';

  @override
  String get dataSaverInfo =>
      'Graba con una tasa de bits más baja: el archivo ocupa un tercio de lo normal. La imagen mantiene la resolución elegida.';

  @override
  String get segmentLength => 'Duración de los segmentos';

  @override
  String get custom => 'Personalizado';

  @override
  String get minutesUnit => 'min';

  @override
  String get customTitle => 'Valor personalizado';

  @override
  String get camera => 'Cámara';

  @override
  String get rear => 'Trasera';

  @override
  String get front => 'Delantera';

  @override
  String get crashSensitivity => 'Sensibilidad a los golpes';

  @override
  String get crashLow => 'Baja';

  @override
  String get crashNormal => 'Normal';

  @override
  String get crashHigh => 'Alta';

  @override
  String get carStart => 'Iniciar en el coche';

  @override
  String get carStartDetail =>
      'Graba sola cuando aparece una señal de abajo, a veces con una notificación que tocar';

  @override
  String get carBluetooth => 'Bluetooth del coche';

  @override
  String get carBluetoothDetail =>
      'Se conecta un dispositivo de audio del coche';

  @override
  String get carBluetoothInfo =>
      'Empieza cuando un dispositivo de audio del coche vinculado se conecta y se detiene cuando se desconecta. No usa sensores, así que no gasta batería. Necesita el permiso Dispositivos cercanos. Unos auriculares Bluetooth también pueden activarla.';

  @override
  String get carMotion => 'Carga y movimiento';

  @override
  String get carMotionDetail => 'El teléfono carga y se mueve';

  @override
  String get carMotionInfo =>
      'Empieza cuando el teléfono está cargando y el sensor de movimiento nota movimiento, y se detiene diez minutos después del último movimiento. No necesita permisos. Mover el teléfono sobre un cargador de mesa también puede activarla.';

  @override
  String get carVehicle => 'Detección de vehículo de Google';

  @override
  String get carVehicleDetail => 'El teléfono indica que está en un vehículo';

  @override
  String get carVehicleInfo =>
      'Usa el reconocimiento de actividad de los servicios de Google Play, que agrupa las lecturas y gasta muy poca batería. Detecta un viaje al cabo de un minuto aproximadamente. Necesita el permiso Actividad física.';

  @override
  String get applyNextRecording => 'Se aplica a la próxima grabación';

  @override
  String get destination => 'Destino';

  @override
  String get appStorage => 'Almacenamiento de la app';

  @override
  String get choose => 'Elegir';

  @override
  String get change => 'Cambiar';

  @override
  String get useAppStorage => 'Usar el almacenamiento de la app';

  @override
  String get clipsGrouped => 'Los clips se agrupan por año, mes y día';

  @override
  String get storageBudget => 'Límite de espacio';

  @override
  String get destroyAfter => 'Eliminar después';

  @override
  String get destroyAfterDetail => 'Los clips viejos se borran solos';

  @override
  String get destroyOff => 'Nunca';

  @override
  String get destroyHours => '1 hora';

  @override
  String get destroyDay => '1 día';

  @override
  String get destroyWeek => '7 días';

  @override
  String get destroyKeepsProtected =>
      'Los clips protegidos se quedan hasta que quites la protección en la biblioteca';

  @override
  String get destroyUnit => 'Unidad';

  @override
  String get unitMinutes => 'Minutos';

  @override
  String get unitHours => 'Horas';

  @override
  String get unitDays => 'Días';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get batteryOptimization => 'Optimización de batería';

  @override
  String get batteryExempt => 'Exenta';

  @override
  String get batteryNotExempt => 'No exenta';

  @override
  String get checking => 'Comprobando';

  @override
  String get allow => 'Permitir';

  @override
  String get clipsTooltip => 'Clips';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get startRecording => 'Empezar a grabar';

  @override
  String get stopRecording => 'Parar la grabación';

  @override
  String get recordingLabel => 'Grabando';

  @override
  String get startingCamera => 'Iniciando la cámara';

  @override
  String get warningLowStorage =>
      'Grabación detenida. Quedan menos de 500 MB libres';

  @override
  String get warningStorageError =>
      'Grabación detenida. El almacenamiento no está disponible';

  @override
  String get warningCameraError => 'Grabación detenida. Error de la cámara';

  @override
  String get warningRecorderError => 'Grabación detenida. Error de grabación';

  @override
  String get warningGeneric => 'Grabación detenida';

  @override
  String get batteryDialogTitle => 'Seguir grabando con la pantalla apagada';

  @override
  String get batteryDialogBody =>
      'Android puede detener la grabación cuando la pantalla está apagada. ¿Permitir que reason funcione sin optimización de batería?';

  @override
  String get notNow => 'Ahora no';

  @override
  String get notificationsOff =>
      'Las notificaciones están desactivadas: el botón de parar no aparecerá';

  @override
  String get cameraNeededTitle => 'Hace falta acceso a la cámara';

  @override
  String get cameraNeededBody =>
      'reason graba con la cámara: sin el permiso no puede funcionar';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get openSettings => 'Abrir los ajustes';

  @override
  String get noCameraTitle => 'No hay ninguna cámara utilizable';

  @override
  String get noCameraBody =>
      'Este teléfono no tiene una cámara trasera o delantera que pueda grabar vídeo';

  @override
  String get checkAgain => 'Comprobar otra vez';

  @override
  String get couldNotStartCamera => 'No se pudo iniciar la cámara';

  @override
  String get clipsTitle => 'Clips';

  @override
  String get noClipsTitle => 'Todavía no hay clips';

  @override
  String get noClipsBody => 'Los clips grabados aparecen aquí';

  @override
  String get couldNotReadClips => 'No se pudieron leer los clips';

  @override
  String get deleteClipTitle => '¿Eliminar el clip?';

  @override
  String get deleteClipProtectedBody =>
      'Este clip está protegido. Al eliminarlo desaparece también su marca de protección.';

  @override
  String get deleteClipBody => 'El clip se borra del teléfono.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get clipDeleted => 'Clip eliminado';

  @override
  String get clearProtectionTitle => '¿Quitar la protección?';

  @override
  String get clearProtectionBody =>
      'El bucle podrá eliminar este clip cuando haga falta espacio.';

  @override
  String get clear => 'Quitar';

  @override
  String get protectionCleared => 'Protección quitada';

  @override
  String get share => 'Compartir';

  @override
  String get clearProtection => 'Quitar la protección';

  @override
  String get clipActions => 'Acciones del clip';

  @override
  String get protected => 'Protegido';

  @override
  String get couldNotPlayClip => 'No se pudo reproducir este clip';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausa';

  @override
  String get errorCameraPermission => 'Hace falta el permiso de cámara';

  @override
  String get errorLowStorage =>
      'Quedan menos de 500 MB libres. Liberar espacio y volver a intentarlo';

  @override
  String get errorStorageUnavailable =>
      'El almacenamiento de clips no está disponible';

  @override
  String get errorServiceFailed => 'El servicio de grabación no arrancó';

  @override
  String get errorRecordingInProgress => 'Parar antes la grabación en curso';

  @override
  String get errorInvalidArgs => 'Estos ajustes de grabación no son válidos';

  @override
  String get errorClipNotFound => 'Ese clip ya no está';

  @override
  String get errorShareFailed => 'No se pudo abrir el menú de compartir';

  @override
  String get errorFolder => 'No se pudo usar esa carpeta';

  @override
  String get errorPickerBusy => 'El selector de carpetas ya está abierto';

  @override
  String get errorRecordingFailed => 'La grabación falló';

  @override
  String get today => 'Hoy';

  @override
  String get set => 'Fijar';

  @override
  String numberRange(int min, int max) {
    return 'De $min a $max';
  }

  @override
  String get crashSensitivityInfo =>
      'Un golpe fuerte marca el clip en curso como protegido, así el bucle lo conserva';
}
