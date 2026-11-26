import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CameraFacing {
  rear('rear'),
  front('front');

  const CameraFacing(this.wire);

  final String wire;

  static CameraFacing fromWire(Object? value) =>
      value == 'front' ? CameraFacing.front : CameraFacing.rear;
}

enum Resolution {
  qhd1440('1440p'),
  fhd1080('1080p'),
  hd720('720p'),
  sd480('480p');

  const Resolution(this.wire);

  final String wire;

  static Resolution fromWire(Object? value) =>
      tryFromWire(value) ?? Resolution.fhd1080;

  static Resolution? tryFromWire(Object? value) {
    for (final resolution in Resolution.values) {
      if (resolution.wire == value) return resolution;
    }
    return null;
  }
}

enum AppLanguage {
  system('system', null),
  english('en', 'en'),
  italian('it', 'it'),
  french('fr', 'fr'),
  spanish('es', 'es'),
  german('de', 'de');

  const AppLanguage(this.wire, this.localeCode);

  final String wire;
  final String? localeCode;

  static AppLanguage fromWire(Object? value) {
    for (final language in AppLanguage.values) {
      if (language.wire == value) return language;
    }
    return AppLanguage.system;
  }
}

enum CrashSensitivity {
  low('low'),
  normal('normal'),
  high('high');

  const CrashSensitivity(this.wire);

  final String wire;

  static CrashSensitivity fromWire(Object? value) => switch (value) {
    'low' => CrashSensitivity.low,
    'high' => CrashSensitivity.high,
    _ => CrashSensitivity.normal,
  };
}

@immutable
class CameraCapability {
  const CameraCapability({required this.available, required this.resolutions});

  static const none = CameraCapability(available: false, resolutions: []);

  final bool available;
  final List<Resolution> resolutions;
}

@immutable
class Capabilities {
  const Capabilities({required this.rear, required this.front});

  static const optimistic = Capabilities(
    rear: CameraCapability(
      available: true,
      resolutions: [
        Resolution.qhd1440,
        Resolution.fhd1080,
        Resolution.hd720,
        Resolution.sd480,
      ],
    ),
    front: CameraCapability(
      available: true,
      resolutions: [
        Resolution.qhd1440,
        Resolution.fhd1080,
        Resolution.hd720,
        Resolution.sd480,
      ],
    ),
  );

  factory Capabilities.fromMap(Map<Object?, Object?> map) {
    CameraCapability parse(Object? value) {
      if (value is! Map) return CameraCapability.none;
      final resolutions = <Resolution>[];
      final raw = value['resolutions'];
      if (raw is List) {
        for (final item in raw) {
          final resolution = Resolution.tryFromWire(item);
          if (resolution != null && !resolutions.contains(resolution)) {
            resolutions.add(resolution);
          }
        }
      }
      return CameraCapability(
        available: value['available'] == true && resolutions.isNotEmpty,
        resolutions: resolutions,
      );
    }

    return Capabilities(rear: parse(map['rear']), front: parse(map['front']));
  }

  final CameraCapability rear;
  final CameraCapability front;

  bool get hasCamera => rear.available || front.available;

  CameraCapability forCamera(CameraFacing camera) =>
      camera == CameraFacing.front ? front : rear;

  bool supports(CameraFacing camera, Resolution resolution) =>
      forCamera(camera).resolutions.contains(resolution);

  Resolution? bestResolution(CameraFacing camera) {
    final resolutions = forCamera(camera).resolutions;
    for (final resolution in Resolution.values) {
      if (resolutions.contains(resolution)) return resolution;
    }
    return null;
  }
}

@immutable
class Settings {
  const Settings({
    required this.resolution,
    required this.segmentMinutes,
    required this.budgetGb,
    required this.camera,
    required this.sensitivity,
    this.dataSaver = false,
    this.autoCar = false,
    this.carBluetooth = true,
    this.carMotion = true,
    this.carActivity = true,
    this.destroyAfterMinutes = 0,
    this.language = AppLanguage.system,
    this.storageUri,
    this.storageLabel,
    this.batteryPromptShown = false,
  });

