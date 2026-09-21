import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:teddoro/core/clock.dart';
import 'package:teddoro/core/formatting.dart';
import 'package:teddoro/core/ids.dart';
import 'package:teddoro/data/repositories.dart';
import 'package:teddoro/domain/models/session_record.dart';
import 'package:teddoro/domain/models/session_type.dart';
import 'package:teddoro/domain/models/sounds.dart';
import 'package:teddoro/domain/stats/badges.dart';
import 'package:teddoro/domain/timer/timer_engine.dart';
import 'package:teddoro/domain/timer/timer_snapshot.dart';
import 'package:teddoro/services/audio_service.dart';
import 'package:teddoro/services/notification_service.dart';
import 'package:teddoro/services/platform_services.dart';
import 'package:teddoro/state/session_log_controller.dart';
import 'package:teddoro/state/settings_controller.dart';
import 'package:teddoro/state/task_controller.dart';

/// Drives the [TimerEngine] with real time and wires its events to the
/// session log, tasks, audio, notifications, wakelock and widgets.
class TimerController extends ChangeNotifier {
  TimerController({
    required SettingsController settings,
    required this._tasks,
    required this._log,
    required this._repository,
    required this._clock,
    required this._ids,
    required this._audio,
    required this._notifications,
    required this._wakelock,
    required this._widgets,
    required this._blocking,
  }) : _settings = settings,
       _engine = TimerEngine(config: _configFrom(settings)) {
    _settings.addListener(_onSettingsChanged);
  }

  static const _tickInterval = Duration(milliseconds: 250);
  static const _reminderRotation = Duration(seconds: 45);

  final SettingsController _settings;
  final TaskController _tasks;
  final SessionLogController _log;
  final TimerStateRepository _repository;
  final Clock _clock;
  final IdGenerator _ids;
  final AudioService _audio;
  final NotificationService _notifications;
  final WakelockService _wakelock;
  final WidgetBridge _widgets;
  final AppBlockingService _blocking;

  TimerEngine _engine;
  Timer? _ticker;
  final _achievementEvents = StreamController<Achievement>.broadcast();
  int _lastShownSecond = -1;
  (AmbientSound, double)? _ambientPlaying;

  TimerSnapshot get snapshot => _engine.snapshot;
  SessionType get type => snapshot.type;
  bool get isRunning => snapshot.isRunning;
  bool get isPaused => snapshot.isPaused;
  bool get isIdle => snapshot.isIdle;
  int get remainingSeconds => _engine.remainingSeconds(_clock.now());
  double get progress => _engine.progress(_clock.now());
  int get cycleCount => snapshot.cycleCount;
  int get longBreakEvery => _engine.config.preset.longBreakEvery;

  /// Fires once for every badge newly earned. The UI shows a celebration.
  Stream<Achievement> get achievementEarned => _achievementEvents.stream;

  /// Strict mode locks the controls while a session is running.
  bool get controlsLocked => _settings.settings.strictMode && !isIdle;

  /// The focus message with `{time}` substituted.
  String get focusMessage => _settings.settings.focusMessage.replaceAll(
    '{time}',
    formatCountdown(remainingSeconds),
  );

  /// Which break reminder to show right now, rotating every 45 seconds.
  String? get currentBreakReminder {
    final s = _settings.settings;
    if (!type.isBreak || isIdle || !s.breakRemindersEnabled) return null;
    if (s.breakReminders.isEmpty) return null;
    final elapsed = snapshot.durationSeconds - remainingSeconds;
    final index =
        (elapsed ~/ _reminderRotation.inSeconds) % s.breakReminders.length;
    return s.breakReminders[index];
  }

  /// Restore persisted state. A session that ended while the app was dead
  /// is logged, and the timer lands idle on the next session.
  Future<void> restore() async {
    final saved = await _repository.load();
    if (saved != null) {
      _engine = TimerEngine(config: _configFrom(_settings), initial: saved);
    }
    final events = _engine.tick(_clock.now(), allowAutoStart: false);
    await _handleEvents(events);
    await _syncSideEffects();
    _syncTicker();
    notifyListeners();
  }

  Future<void> start() => _apply(() => _engine.start(_clock.now()));

  Future<void> pause() async {
    if (controlsLocked) return;
    await _apply(() => _engine.pause(_clock.now()));
  }

  Future<void> skip() async {
    if (controlsLocked) return;
    await _apply(() => _engine.skip(_clock.now()));
  }

  Future<void> reset() async {
    if (controlsLocked) return;
    await _apply(() => _engine.reset());
  }

  /// Call from the app lifecycle when returning to the foreground.
  Future<void> onResumed() => _apply(() => _engine.tick(_clock.now()));

  Future<void> _apply(List<TimerEvent> Function() action) async {
    final events = action();
    await _handleEvents(events);
    await _syncSideEffects();
    _syncTicker();
    notifyListeners();
  }

  Future<void> _handleEvents(List<TimerEvent> events) async {
    for (final event in events) {
      switch (event) {
        case SessionEnded():
          await _onSessionEnded(event);
        case SessionStarted():
          break;
      }
    }
  }

