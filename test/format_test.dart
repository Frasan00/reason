import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reason/format.dart';

void main() {
  group('formatElapsed', () {
    test('formats zero', () => expect(formatElapsed(0), '00:00:00'));

    test('formats seconds', () {
      expect(formatElapsed(59 * 1000), '00:00:59');
    });

    test('formats hours', () {
      expect(formatElapsed(3661 * 1000), '01:01:01');
    });

    test('clamps negative values', () {
      expect(formatElapsed(-5000), '00:00:00');
    });
  });

  group('formatBytes', () {
    test('formats bytes', () => expect(formatBytes(0), '0 B'));

    test('formats kilobytes', () => expect(formatBytes(1024), '1.0 KB'));

    test('formats a partial unit', () {
      expect(formatBytes(1536), '1.5 KB');
    });

    test('formats gigabytes', () {
      expect(formatBytes(2 * 1024 * 1024 * 1024), '2.0 GB');
    });

    test('stays in bytes just under a unit', () {
      expect(formatBytes(1023), '1023 B');
    });

    test('promotes instead of printing 1024.0 of a unit', () {
      expect(formatBytes(1024 * 1024 - 1), '1.0 MB');
      expect(formatBytes(1024 * 1024 * 1024 - 1), '1.0 GB');
    });

    test('survives a negative count', () {
      expect(formatBytes(-1), '-1 B');
    });
  });

  group('usedFraction', () {
    test('returns zero for a zero budget', () {
      expect(usedFraction(10, 0), 0.0);
    });

    test('clamps over budget', () {
      expect(usedFraction(3, 2), 1.0);
    });

    test('returns the ratio', () {
      expect(usedFraction(1, 2), 0.5);
    });

    test('clamps a negative usage', () {
      expect(usedFraction(-10, 100), 0.0);
    });
  });

  group('formatDuration', () {
    test('formats zero', () => expect(formatDuration(0), '0:00'));

    test('formats seconds', () {
      expect(formatDuration(5 * 1000), '0:05');
    });

    test('formats minutes', () {
      expect(formatDuration(125 * 1000), '2:05');
    });

    test('formats hours', () {
      expect(formatDuration(3723 * 1000), '1:02:03');
    });

    test('clamps beyond 99 hours', () {
      expect(formatDuration(1000 * 3600 * 1000), '99:59:59');
    });
  });

  group('formatClipStart', () {
    setUpAll(() async {
      await initializeDateFormatting('it');
    });

    test('uses Today for the same local day', () {
      final now = DateTime(2026, 11, 25, 10);
      final start = DateTime(2026, 11, 25, 9, 5);
      expect(
        formatClipStart(
          start.millisecondsSinceEpoch,
          locale: 'en',
          today: 'Today',
          now: now,
        ),
        'Today 09:05',
      );
    });

    test('shows the date for an earlier day', () {
      final now = DateTime(2026, 11, 25, 10);
      final start = DateTime(2026, 11, 24, 18, 42);
      expect(
        formatClipStart(
          start.millisecondsSinceEpoch,
          locale: 'en',
          today: 'Today',
          now: now,
        ),
        'Nov 24 18:42',
      );
    });

    test('uses the locale month name', () {
      final now = DateTime(2026, 11, 25, 10);
      final start = DateTime(2026, 11, 24, 18, 42);
      expect(
        formatClipStart(
          start.millisecondsSinceEpoch,
          locale: 'it',
          today: 'Oggi',
          now: now,
        ),
        '24 nov 18:42',
      );
    });

    test('shows the year for a clip from another year', () {
      final now = DateTime(2027, 1, 2, 10);
      final start = DateTime(2026, 11, 24, 18, 42);
      expect(
        formatClipStart(
          start.millisecondsSinceEpoch,
          locale: 'en',
          today: 'Today',
          now: now,
        ),
        'Nov 24, 2026 18:42',
      );
    });

    test('formats the full start', () {
      final start = DateTime(2026, 11, 24, 18, 42);
      expect(
        formatClipStartFull(start.millisecondsSinceEpoch, locale: 'en'),
        'November 24, 2026, 18:42',
      );
    });
  });
}
