import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'settings.dart';

@immutable
class RecorderStatus {
  const RecorderStatus({
    required this.state,
    required this.camera,
    required this.resolution,
    required this.segmentMinutes,
    required this.budgetBytes,
    required this.sessionElapsedMs,
    required this.segmentIndex,
    required this.usedBytes,
    required this.freeBytes,
    required this.recording,
    this.warning,
    this.lastError,
  });

  static const idle = RecorderStatus(
    state: 'idle',
    camera: 'rear',
    resolution: '1080p',
    segmentMinutes: 3,
    budgetBytes: 2 * 1024 * 1024 * 1024,
    sessionElapsedMs: 0,
    segmentIndex: 0,
    usedBytes: 0,
    freeBytes: 0,
    recording: false,
  );

  factory RecorderStatus.fromMap(Map<Object?, Object?> map) {
    int intOf(Object? value, int fallback) =>
        value is num ? value.toInt() : fallback;

    return RecorderStatus(
      state: map['state'] is String ? map['state'] as String : 'idle',
      camera: map['camera'] is String ? map['camera'] as String : 'rear',
      resolution: map['resolution'] is String
          ? map['resolution'] as String
          : '1080p',
      segmentMinutes: intOf(map['segmentMinutes'], 3),
      budgetBytes: intOf(map['budgetBytes'], 2 * 1024 * 1024 * 1024),
      sessionElapsedMs: intOf(map['sessionElapsedMs'], 0),
      segmentIndex: intOf(map['segmentIndex'], 0),
      usedBytes: intOf(map['usedBytes'], 0),
      freeBytes: intOf(map['freeBytes'], 0),
      recording: map['recording'] == true || map['state'] == 'recording',
      warning: map['warning'] is String && (map['warning'] as String).isNotEmpty
          ? map['warning'] as String
          : null,
      lastError: map['lastError'] is String ? map['lastError'] as String : null,
    );
  }

  final String state;
  final String camera;
  final String resolution;
  final int segmentMinutes;
  final int budgetBytes;
  final int sessionElapsedMs;
  final int segmentIndex;
  final int usedBytes;
  final int freeBytes;
  final bool recording;
  final String? warning;
  final String? lastError;

  bool get isBusy => state == 'starting' || state == 'stopping';
}

@immutable
class ClipInfo {
  const ClipInfo({
    required this.name,
    required this.uri,
    required this.startEpochMs,
    required this.sizeBytes,
    required this.durationMs,
    required this.isProtected,
  });

  factory ClipInfo.fromMap(Map<Object?, Object?> map) {
    int intOf(Object? value) => value is num ? value.toInt() : 0;
    final rawUri = map['uri'] ?? map['path'];
    return ClipInfo(
      name: map['name'] is String ? map['name'] as String : '',
      uri: rawUri is String ? rawUri : '',
      startEpochMs: intOf(map['startEpochMs']),
      sizeBytes: intOf(map['sizeBytes']),
      durationMs: intOf(map['durationMs']),
      isProtected: map['protected'] == true,
    );
  }

  final String name;
  final String uri;
  final int startEpochMs;
  final int sizeBytes;
  final int durationMs;
  final bool isProtected;
}

class RecorderException implements Exception {
  RecorderException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

class RecorderController extends ChangeNotifier {
  static const _channel = MethodChannel('reason/recorder');
  static const _events = EventChannel('reason/recorder_events');

  RecorderStatus _status = RecorderStatus.idle;
  StreamSubscription<dynamic>? _subscription;
  bool _orientationLocked = false;

  RecorderStatus get status => _status;

  Future<void> init() async {
    _subscription ??= _events.receiveBroadcastStream().listen(
      _apply,
      onError: (Object error) {
        debugPrint('Recorder event stream error: $error');
      },
      onDone: () => _subscription = null,
    );
    await sync();
  }

  Future<RecorderStatus> sync() async {
    final raw = await _invoke('getStatus');
    if (raw is Map) {
      _apply(raw);
    }
    return _status;
  }

  Future<Capabilities> getCapabilities() async {
    try {
      final raw = await _invoke('getCapabilities');
      if (raw is Map) return Capabilities.fromMap(raw);
    } on RecorderException catch (error) {
      debugPrint('Camera capabilities unavailable: $error');
    }
    return Capabilities.optimistic;
  }