  Future<void> _onSessionEnded(SessionEnded event) async {
    final task = _tasks.activeTask;
    final record = SessionRecord(
      id: _ids.next(),
      type: event.type,
      startedAt: event.startedAt,
      endedAt: event.endedAt,
      durationSeconds: event.activeSeconds,
      taskId: task?.id,
      projectId: task?.projectId,
      completed: event.completed,
    );
    // Don't log a skip with nothing done in it.
    if (!event.completed && event.activeSeconds < 1) return;
    await _log.add(record);

    if (record.countsAsPomodoro && task != null) {
      await _tasks.incrementCompleted(task.id);
    }
    if (event.completed) {
      final s = _settings.settings;
      unawaited(_audio.playAlarm(s.alarmSound, s.alarmVolume));
      await _checkBadges();
    }
  }

  Future<void> _checkBadges() async {
    final s = _settings.settings;
    final earned = const BadgeEvaluator().earned(
      stats: _log.stats,
      dailyGoal: s.dailyGoal,
      today: _clock.now(),
    );
    final fresh = const BadgeEvaluator().newlyEarned(s.earnedBadges, earned);
    if (fresh.isEmpty) return;
    await _settings.recordBadges(earned);
    for (final badge in fresh) {
      _achievementEvents.add(badge);
    }
  }

  /// Bring audio, notifications, wakelock, widgets and blocking in line with
  /// the current snapshot, then persist it.
  Future<void> _syncSideEffects() async {
    final s = _settings.settings;
    final snap = snapshot;
    await _repository.save(snap);
    await _widgets.publish(snap);

    final running = snap.isRunning;
    await _wakelock.setEnabled(running && s.keepAwake);

    final ambientOn = running && type == SessionType.work;
    await _syncAmbient(ambientOn);

    await _blocking.setBlocking(
      enabled: ambientOn && s.blockingEnabled,
      apps: s.blockedApps,
    );

    final endsAt = snap.endsAt;
    if (running && endsAt != null) {
      await _notifications.showRunning(
        type: type,
        endsAt: endsAt,
        alerts: _alertsFor(snap, endsAt),
      );
    } else if (snap.isPaused) {
      await _notifications.showPaused(type: type, remaining: remainingSeconds);
    } else {
      await _notifications.clearRunning();
    }
  }

  /// Start, retune or stop the ambient loop without restarting it on every
  /// unrelated state change.
  Future<void> _syncAmbient(bool shouldPlay) async {
    final s = _settings.settings;
    final wanted = shouldPlay && s.ambientSound != AmbientSound.none
        ? (s.ambientSound, s.ambientVolume)
        : null;
    if (wanted == _ambientPlaying) return;
    if (wanted == null) {
      await _audio.stopAmbient();
    } else if (_ambientPlaying?.$1 == wanted.$1) {
      await _audio.setAmbientVolume(wanted.$2);
    } else {
      await _audio.startAmbient(wanted.$1, wanted.$2);
    }
    _ambientPlaying = wanted;
  }

  List<ScheduledAlert> _alertsFor(TimerSnapshot snap, DateTime endsAt) {
    final alerts = [
      ScheduledAlert(
        at: endsAt,
        title: '${snap.type.label} finished',
        body: snap.type.isBreak
            ? 'Back to it — a work session is up next.'
            : 'Nice work. Time for a break.',
      ),
    ];
    // With auto-start on, the next session begins without the app being
    // open, so schedule its end alert now too.
    final next = _peekNextType(snap);
    if (_engine.config.shouldAutoStart(next)) {
      final nextEnd = endsAt.add(_engine.config.preset.durationFor(next));
      alerts.add(
        ScheduledAlert(
          at: nextEnd,
          title: '${next.label} finished',
          body: next.isBreak ? 'Back to work.' : 'Time for a break.',
        ),
      );
    }
    return alerts;
  }

  SessionType _peekNextType(TimerSnapshot snap) {
    if (snap.type.isBreak) return SessionType.work;
    final cycle = snap.cycleCount + 1;
    final every = _engine.config.preset.longBreakEvery.clamp(1, 99);
    return cycle % every == 0 ? SessionType.longBreak : SessionType.shortBreak;
  }

  void _syncTicker() {
    if (isRunning) {
      _ticker ??= Timer.periodic(_tickInterval, (_) => _onTick());
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _onTick() {
    final events = _engine.tick(_clock.now());
    if (events.isNotEmpty) {
      unawaited(_apply(() => events));
      return;
    }
    // Only rebuild listeners when the displayed second changes.
    final second = remainingSeconds;
    if (second != _lastShownSecond) {
      _lastShownSecond = second;
      notifyListeners();
    }
  }

  void _onSettingsChanged() {
    _engine.updateConfig(_configFrom(_settings));
    unawaited(_syncAmbient(isRunning && type == SessionType.work));
    notifyListeners();
  }

  static TimerConfig _configFrom(SettingsController settings) {
    final s = settings.settings;
    return TimerConfig(
      preset: s.activePreset,
      autoStartBreaks: s.autoStartBreaks,
      autoStartWork: s.autoStartWork,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _settings.removeListener(_onSettingsChanged);
    _achievementEvents.close();
    super.dispose();
  }
}