  static const defaults = Settings(
    resolution: Resolution.fhd1080,
    segmentMinutes: 3,
    budgetGb: 2,
    camera: CameraFacing.rear,
    sensitivity: CrashSensitivity.normal,
  );

  static const segmentOptions = [1, 3, 5];
  static const budgetOptions = [1, 2, 5];
  static const minSegmentMinutes = 1;
  static const maxSegmentMinutes = 60;
  static const minBudgetGb = 1;
  static const maxBudgetGb = 512;

  /// Minutes, 0 means clips are kept until the budget or the user removes them.
  static const destroyAfterOptions = [0, 60, 1440, 10080];
  static const minDestroyMinutes = 1;
  static const maxDestroyMinutes = 365 * 24 * 60;

  final Resolution resolution;
  final int segmentMinutes;
  final int budgetGb;
  final CameraFacing camera;
  final CrashSensitivity sensitivity;
  final bool dataSaver;
  final bool autoCar;
  final bool carBluetooth;
  final bool carMotion;
  final bool carActivity;
  final int destroyAfterMinutes;
  final AppLanguage language;
  final String? storageUri;
  final String? storageLabel;
  final bool batteryPromptShown;

  int get budgetBytes => budgetGb * 1024 * 1024 * 1024;

  Settings copyWith({
    Resolution? resolution,
    int? segmentMinutes,
    int? budgetGb,
    CameraFacing? camera,
    CrashSensitivity? sensitivity,
    bool? dataSaver,
    bool? autoCar,
    bool? carBluetooth,
    bool? carMotion,
    bool? carActivity,
    int? destroyAfterMinutes,
    AppLanguage? language,
    String? storageUri,
    String? storageLabel,
    bool clearStorage = false,
    bool? batteryPromptShown,
  }) {
    return Settings(
      resolution: resolution ?? this.resolution,
      segmentMinutes: segmentMinutes ?? this.segmentMinutes,
      budgetGb: budgetGb ?? this.budgetGb,
      camera: camera ?? this.camera,
      sensitivity: sensitivity ?? this.sensitivity,
      dataSaver: dataSaver ?? this.dataSaver,
      autoCar: autoCar ?? this.autoCar,
      carBluetooth: carBluetooth ?? this.carBluetooth,
      carMotion: carMotion ?? this.carMotion,
      carActivity: carActivity ?? this.carActivity,
      destroyAfterMinutes: destroyAfterMinutes ?? this.destroyAfterMinutes,
      language: language ?? this.language,
      storageUri: clearStorage ? null : storageUri ?? this.storageUri,
      storageLabel: clearStorage ? null : storageLabel ?? this.storageLabel,
      batteryPromptShown: batteryPromptShown ?? this.batteryPromptShown,
    );
  }

  Settings normalize(Capabilities capabilities) {
    var nextCamera = camera;
    if (!capabilities.forCamera(nextCamera).available) {
      final other = nextCamera == CameraFacing.rear
          ? CameraFacing.front
          : CameraFacing.rear;
      if (capabilities.forCamera(other).available) nextCamera = other;
    }
    var nextResolution = resolution;
    if (!capabilities.supports(nextCamera, nextResolution)) {
      nextResolution =
          capabilities.bestResolution(nextCamera) ?? nextResolution;
    }
    return copyWith(camera: nextCamera, resolution: nextResolution);
  }

  Map<String, Object?> toMap() => {
    'resolution': resolution.wire,
    'segmentMinutes': segmentMinutes,
    'budgetGb': budgetGb,
    'camera': camera.wire,
    'sensitivity': sensitivity.wire,
    'dataSaver': dataSaver,
    'autoCar': autoCar,
    'carBluetooth': carBluetooth,
    'carMotion': carMotion,
    'carActivity': carActivity,
    'destroyAfterMinutes': destroyAfterMinutes,
    'language': language.wire,
    'storageUri': storageUri,
    'storageLabel': storageLabel,
    'batteryPromptShown': batteryPromptShown,
  };