  Future<void> startPreview(Settings settings) async {
    await _invoke('startPreview', {
      'camera': settings.camera.wire,
      'resolution': settings.resolution.wire,
    });
  }

  Future<void> startRecording(Settings settings) async {
    await _invoke('startRecording', {
      'camera': settings.camera.wire,
      'resolution': settings.resolution.wire,
      'segmentMinutes': settings.segmentMinutes,
      'budgetBytes': settings.budgetBytes,
      'sensitivity': settings.sensitivity.wire,
      'dataSaver': settings.dataSaver,
      'destroyAfterMinutes': settings.destroyAfterMinutes,
      'audio': settings.audio,
      'stamp': settings.burnTimestamp,
      'zone': settings.timeZone,
    });
  }

  Future<void> stopRecording() async {
    await _invoke('stopRecording');
  }

  Future<void> enableCarMode(Settings settings) async {
    await _invoke('setCarMode', {
      'camera': settings.camera.wire,
      'resolution': settings.resolution.wire,
      'segmentMinutes': settings.segmentMinutes,
      'budgetBytes': settings.budgetBytes,
      'sensitivity': settings.sensitivity.wire,
      'dataSaver': settings.dataSaver,
      'destroyAfterMinutes': settings.destroyAfterMinutes,
      'audio': settings.audio,
      'stamp': settings.burnTimestamp,
      'zone': settings.timeZone,
      'bluetooth': settings.carBluetooth,
      'motion': settings.carMotion,
      'activity': settings.carActivity,
    });
  }

  Future<void> disableCarMode() async {
    await _invoke('clearCarMode');
  }

  Future<({String uri, String label})?> pickStorageFolder() async {
    final raw = await _invoke('pickStorageFolder');
    if (raw is! Map) return null;
    final uri = raw['uri'];
    if (uri is! String || uri.isEmpty) return null;
    final label = raw['label'];
    return (
      uri: uri,
      label: label is String && label.isNotEmpty ? label : 'Folder',
    );
  }

  Future<void> setStorageFolder(String? uri) async {
    await _invoke('setStorageFolder', {'uri': uri});
  }

  Future<void> applyRetention(int minutes) async {
    await _invoke('applyRetention', {'minutes': minutes});
  }

  Future<List<String>> getTimeZones() async {
    final raw = await _invoke('getTimeZones');
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  Future<void> setLanguage(AppLanguage language) async {
    await _invoke('setLanguage', {'language': language.wire});
  }

  Future<void> stopPreview() async {
    await _invoke('stopPreview');
  }

  Future<List<ClipInfo>> listClips() async {
    final raw = await _invoke('listClips');
    if (raw is! List) return const [];
    final clips = <ClipInfo>[];
    for (final item in raw) {
      if (item is Map) {
        final clip = ClipInfo.fromMap(Map<Object?, Object?>.from(item));
        if (clip.name.isNotEmpty && clip.uri.isNotEmpty) clips.add(clip);
      }
    }
    clips.sort((a, b) => b.startEpochMs.compareTo(a.startEpochMs));
    return clips;
  }

  Future<void> deleteClip(String name) async {
    await _invoke('deleteClip', {'name': name});
  }

  Future<void> clearProtection(String name) async {
    await _invoke('clearProtection', {'name': name});
  }

  Future<void> shareClip(String name) async {
    await _invoke('shareClip', {'name': name});
  }

  void _apply(dynamic event) {
    if (event is! Map) return;
    final next = RecorderStatus.fromMap(event);
    final recordingChanged = next.recording != _status.recording;
    _status = next;
    if (recordingChanged) _lockOrientation(next.recording);
    notifyListeners();
  }

  Future<void> _lockOrientation(bool locked) async {
    if (_orientationLocked == locked) return;
    _orientationLocked = locked;
    try {
      await _channel.invokeMethod<void>('setOrientationLocked', locked);
    } on PlatformException {
      // Orientation is cosmetic; it must not break recording.
    } on MissingPluginException {
      // No native side in widget tests.
    }
  }

  Future<dynamic> _invoke(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _channel.invokeMethod<dynamic>(method, arguments);
    } on PlatformException catch (error) {
      throw RecorderException(error.code, error.message ?? '');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
