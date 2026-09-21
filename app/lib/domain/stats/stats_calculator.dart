import 'package:teddoro/domain/models/session_record.dart';

/// Summary numbers for a date range.
class PeriodStats {
  const PeriodStats({
    required this.pomodoros,
    required this.focusSeconds,
    required this.breakSeconds,
  });

  final int pomodoros;
  final int focusSeconds;
  final int breakSeconds;

  static const empty = PeriodStats(
    pomodoros: 0,
    focusSeconds: 0,
    breakSeconds: 0,
  );
}

/// Focus time grouped by a key (task id or project id).
class BreakdownEntry {
  const BreakdownEntry({
    required this.key,
    required this.pomodoros,
    required this.focusSeconds,
  });

  /// Null means "no task" / "no project".
  final String? key;
  final int pomodoros;
  final int focusSeconds;
}

class StreakInfo {
  const StreakInfo({required this.current, required this.best});

  final int current;
  final int best;

  static const none = StreakInfo(current: 0, best: 0);
}

/// Pure functions over the session log. All dates are treated in local time
/// and a "day" runs midnight to midnight.
class StatsCalculator {
  const StatsCalculator(this.sessions);

  final List<SessionRecord> sessions;

  static DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  Iterable<SessionRecord> inRange(DateTime start, DateTime endExclusive) =>
      sessions.where(
        (s) => !s.endedAt.isBefore(start) && s.endedAt.isBefore(endExclusive),
      );

  PeriodStats forRange(DateTime start, DateTime endExclusive) =>
      _summarise(inRange(start, endExclusive));

  PeriodStats forDay(DateTime day) {
    final start = dayOf(day);
    return forRange(start, start.add(const Duration(days: 1)));
  }

  /// Monday-to-Sunday week containing [day].
  PeriodStats forWeek(DateTime day) {
    final start = weekStart(day);
    return forRange(start, start.add(const Duration(days: 7)));
  }

  PeriodStats forMonth(DateTime day) {
    final start = DateTime(day.year, day.month);
    return forRange(start, DateTime(day.year, day.month + 1));
  }

  static DateTime weekStart(DateTime day) {
    final d = dayOf(day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  /// Pomodoros completed per day, keyed by midnight-local [DateTime].
  Map<DateTime, int> pomodorosPerDay() {
    final counts = <DateTime, int>{};
    for (final s in sessions.where((s) => s.countsAsPomodoro)) {
      final day = dayOf(s.endedAt);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  /// Consecutive days (ending today or yesterday) that met [dailyGoal].
  StreakInfo streaks({required int dailyGoal, required DateTime today}) {
    if (dailyGoal <= 0) return StreakInfo.none;
    final perDay = pomodorosPerDay();
    final hitDays =
        perDay.entries
            .where((e) => e.value >= dailyGoal)
            .map((e) => e.key)
            .toList()
          ..sort();
    if (hitDays.isEmpty) return StreakInfo.none;

    var best = 1;
    var run = 1;
    for (var i = 1; i < hitDays.length; i++) {
      final gap = hitDays[i].difference(hitDays[i - 1]).inDays;
      run = gap == 1 ? run + 1 : 1;
      if (run > best) best = run;
    }

    final todayKey = dayOf(today);
    final last = hitDays.last;
    final daysSinceLast = todayKey.difference(last).inDays;
    // The streak is alive if the goal was hit today or yesterday.
    final current = daysSinceLast <= 1 ? run : 0;
    return StreakInfo(current: current, best: best);
  }

  List<BreakdownEntry> byTask({DateTime? start, DateTime? endExclusive}) =>
      _breakdown((s) => s.taskId, start, endExclusive);

  List<BreakdownEntry> byProject({DateTime? start, DateTime? endExclusive}) =>
      _breakdown((s) => s.projectId, start, endExclusive);

  int get totalPomodoros => sessions.where((s) => s.countsAsPomodoro).length;

  List<BreakdownEntry> _breakdown(
    String? Function(SessionRecord) keyOf,
    DateTime? start,
    DateTime? endExclusive,
  ) {
    final source = start != null && endExclusive != null
        ? inRange(start, endExclusive)
        : sessions;
    final pomodoros = <String?, int>{};
    final seconds = <String?, int>{};
    for (final s in source.where((s) => s.type.isBreak == false)) {
      final key = keyOf(s);
      seconds[key] = (seconds[key] ?? 0) + s.durationSeconds;
      if (s.completed) pomodoros[key] = (pomodoros[key] ?? 0) + 1;
    }
    final entries =
        seconds.keys
            .map(
              (k) => BreakdownEntry(
                key: k,
                pomodoros: pomodoros[k] ?? 0,
                focusSeconds: seconds[k] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.focusSeconds.compareTo(a.focusSeconds));
    return List.unmodifiable(entries);
  }

  PeriodStats _summarise(Iterable<SessionRecord> source) {
    var pomodoros = 0;
    var focus = 0;
    var rest = 0;
    for (final s in source) {
      if (s.countsAsPomodoro) pomodoros++;
      if (s.type.isBreak) {
        rest += s.durationSeconds;
      } else {
        focus += s.durationSeconds;
      }
    }
    return PeriodStats(
      pomodoros: pomodoros,
      focusSeconds: focus,
      breakSeconds: rest,
    );
  }
}
