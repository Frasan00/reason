import 'package:intl/intl.dart';

String formatElapsed(int milliseconds) {
  final seconds = (milliseconds ~/ 1000).clamp(0, 359999);
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remaining = seconds % 60;
  return '${_two(hours)}:${_two(minutes)}:${_two(remaining)}';
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  // 1048575 bytes rounds to "1024.0 KB"; promote it to "1.0 MB" instead.
  if (double.parse(value.toStringAsFixed(1)) >= 1024 &&
      unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(1)} ${units[unit]}';
}

double usedFraction(int usedBytes, int budgetBytes) {
  if (budgetBytes <= 0) return 0;
  return (usedBytes / budgetBytes).clamp(0.0, 1.0);
}

String formatDuration(int milliseconds) {
  final totalSeconds = (milliseconds ~/ 1000).clamp(0, 359999);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) return '$hours:${_two(minutes)}:${_two(seconds)}';
  return '$minutes:${_two(seconds)}';
}

String formatClipStart(
  int epochMs, {
  required String locale,
  required String today,
  DateTime? now,
}) {
  final start = DateTime.fromMillisecondsSinceEpoch(epochMs);
  final current = now ?? DateTime.now();
  final time = _hourMinute(locale, start);
  final sameDay =
      start.year == current.year &&
      start.month == current.month &&
      start.day == current.day;
  if (sameDay) return '$today $time';
  if (start.year != current.year) {
    return '${DateFormat.yMMMd(locale).format(start)} $time';
  }
  return '${DateFormat.MMMd(locale).format(start)} $time';
}

String formatClipStartFull(int epochMs, {required String locale}) {
  final start = DateTime.fromMillisecondsSinceEpoch(epochMs);
  return '${DateFormat.yMMMMd(locale).format(start)}, '
      '${_hourMinute(locale, start)}';
}

/// Dash-cam clips read better on a 24-hour clock than on the locale's am/pm.
String _hourMinute(String locale, DateTime time) =>
    DateFormat('HH:mm', locale).format(time);

String _two(int value) => value.toString().padLeft(2, '0');
