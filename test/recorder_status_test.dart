import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reason/l10n/errors.dart';
import 'package:reason/l10n/generated/app_localizations.dart';
import 'package:reason/recorder_controller.dart';

void main() {
  test('parses a full status map', () {
    final status = RecorderStatus.fromMap({
      'state': 'recording',
      'camera': 'front',
      'resolution': '720p',
      'segmentMinutes': 5,
      'budgetBytes': 1024,
      'sessionElapsedMs': 1234,
      'segmentIndex': 2,
      'usedBytes': 512,
      'freeBytes': 2048,
      'recording': true,
      'warning': 'low_storage',
      'lastError': 'boom',
    });
    expect(status.state, 'recording');
    expect(status.camera, 'front');
    expect(status.resolution, '720p');
    expect(status.segmentMinutes, 5);
    expect(status.budgetBytes, 1024);
    expect(status.sessionElapsedMs, 1234);
    expect(status.segmentIndex, 2);
    expect(status.usedBytes, 512);
    expect(status.freeBytes, 2048);
    expect(status.recording, isTrue);
    expect(status.warning, 'low_storage');
    expect(status.lastError, 'boom');
  });

  test('falls back on missing fields', () {
    final status = RecorderStatus.fromMap({});
    expect(status.state, 'idle');
    expect(status.recording, isFalse);
    expect(status.warning, isNull);
    expect(status.budgetBytes, 2 * 1024 * 1024 * 1024);
  });

  test('treats a recording state as recording without the flag', () {
    expect(RecorderStatus.fromMap({'state': 'recording'}).recording, isTrue);
  });

  test('busy states', () {
    expect(RecorderStatus.fromMap({'state': 'starting'}).isBusy, isTrue);
    expect(RecorderStatus.fromMap({'state': 'stopping'}).isBusy, isTrue);
    expect(RecorderStatus.fromMap({'state': 'previewing'}).isBusy, isFalse);
  });

  test('an empty warning is null', () {
    expect(RecorderStatus.fromMap({'warning': ''}).warning, isNull);
  });

  test('recorder errors read in the chosen language', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final it = await AppLocalizations.delegate.load(const Locale('it'));
    expect(
      RecorderException('low_storage', 'x').text(en),
      'Less than 500 MB free. Free up space and try again',
    );
    expect(
      RecorderException('low_storage', 'x').text(it),
      'Meno di 500 MB liberi. Libera spazio e riprova',
    );
    expect(
      RecorderException('unknown', 'native detail').text(en),
      'Recording failed',
    );
    expect(RecorderException('unknown', '').text(en), 'Recording failed');
  });
}
