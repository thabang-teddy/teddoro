import 'package:teddoro/domain/models/session_type.dart';
import 'package:teddoro/domain/models/timer_preset.dart';
import 'package:teddoro/domain/timer/timer_snapshot.dart';

/// Durations and auto-start behaviour the engine runs with.
class TimerConfig {
  const TimerConfig({
    required this.preset,
    this.autoStartBreaks = false,
    this.autoStartWork = false,
  });

  final TimerPreset preset;
  final bool autoStartBreaks;
  final bool autoStartWork;

  bool shouldAutoStart(SessionType next) =>
      next.isBreak ? autoStartBreaks : autoStartWork;
}

/// Something that happened as a result of an engine call.
sealed class TimerEvent {
  const TimerEvent();
}

/// A session reached its end (or was skipped with [completed] = false).
final class SessionEnded extends TimerEvent {
  const SessionEnded({
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.activeSeconds,
    required this.completed,
  });

  final SessionType type;
  final DateTime startedAt;
  final DateTime endedAt;
  final int activeSeconds;
  final bool completed;
}

/// A session began counting down. [auto] is true when auto-start kicked in.
final class SessionStarted extends TimerEvent {
  const SessionStarted({required this.type, required this.auto});

  final SessionType type;
  final bool auto;
}

/// Pure state machine for the Pomodoro cycle. Holds no timers of its own;
/// the caller passes `now` into every method so it is trivially testable and
/// survives the app being killed (see [TimerSnapshot.endsAt]).
class TimerEngine {
  TimerEngine({required TimerConfig config, TimerSnapshot? initial})
    : _config = config,
      _snapshot =
          initial ??
          TimerSnapshot.idle(
            type: SessionType.work,
            durationSeconds: config.preset
                .durationFor(SessionType.work)
                .inSeconds,
          );

  TimerConfig _config;
  TimerSnapshot _snapshot;

  TimerConfig get config => _config;
  TimerSnapshot get snapshot => _snapshot;

  int remainingSeconds(DateTime now) => _snapshot.remainingSeconds(now);
  double progress(DateTime now) => _snapshot.progress(now);

  /// Replace durations. An idle session picks up the new length immediately;
  /// a running or paused one keeps the length it started with.
  void updateConfig(TimerConfig config) {
    _config = config;
    if (_snapshot.isIdle) {
      _snapshot = _snapshot.copyWith(
        durationSeconds: _durationFor(_snapshot.type),
      );
    }
  }

  /// Start an idle session or resume a paused one.
  List<TimerEvent> start(DateTime now) {
    switch (_snapshot.status) {
      case TimerStatus.running:
        return const [];
      case TimerStatus.idle:
        _snapshot = _snapshot.copyWith(
          status: TimerStatus.running,
          startedAt: now,
          endsAt: now.add(Duration(seconds: _snapshot.durationSeconds)),
          clearPausedRemaining: true,
        );
        return [SessionStarted(type: _snapshot.type, auto: false)];
      case TimerStatus.paused:
        final remaining = _snapshot.remainingSeconds(now);
        _snapshot = _snapshot.copyWith(
          status: TimerStatus.running,
          endsAt: now.add(Duration(seconds: remaining)),
          clearPausedRemaining: true,
        );
        return const [];
    }
  }

  List<TimerEvent> pause(DateTime now) {
    if (!_snapshot.isRunning) return const [];
    _snapshot = _snapshot.copyWith(
      status: TimerStatus.paused,
      pausedRemainingSeconds: _snapshot.remainingSeconds(now),
      clearEndsAt: true,
    );
    return const [];
  }

  /// End the current session early and move to the next one (idle).
  List<TimerEvent> skip(DateTime now) {
    final events = <TimerEvent>[];
    final started = _snapshot.startedAt;
    if (started != null) {
      events.add(
        SessionEnded(
          type: _snapshot.type,
          startedAt: started,
          endedAt: now,
          activeSeconds:
              _snapshot.durationSeconds - _snapshot.remainingSeconds(now),
          completed: false,
        ),
      );
    }
    // A skipped work session still advances the cycle so the user can
    // reach a long break; a skipped break just returns to work.
    final next = _advance(countWork: _snapshot.type == SessionType.work);
    _snapshot = next;
    return events;
  }

  /// Put the current session back to its full length, idle.
  List<TimerEvent> reset() {
    _snapshot = TimerSnapshot.idle(
      type: _snapshot.type,
      durationSeconds: _durationFor(_snapshot.type),
      cycleCount: _snapshot.cycleCount,
    );
    return const [];
  }

  /// Check whether a running session has finished. Call this regularly and
  /// once on app launch. Set [allowAutoStart] false on launch so a session
  /// that ended while the app was dead does not chain into the next one.
  List<TimerEvent> tick(DateTime now, {bool allowAutoStart = true}) {
    final endsAt = _snapshot.endsAt;
    if (!_snapshot.isRunning || endsAt == null) return const [];
    if (now.isBefore(endsAt)) return const [];

    final events = <TimerEvent>[
      SessionEnded(
        type: _snapshot.type,
        startedAt: _snapshot.startedAt ?? endsAt,
        endedAt: endsAt,
        activeSeconds: _snapshot.durationSeconds,
        completed: true,
      ),
    ];
    final next = _advance(countWork: _snapshot.type == SessionType.work);
    _snapshot = next;

    if (allowAutoStart && _config.shouldAutoStart(next.type)) {
      // Anchor the auto-started session at the moment the previous one
      // ended, not at the (possibly later) tick, so no time is lost.
      _snapshot = next.copyWith(
        status: TimerStatus.running,
        startedAt: endsAt,
        endsAt: endsAt.add(Duration(seconds: next.durationSeconds)),
      );
      events.add(SessionStarted(type: next.type, auto: true));
    }
    return events;
  }

  TimerSnapshot _advance({required bool countWork}) {
    final cycle = countWork ? _snapshot.cycleCount + 1 : _snapshot.cycleCount;
    final every = _config.preset.longBreakEvery.clamp(1, 99);
    final nextType = switch (_snapshot.type) {
      SessionType.work =>
        cycle % every == 0 ? SessionType.longBreak : SessionType.shortBreak,
      SessionType.shortBreak || SessionType.longBreak => SessionType.work,
    };
    // Roll the cycle counter over after a long break has been earned.
    final nextCycle = nextType == SessionType.longBreak ? 0 : cycle;
    return TimerSnapshot.idle(
      type: nextType,
      durationSeconds: _durationFor(nextType),
      cycleCount: nextCycle,
    );
  }

  int _durationFor(SessionType type) =>
      _config.preset.durationFor(type).inSeconds;
}
