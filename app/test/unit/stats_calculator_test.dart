import 'package:flutter_test/flutter_test.dart';
import 'package:teddoro/domain/models/session_record.dart';
import 'package:teddoro/domain/models/session_type.dart';
import 'package:teddoro/domain/stats/badges.dart';
import 'package:teddoro/domain/stats/stats_calculator.dart';

void main() {
  var counter = 0;
  SessionRecord work(DateTime endedAt, {bool completed = true, String? task}) {
    counter++;
    return SessionRecord(
      id: 's$counter',
      type: SessionType.work,
      startedAt: endedAt.subtract(const Duration(minutes: 25)),
      endedAt: endedAt,
      durationSeconds: 25 * 60,
      completed: completed,
      taskId: task,
      projectId: task == null ? null : 'proj-$task',
    );
  }

  SessionRecord rest(DateTime endedAt) {
    counter++;
    return SessionRecord(
      id: 's$counter',
      type: SessionType.shortBreak,
      startedAt: endedAt.subtract(const Duration(minutes: 5)),
      endedAt: endedAt,
      durationSeconds: 5 * 60,
    );
  }

  final monday = DateTime(2026, 9, 21, 10); // a Monday
  List<SessionRecord> dayWith(DateTime day, int pomodoros) => [
    for (var i = 0; i < pomodoros; i++)
      work(DateTime(day.year, day.month, day.day, 9 + i)),
  ];

  group('period summaries', () {
    test('counts only completed work sessions as pomodoros', () {
      final stats = StatsCalculator([
        work(monday),
        work(monday.add(const Duration(hours: 1)), completed: false),
        rest(monday.add(const Duration(hours: 2))),
      ]);
      final day = stats.forDay(monday);
      expect(day.pomodoros, 1);
      expect(day.focusSeconds, 50 * 60, reason: 'skipped time still counts');
      expect(day.breakSeconds, 5 * 60);
    });

    test('week runs Monday to Sunday', () {
      final sunday = monday.add(const Duration(days: 6));
      final nextMonday = monday.add(const Duration(days: 7));
      final stats = StatsCalculator([
        work(monday),
        work(sunday),
        work(nextMonday),
      ]);
      expect(stats.forWeek(monday).pomodoros, 2);
      expect(stats.forWeek(nextMonday).pomodoros, 1);
    });

    test('month groups by calendar month', () {
      final stats = StatsCalculator([
        work(DateTime(2026, 9, 1, 8)),
        work(DateTime(2026, 9, 30, 23)),
        work(DateTime(2026, 10, 1, 0, 30)),
      ]);
      expect(stats.forMonth(DateTime(2026, 9, 15)).pomodoros, 2);
    });
  });

  group('streaks', () {
    test('counts consecutive goal days ending today', () {
      final sessions = [
        ...dayWith(monday.subtract(const Duration(days: 2)), 2),
        ...dayWith(monday.subtract(const Duration(days: 1)), 2),
        ...dayWith(monday, 2),
      ];
      final streak = StatsCalculator(sessions)
          .streaks(dailyGoal: 2, today: monday);
      expect(streak.current, 3);
      expect(streak.best, 3);
    });

    test(
      'a streak survives if yesterday hit the goal but today has not yet',
      () {
        final sessions = dayWith(monday.subtract(const Duration(days: 1)), 2);
        final streak = StatsCalculator(sessions)
            .streaks(dailyGoal: 2, today: monday);
        expect(streak.current, 1);
      },
    );

    test('a missed day breaks the current streak but keeps the best', () {
      final sessions = [
        ...dayWith(monday.subtract(const Duration(days: 5)), 3),
        ...dayWith(monday.subtract(const Duration(days: 4)), 3),
        ...dayWith(monday, 3),
      ];
      final streak = StatsCalculator(sessions)
          .streaks(dailyGoal: 3, today: monday);
      expect(streak.current, 1);
      expect(streak.best, 2);
    });

    test('days below the goal do not count', () {
      final sessions = dayWith(monday, 1);
      final streak = StatsCalculator(sessions)
          .streaks(dailyGoal: 2, today: monday);
      expect(streak.current, 0);
      expect(streak.best, 0);
    });
  });

  group('breakdown and heatmap', () {
    test('groups focus time by task, most time first', () {
      final stats = StatsCalculator([
        work(monday, task: 'a'),
        work(monday.add(const Duration(hours: 1)), task: 'b'),
        work(monday.add(const Duration(hours: 2)), task: 'b'),
        work(monday.add(const Duration(hours: 3))),
      ]);
      final byTask = stats.byTask();
      expect(byTask.first.key, 'b');
      expect(byTask.first.pomodoros, 2);
      expect(byTask.map((e) => e.key), containsAll(['a', 'b', null]));
      expect(stats.byProject().first.key, 'proj-b');
    });

    test('heatmap counts pomodoros per local day', () {
      final stats = StatsCalculator([
        ...dayWith(monday, 3),
        ...dayWith(monday.add(const Duration(days: 1)), 1),
      ]);
      final map = stats.pomodorosPerDay();
      expect(map[DateTime(2026, 9, 21)], 3);
      expect(map[DateTime(2026, 9, 22)], 1);
      expect(map.length, 2);
    });
  });

  group('badges', () {
    test('awards the goal badge and pomodoro milestones', () {
      final stats = StatsCalculator(dayWith(monday, 10));
      final earned = const BadgeEvaluator().earned(
        stats: stats,
        dailyGoal: 8,
        today: monday,
      );
      expect(
        earned,
        containsAll([Achievement.goalHit.id, Achievement.pomodoros10.id]),
      );
      expect(earned, isNot(contains(Achievement.streak7.id)));
    });

    test('reports only newly earned badges', () {
      const evaluator = BadgeEvaluator();
      final fresh = evaluator.newlyEarned(
        {Achievement.goalHit.id},
        {Achievement.goalHit.id, Achievement.pomodoros10.id},
      );
      expect(fresh.map((b) => b.id), [Achievement.pomodoros10.id]);
    });
  });
}
