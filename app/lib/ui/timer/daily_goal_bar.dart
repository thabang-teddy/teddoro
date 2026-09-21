import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/state/session_log_controller.dart';
import 'package:teddoro/state/settings_controller.dart';

/// Today's pomodoros against the daily goal, plus the current streak.
class DailyGoalBar extends StatelessWidget {
  const DailyGoalBar({super.key});

  @override
  Widget build(BuildContext context) {
    final goal = context.select<SettingsController, int>(
      (s) => s.settings.dailyGoal,
    );
    final stats = context.watch<SessionLogController>().stats;
    final now = DateTime.now();
    final today = stats.forDay(now).pomodoros;
    final streak = stats.streaks(dailyGoal: goal, today: now).current;
    final fraction = goal == 0 ? 0.0 : (today / goal).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final reached = goal > 0 && today >= goal;

    return Semantics(
      label:
          'Daily goal: $today of $goal pomodoros'
          '${streak > 0 ? ', $streak day streak' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Today',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (streak > 0) ...[
                Icon(
                  Icons.local_fire_department,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$streak day${streak == 1 ? '' : 's'}',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                '$today / $goal',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: reached ? theme.colorScheme.primary : null,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