  factory Settings.fromMap(Map<Object?, Object?> map) {
    String? stringOf(Object? value) =>
        value is String && value.isNotEmpty ? value : null;

    return Settings(
      resolution: Resolution.fromWire(map['resolution']),
      segmentMinutes: _intInRange(
        map['segmentMinutes'],
        minSegmentMinutes,
        maxSegmentMinutes,
        3,
      ),
      budgetGb: _intInRange(map['budgetGb'], minBudgetGb, maxBudgetGb, 2),
      camera: CameraFacing.fromWire(map['camera']),
      sensitivity: CrashSensitivity.fromWire(map['sensitivity']),
      dataSaver: map['dataSaver'] == true,
      autoCar: map['autoCar'] == true,
      carBluetooth: map['carBluetooth'] != false,
      carMotion: map['carMotion'] != false,
      carActivity: map['carActivity'] != false,
      destroyAfterMinutes: _intInRange(
        map['destroyAfterMinutes'],
        0,
        maxDestroyMinutes,
        0,
      ),
      language: AppLanguage.fromWire(map['language']),
      storageUri: stringOf(map['storageUri']),
      storageLabel: stringOf(map['storageLabel']),
      batteryPromptShown: map['batteryPromptShown'] == true,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Settings &&
        other.resolution == resolution &&
        other.segmentMinutes == segmentMinutes &&
        other.budgetGb == budgetGb &&
        other.camera == camera &&
        other.sensitivity == sensitivity &&
        other.dataSaver == dataSaver &&
        other.autoCar == autoCar &&
        other.carBluetooth == carBluetooth &&
        other.carMotion == carMotion &&
        other.carActivity == carActivity &&
        other.destroyAfterMinutes == destroyAfterMinutes &&
        other.language == language &&
        other.storageUri == storageUri &&
        other.storageLabel == storageLabel &&
        other.batteryPromptShown == batteryPromptShown;
  }

  @override
  int get hashCode => Object.hash(
    resolution,
    segmentMinutes,
    budgetGb,
    camera,
    sensitivity,
    dataSaver,
    autoCar,
    carBluetooth,
    carMotion,
    carActivity,
    destroyAfterMinutes,
    language,
    storageUri,
    storageLabel,
    batteryPromptShown,
  );
}

int _intInRange(Object? value, int min, int max, int fallback) {
  final number = value is num ? value.toInt() : null;
  return number != null && number >= min && number <= max ? number : fallback;
}

class SettingsStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<Settings> load() async {
    final values = await _preferences.getAll();
    return Settings.fromMap(values);
  }

  Future<void> save(Settings settings) async {
    await _preferences.setString('resolution', settings.resolution.wire);
    await _preferences.setInt('segmentMinutes', settings.segmentMinutes);
    await _preferences.setInt('budgetGb', settings.budgetGb);
    await _preferences.setString('camera', settings.camera.wire);
    await _preferences.setString('sensitivity', settings.sensitivity.wire);
    await _preferences.setBool('dataSaver', settings.dataSaver);
    await _preferences.setBool('autoCar', settings.autoCar);
    await _preferences.setBool('carBluetooth', settings.carBluetooth);
    await _preferences.setBool('carMotion', settings.carMotion);
    await _preferences.setBool('carActivity', settings.carActivity);
    await _preferences.setInt(
      'destroyAfterMinutes',
      settings.destroyAfterMinutes,
    );
    await _preferences.setString('language', settings.language.wire);
    await _preferences.setString('storageUri', settings.storageUri ?? '');
    await _preferences.setString('storageLabel', settings.storageLabel ?? '');
    await _preferences.setBool(
      'batteryPromptShown',
      settings.batteryPromptShown,
    );
  }
}

class SettingsController extends ChangeNotifier {
  SettingsController(this._settings, this._store);

  final SettingsStore _store;
  Settings _settings;
  Future<void> _saveChain = Future.value();

  Settings get settings => _settings;

  Future<void> update(Settings settings) {
    if (settings == _settings) return Future.value();
    _settings = settings;
    notifyListeners();
    // Rapid taps can overlap writes; chain them so the last value wins.
    _saveChain = _saveChain.then((_) async {
      try {
        await _store.save(_settings);
      } catch (error) {
        debugPrint('Could not save settings: $error');
      }
    });
    return _saveChain;
  }

  Future<void> markBatteryPromptShown() {
    return update(_settings.copyWith(batteryPromptShown: true));
  }
}
