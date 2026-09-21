import 'package:teddoro/domain/models/session_type.dart';

enum TimerStatus {
  idle,
  running,
  paused;

  static TimerStatus fromKey(String? key) =>
      values.firstWhere((s) => s.name == key, orElse: () => idle);
}

/// Immutable, persistable state of the timer.
///
/// While running, the source of truth is [endsAt] (an absolute instant), so
/// backgrounding, sleep or a killed process never drifts the countdown.
class TimerSnapshot {
  const TimerSnapshot({
    required this.type,
    required this.status,
    required this.durationSeconds,
    required this.cycleCount,
    this.endsAt,
    this.startedAt,
    this.pausedRemainingSeconds,
  });

  const TimerSnapshot.idle({
    required this.type,
    required this.durationSeconds,
    this.cycleCount = 0,
  }) : status = TimerStatus.idle,
       endsAt = null,
       startedAt = null,
       pausedRemainingSeconds = null;

  final SessionType type;
  final TimerStatus status;
  final int durationSeconds;

  /// Completed work sessions in the current long-break cycle.
  final int cycleCount;

  /// Instant the session will finish. Only set while running.
  final DateTime? endsAt;

  /// Instant the session was first started. Set while running or paused.
  final DateTime? startedAt;

  /// Seconds left when paused. Only set while paused.
  final int? pausedRemainingSeconds;

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isIdle => status == TimerStatus.idle;

  /// Seconds remaining at [now], clamped to `0..durationSeconds`.
  int remainingSeconds(DateTime now) {
    final raw = switch (status) {
      TimerStatus.idle => durationSeconds,
      TimerStatus.paused => pausedRemainingSeconds ?? durationSeconds,
      TimerStatus.running => _secondsUntil(endsAt, now),
    };
    return raw.clamp(0, durationSeconds);
  }

  /// Fraction of the session elapsed, 0.0 → 1.0.
  double progress(DateTime now) {
    if (durationSeconds == 0) return 1;
    return 1 - remainingSeconds(now) / durationSeconds;
  }

  int _secondsUntil(DateTime? target, DateTime now) {
    if (target == null) return durationSeconds;
    // Round up so the display doesn't show 0 while there is time left.
    final ms = target.difference(now).inMilliseconds;
    return (ms / 1000).ceil();
  }

  TimerSnapshot copyWith({
    SessionType? type,
    TimerStatus? status,
    int? durationSeconds,
    int? cycleCount,
    DateTime? endsAt,
    bool clearEndsAt = false,
    DateTime? startedAt,
    bool clearStartedAt = false,
    int? pausedRemainingSeconds,
    bool clearPausedRemaining = false,
  }) => TimerSnapshot(
    type: type ?? this.type,
    status: status ?? this.status,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    cycleCount: cycleCount ?? this.cycleCount,
    endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
    startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
    pausedRemainingSeconds: clearPausedRemaining
        ? null
        : (pausedRemainingSeconds ?? this.pausedRemainingSeconds),
  );

  Map<String, Object?> toJson() => {
    'type': type.key,
    'status': status.name,
    'duration': durationSeconds,
    'cycle': cycleCount,
    'endsAt': endsAt?.toUtc().toIso8601String(),
    'startedAt': startedAt?.toUtc().toIso8601String(),
    'pausedRemaining': pausedRemainingSeconds,
  };

  factory TimerSnapshot.fromJson(Map<String, Object?> json) => TimerSnapshot(
    type: SessionType.fromKey(json['type'] as String?),
    status: TimerStatus.fromKey(json['status'] as String?),
    durationSeconds: json['duration'] as int? ?? 25 * 60,
    cycleCount: json['cycle'] as int? ?? 0,
    endsAt: _parse(json['endsAt']),
    startedAt: _parse(json['startedAt']),
    pausedRemainingSeconds: json['pausedRemaining'] as int?,
  );

  static DateTime? _parse(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
}
