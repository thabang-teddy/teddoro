import 'package:flutter_test/flutter_test.dart';
import 'package:teddoro/domain/models/session_type.dart';
import 'package:teddoro/domain/models/timer_preset.dart';
import 'package:teddoro/domain/timer/timer_engine.dart';
import 'package:teddoro/domain/timer/timer_snapshot.dart';

void main() {
  final t0 = DateTime(2026, 9, 21, 9);
  const preset = TimerPreset(
    id: 'p',
    name: 'Test',
    workMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    longBreakEvery: 4,
  );

  TimerEngine engine({bool autoBreaks = false, bool autoWork = false}) =>
      TimerEngine(
        config: TimerConfig(
          preset: preset,
          autoStartBreaks: autoBreaks,
          autoStartWork: autoWork,
        ),
      );

  group('start / pause / resume', () {
    test('starts idle on a full-length work session', () {
      final e = engine();
      expect(e.snapshot.status, TimerStatus.idle);
      expect(e.snapshot.type, SessionType.work);
      expect(e.remainingSeconds(t0), 25 * 60);
    });

    test('start sets an absolute end time', () {
      final e = engine();
      final events = e.start(t0);
      expect(events.single, isA<SessionStarted>());
      expect(e.snapshot.endsAt, t0.add(const Duration(minutes: 25)));
      expect(e.remainingSeconds(t0.add(const Duration(minutes: 10))), 15 * 60);
    });

    test('pause freezes remaining time and resume continues from it', () {
      final e = engine()..start(t0);
      e.pause(t0.add(const Duration(minutes: 10)));
      expect(e.snapshot.isPaused, isTrue);
      // Time passing while paused changes nothing.
      expect(e.remainingSeconds(t0.add(const Duration(hours: 3))), 15 * 60);

      final resumeAt = t0.add(const Duration(hours: 3));
      e.start(resumeAt);
      expect(e.snapshot.endsAt, resumeAt.add(const Duration(minutes: 15)));
    });

    test('remaining time rounds up so it never shows 0 early', () {
      final e = engine()..start(t0);
      final almostDone = t0.add(
        const Duration(minutes: 24, seconds: 59, milliseconds: 500),
      );
      expect(e.remainingSeconds(almostDone), 1);
    });
  });

  group('completion and long-break cadence', () {
    test('work ends into a short break and counts the cycle', () {
      final e = engine()..start(t0);
      final events = e.tick(t0.add(const Duration(minutes: 25)));
      final ended = events.whereType<SessionEnded>().single;
      expect(ended.type, SessionType.work);
      expect(ended.completed, isTrue);
      expect(ended.activeSeconds, 25 * 60);
      expect(e.snapshot.type, SessionType.shortBreak);
      expect(e.snapshot.cycleCount, 1);
      expect(e.snapshot.isIdle, isTrue);
    });

    test('fourth work session is followed by a long break', () {
      final e = engine();
      var now = t0;
      for (var i = 0; i < 3; i++) {
        e.start(now);
        now = now.add(const Duration(minutes: 25));
        e.tick(now);
        expect(e.snapshot.type, SessionType.shortBreak);
        e.start(now);
        now = now.add(const Duration(minutes: 5));
        e.tick(now);
        expect(e.snapshot.type, SessionType.work);
      }
      e.start(now);
      now = now.add(const Duration(minutes: 25));
      e.tick(now);
      expect(e.snapshot.type, SessionType.longBreak);
      expect(e.remainingSeconds(now), 15 * 60);
      expect(e.snapshot.cycleCount, 0, reason: 'cycle rolls over');
    });

    test('tick before the end does nothing', () {
      final e = engine()..start(t0);
      expect(e.tick(t0.add(const Duration(minutes: 24))), isEmpty);
      expect(e.snapshot.isRunning, isTrue);
    });
  });

  group('auto-start', () {
    test('auto-starts the break anchored at the previous end time', () {
      final e = engine(autoBreaks: true)..start(t0);
      final end = t0.add(const Duration(minutes: 25));
      final lateTick = end.add(const Duration(seconds: 7));
      final events = e.tick(lateTick);
      expect(events.whereType<SessionStarted>().single.auto, isTrue);
      expect(e.snapshot.isRunning, isTrue);
      expect(e.snapshot.type, SessionType.shortBreak);
      expect(e.snapshot.endsAt, end.add(const Duration(minutes: 5)));
    });

    test('does not auto-start work when only breaks are enabled', () {
      final e = engine(autoBreaks: true)..start(t0);
      e.tick(t0.add(const Duration(minutes: 25)));
      e.tick(t0.add(const Duration(minutes: 30)));
      expect(e.snapshot.type, SessionType.work);
      expect(e.snapshot.isIdle, isTrue);
    });

    test('allowAutoStart=false lands idle after a restart', () {
      final e = engine(autoBreaks: true)..start(t0);
      e.tick(t0.add(const Duration(hours: 2)), allowAutoStart: false);
      expect(e.snapshot.type, SessionType.shortBreak);
      expect(e.snapshot.isIdle, isTrue);
    });
  });

  group('skip and reset', () {
    test('skip logs a partial session and advances', () {
      final e = engine()..start(t0);
      final events = e.skip(t0.add(const Duration(minutes: 10)));
      final ended = events.whereType<SessionEnded>().single;
      expect(ended.completed, isFalse);
      expect(ended.activeSeconds, 10 * 60);
      expect(e.snapshot.type, SessionType.shortBreak);
      expect(e.snapshot.cycleCount, 1);
    });

    test('skip from idle emits nothing but still advances', () {
      final e = engine();
      expect(e.skip(t0), isEmpty);
      expect(e.snapshot.type, SessionType.shortBreak);
    });

    test('reset returns the current session to full length', () {
      final e = engine()..start(t0);
      e.reset();
      expect(e.snapshot.isIdle, isTrue);
      expect(e.snapshot.type, SessionType.work);
      expect(e.remainingSeconds(t0), 25 * 60);
    });
  });

  group('resume after kill', () {
    test('a snapshot round-trips through JSON and keeps its end time', () {
      final e = engine()..start(t0);
      final json = e.snapshot.toJson();
      final restored = TimerSnapshot.fromJson(json);
      expect(restored.endsAt, e.snapshot.endsAt);
      expect(
        restored.remainingSeconds(t0.add(const Duration(minutes: 5))),
        20 * 60,
      );
    });

    test('restoring an expired snapshot logs it and goes idle', () {
      final running = engine()..start(t0);
      final restored = TimerEngine(
        config: running.config,
        initial: TimerSnapshot.fromJson(running.snapshot.toJson()),
      );
      final events = restored.tick(
        t0.add(const Duration(hours: 1)),
        allowAutoStart: false,
      );
      final ended = events.whereType<SessionEnded>().single;
      expect(ended.endedAt, t0.add(const Duration(minutes: 25)));
      expect(restored.snapshot.isIdle, isTrue);
      expect(restored.snapshot.type, SessionType.shortBreak);
    });
  });

  group('config changes', () {
    test('an idle session picks up a new preset length', () {
      final e = engine();
      e.updateConfig(TimerConfig(preset: TimerPreset.deepWork));
      expect(e.remainingSeconds(t0), 50 * 60);
    });

    test('a running session keeps its original length', () {
      final e = engine()..start(t0);
      e.updateConfig(TimerConfig(preset: TimerPreset.deepWork));
      expect(e.snapshot.durationSeconds, 25 * 60);
    });
  });
}
