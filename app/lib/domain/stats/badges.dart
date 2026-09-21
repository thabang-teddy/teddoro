import 'package:teddoro/domain/stats/stats_calculator.dart';

/// An achievement the user can earn.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  static const goalHit = Achievement(
    id: 'goal_hit',
    title: 'Goal getter',
    description: 'Hit your daily goal for the first time.',
  );
  static const streak7 = Achievement(
    id: 'streak_7',
    title: 'One week strong',
    description: 'Hit your daily goal seven days in a row.',
  );
  static const streak30 = Achievement(
    id: 'streak_30',
    title: 'Unstoppable',
    description: 'Thirty-day streak. Seriously impressive.',
  );
  static const pomodoros10 = Achievement(
    id: 'pomodoros_10',
    title: 'Warming up',
    description: 'Completed 10 pomodoros.',
  );
  static const pomodoros100 = Achievement(
    id: 'pomodoros_100',
    title: 'Century',
    description: 'Completed 100 pomodoros.',
  );
  static const pomodoros500 = Achievement(
    id: 'pomodoros_500',
    title: 'Bear of focus',
    description: 'Completed 500 pomodoros.',
  );

  static const all = [
    goalHit,
    streak7,
    streak30,
    pomodoros10,
    pomodoros100,
    pomodoros500,
  ];

  static Achievement? byId(String id) {
    for (final b in all) {
      if (b.id == id) return b;
    }
    return null;
  }
}

/// Works out which badges the current stats qualify for.
class BadgeEvaluator {
  const BadgeEvaluator();

  Set<String> earned({
    required StatsCalculator stats,
    required int dailyGoal,
    required DateTime today,
  }) {
    final streak = stats.streaks(dailyGoal: dailyGoal, today: today);
    final total = stats.totalPomodoros;
    final todayCount = stats.forDay(today).pomodoros;
    final everHitGoal =
        streak.best > 0 || (dailyGoal > 0 && todayCount >= dailyGoal);

    return {
      if (everHitGoal) Achievement.goalHit.id,
      if (streak.best >= 7) Achievement.streak7.id,
      if (streak.best >= 30) Achievement.streak30.id,
      if (total >= 10) Achievement.pomodoros10.id,
      if (total >= 100) Achievement.pomodoros100.id,
      if (total >= 500) Achievement.pomodoros500.id,
    };
  }

  /// Badges in [now] that were not in [before], in display order.
  List<Achievement> newlyEarned(Set<String> before, Set<String> now) =>
      Achievement.all
          .where((b) => now.contains(b.id) && !before.contains(b.id))
          .toList();
}
