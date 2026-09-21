/// Formats [totalSeconds] as `m:ss`, or `h:mm:ss` past an hour.
String formatCountdown(int totalSeconds) {
  final s = totalSeconds.clamp(0, 359999);
  final hours = s ~/ 3600;
  final minutes = (s % 3600) ~/ 60;
  final seconds = s % 60;
  final mm = minutes.toString().padLeft(hours > 0 ? 2 : 1, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}

/// Human-friendly duration like `2h 15m` or `45m`.
String formatFocusTime(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}
