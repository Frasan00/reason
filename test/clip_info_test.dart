import 'package:flutter_test/flutter_test.dart';
import 'package:reason/recorder_controller.dart';

void main() {
  test('parses a clip map', () {
    final clip = ClipInfo.fromMap({
      'name': '1700000000000.mp4',
      'uri': 'content://test/1700000000000.mp4',
      'startEpochMs': 1700000000000,
      'sizeBytes': 2048,
      'durationMs': 180000,
      'protected': true,
    });
    expect(clip.name, '1700000000000.mp4');
    expect(clip.uri, 'content://test/1700000000000.mp4');
    expect(clip.startEpochMs, 1700000000000);
    expect(clip.sizeBytes, 2048);
    expect(clip.durationMs, 180000);
    expect(clip.isProtected, isTrue);
  });

  test('falls back on missing fields', () {
    final clip = ClipInfo.fromMap({});
    expect(clip.name, '');
    expect(clip.uri, '');
    expect(clip.startEpochMs, 0);
    expect(clip.sizeBytes, 0);
    expect(clip.durationMs, 0);
    expect(clip.isProtected, isFalse);
  });
}
