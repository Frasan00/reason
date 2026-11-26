import 'package:flutter_test/flutter_test.dart';
import 'package:reason/settings.dart';

const _both = Capabilities(
  rear: CameraCapability(
    available: true,
    resolutions: [Resolution.fhd1080, Resolution.hd720],
  ),
  front: CameraCapability(available: true, resolutions: [Resolution.hd720]),
);

void main() {
  test('defaults match the spec', () {
    expect(Settings.defaults.resolution, Resolution.fhd1080);
    expect(Settings.defaults.segmentMinutes, 3);
    expect(Settings.defaults.budgetGb, 2);
    expect(Settings.defaults.camera, CameraFacing.rear);
    expect(Settings.defaults.sensitivity, CrashSensitivity.normal);
    expect(Settings.defaults.autoCar, isFalse);
    expect(Settings.defaults.dataSaver, isFalse);
    expect(Settings.defaults.budgetBytes, 2 * 1024 * 1024 * 1024);
  });

  test('fromMap repairs invalid values', () {
    final settings = Settings.fromMap({
      'resolution': '4k',
      'segmentMinutes': 0,
      'budgetGb': 513,
      'camera': 'side',
      'sensitivity': 'wild',
      'batteryPromptShown': true,
    });
    expect(settings.resolution, Resolution.fhd1080);
    expect(settings.segmentMinutes, 3);
    expect(settings.budgetGb, 2);
    expect(settings.camera, CameraFacing.rear);
    expect(settings.sensitivity, CrashSensitivity.normal);
    expect(settings.batteryPromptShown, isTrue);
  });

  test('toMap round trips', () {
    final settings = Settings.defaults.copyWith(
      segmentMinutes: 7,
      budgetGb: 4,
      camera: CameraFacing.front,
      resolution: Resolution.hd720,
      sensitivity: CrashSensitivity.high,
      dataSaver: true,
      autoCar: true,
      carBluetooth: false,
      carMotion: true,
      carActivity: false,
      storageUri: 'content://tree/x',
      storageLabel: 'Clips',
      destroyAfterMinutes: 90,
      language: AppLanguage.italian,
    );
    expect(Settings.fromMap(settings.toMap()), settings);
  });

  test('destroy after defaults to off and repairs out of range values', () {
    expect(Settings.fromMap({}).destroyAfterMinutes, 0);
    expect(Settings.fromMap({'destroyAfterMinutes': 5}).destroyAfterMinutes, 5);
    expect(
      Settings.fromMap({'destroyAfterMinutes': -3}).destroyAfterMinutes,
      0,
    );
    expect(
      Settings.fromMap({'destroyAfterMinutes': Settings.maxDestroyMinutes + 1})
          .destroyAfterMinutes,
      0,
    );
  });

  test('wrong types fall back instead of crashing', () {
    final settings = Settings.fromMap({
      'segmentMinutes': '5',
      'budgetGb': 2.5,
      'resolution': 1080,
      'storageUri': '',
      'autoCar': 'true',
    });
    expect(settings.segmentMinutes, 3);
    expect(settings.budgetGb, 2);
    expect(settings.resolution, Resolution.fhd1080);
    expect(settings.storageUri, isNull);
    expect(settings.autoCar, isFalse);
  });

  test('timestamp and audio survive a round trip', () {
    final settings = Settings.defaults.copyWith(
      burnTimestamp: true,
      timeZone: 'Europe/Rome',
      audio: true,
    );
    final restored = Settings.fromMap(settings.toMap());
    expect(restored.burnTimestamp, isTrue);
    expect(restored.timeZone, 'Europe/Rome');
    expect(restored.audio, isTrue);
    expect(restored, settings);
  });

  test('the time zone can go back to the system one', () {
    final settings = Settings.defaults.copyWith(timeZone: 'Europe/Rome');
    expect(settings.copyWith(clearTimeZone: true).timeZone, isNull);
  });

  test('audio and the timestamp are off by default', () {
    expect(Settings.fromMap({}).audio, isFalse);
    expect(Settings.fromMap({}).burnTimestamp, isFalse);
    expect(Settings.fromMap({}).timeZone, isNull);
  });

  test('destroy after can be turned off again', () {
    final on = Settings.defaults.copyWith(destroyAfterMinutes: 90);
    expect(on.destroyAfterMinutes, 90);
    expect(on.copyWith(destroyAfterMinutes: 0).destroyAfterMinutes, 0);
  });

  test('language falls back to the system value', () {
    expect(Settings.fromMap({}).language, AppLanguage.system);
    expect(Settings.fromMap({'language': 'it'}).language, AppLanguage.italian);
    expect(Settings.fromMap({'language': 'de'}).language, AppLanguage.german);
    expect(Settings.fromMap({'language': 'pt'}).language, AppLanguage.system);
  });

  test('resolution wire values round trip', () {
    expect(Resolution.fromWire('1440p'), Resolution.qhd1440);
    expect(Resolution.fromWire('1080p'), Resolution.fhd1080);
    expect(Resolution.fromWire('720p'), Resolution.hd720);
    expect(Resolution.fromWire('480p'), Resolution.sd480);
    expect(Resolution.fromWire('4k'), Resolution.fhd1080);
  });

  test('sensitivity wire values round trip', () {
    expect(CrashSensitivity.fromWire('low'), CrashSensitivity.low);
    expect(CrashSensitivity.fromWire('high'), CrashSensitivity.high);
    expect(CrashSensitivity.fromWire(null), CrashSensitivity.normal);
  });

  test('custom values outside the presets are kept', () {
    final settings = Settings.fromMap({'segmentMinutes': 7, 'budgetGb': 4});
    expect(settings.segmentMinutes, 7);
    expect(settings.budgetGb, 4);
  });

  test('car signals default on and can be turned off', () {
    final defaults = Settings.fromMap({});
    expect(defaults.carBluetooth, isTrue);
    expect(defaults.carMotion, isTrue);
    expect(defaults.carActivity, isTrue);
    final off = Settings.fromMap({'carBluetooth': false});
    expect(off.carBluetooth, isFalse);
    expect(off.carMotion, isTrue);
  });

  test('clearing the storage folder drops both fields', () {
    final settings = Settings.defaults.copyWith(
      storageUri: 'content://tree/x',
      storageLabel: 'Clips',
    );
    final cleared = settings.copyWith(clearStorage: true);
    expect(cleared.storageUri, isNull);
    expect(cleared.storageLabel, isNull);
  });

  test('normalize switches an unavailable camera', () {
    const capabilities = Capabilities(
      rear: CameraCapability(available: false, resolutions: []),
      front: CameraCapability(available: true, resolutions: [Resolution.hd720]),
    );
    final normalized = Settings.defaults.normalize(capabilities);
    expect(normalized.camera, CameraFacing.front);
    expect(normalized.resolution, Resolution.hd720);
  });

  test('normalize picks the best supported resolution', () {
    const capabilities = Capabilities(
      rear: CameraCapability(available: true, resolutions: [Resolution.hd720]),
      front: CameraCapability(
        available: true,
        resolutions: [Resolution.fhd1080, Resolution.hd720],
      ),
    );
    expect(
      Settings.defaults.normalize(capabilities).resolution,
      Resolution.hd720,
    );
  });

  test('normalize keeps a supported selection', () {
    expect(Settings.defaults.normalize(_both), Settings.defaults);
  });

  test('capabilities parse native maps', () {
    final capabilities = Capabilities.fromMap({
      'rear': {
        'available': true,
        'resolutions': ['1080p', '720p', '480p'],
      },
      'front': {
        'available': true,
        'resolutions': ['720p'],
      },
    });
    expect(capabilities.rear.resolutions, [
      Resolution.fhd1080,
      Resolution.hd720,
      Resolution.sd480,
    ]);
    expect(capabilities.front.available, isTrue);
    expect(capabilities.bestResolution(CameraFacing.front), Resolution.hd720);
    expect(
      capabilities.supports(CameraFacing.front, Resolution.fhd1080),
      isFalse,
    );
  });

  test('a camera without supported resolutions is unavailable', () {
    final capabilities = Capabilities.fromMap({
      'rear': {'available': true, 'resolutions': <String>[]},
      'front': {'available': false, 'resolutions': <String>[]},
    });
    expect(capabilities.rear.available, isFalse);
    expect(capabilities.hasCamera, isFalse);
  });
}
