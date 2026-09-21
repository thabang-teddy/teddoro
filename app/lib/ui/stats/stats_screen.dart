import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:teddoro/core/formatting.dart';
import 'package:teddoro/domain/stats/badges.dart';
import 'package:teddoro/domain/stats/csv_export.dart';
import 'package:teddoro/domain/stats/stats_calculator.dart';
import 'package:teddoro/state/session_log_controller.dart';
import 'package:teddoro/state/settings_controller.dart';
import 'package:teddoro/state/task_controller.dart';
import 'package:teddoro/ui/common/empty_state.dart';
import 'package:teddoro/ui/stats/breakdown_list.dart';
import 'package:teddoro/ui/stats/heatmap.dart';

enum _Period { day, week, month }

enum _Group { task, project }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _Period _period = _Period.day;
  _Group _group = _Group.task;

  (DateTime, DateTime) _range(DateTime now) => switch (_period) {
    _Period.day => (
      StatsCalculator.dayOf(now),
      StatsCalculator.dayOf(now).add(const Duration(days: 1)),
    ),
    _Period.week => (
      StatsCalculator.weekStart(now),
      StatsCalculator.weekStart(now).add(const Duration(days: 7)),
    ),
    _Period.month => (
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final log = context.watch<SessionLogController>();
    final tasks = context.watch<TaskController>();
    final goal = context.select<SettingsController, int>(
      (s) => s.settings.dailyGoal,
    );
    final earned = context.select<SettingsController, Set<String>>(
      (s) => s.settings.earnedBadges,
    );
    final stats = log.stats;
    final now = DateTime.now();
    final (start, end) = _range(now);
    final period = stats.forRange(start, end);
    final streak = stats.streaks(dailyGoal: goal, today: now);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stats',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: log.sessions.isEmpty ? null : () => _export(context),
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: log.sessions.isEmpty
          ? const EmptyState(
              title: 'Nothing to show yet',
              message: 'Finish a pomodoro and your reports, streaks and heatmap will appear here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                SegmentedButton<_Period>(
                  segments: const [
                    ButtonSegment(value: _Period.day, label: Text('Today')),
                    ButtonSegment(value: _Period.week, label: Text('Week')),
                    ButtonSegment(value: _Period.month, label: Text('Month')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) => setState(() => _period = s.first),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Pomodoros',
                        value: '${period.pomodoros}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Focus time',
                        value: formatFocusTime(period.focusSeconds),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Current streak',
                        value: '${streak.current} d',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Best streak',
                        value: '${streak.best} d',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionTitle('Focus days'),
                const SizedBox(height: 12),
                FocusHeatmap(countsByDay: stats.pomodorosPerDay(), today: now),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(child: _SectionTitle('Where time went')),
                    SegmentedButton<_Group>(
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: const [
                        ButtonSegment(value: _Group.task, label: Text('Task')),
                        ButtonSegment(
                          value: _Group.project,
                          label: Text('Project'),
                        ),
                      ],
                      selected: {_group},
                      onSelectionChanged: (s) =>
                          setState(() => _group = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_group == _Group.task)
                  BreakdownList(
                    entries: stats.byTask(start: start, endExclusive: end),
                    labelFor: (id) => tasks.taskById(id)?.title ?? 'No task',
                    colorFor: (id) {
                      final p = tasks.projectById(
                        tasks.taskById(id)?.projectId,
                      );
                      return p == null ? null : Color(p.color);
                    },
                  )
                else
                  BreakdownList(
                    entries: stats.byProject(start: start, endExclusive: end),
                    labelFor: (id) =>
                        tasks.projectById(id)?.name ?? 'No project',
                    colorFor: (id) {
                      final p = tasks.projectById(id);
                      return p == null ? null : Color(p.color);
                    },
                  ),
                const SizedBox(height: 28),
                _SectionTitle('Badges'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in Achievement.all)
                      Tooltip(
                        message: b.description,
                        child: Chip(
                          avatar: Icon(
                            earned.contains(b.id)
                                ? Icons.emoji_events
                                : Icons.lock_outline,
                            size: 18,
                            color: earned.contains(b.id)
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          label: Text(b.title),
                          backgroundColor: earned.contains(b.id)
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final log = context.read<SessionLogController>();
    final tasks = context.read<TaskController>();
    final messenger = ScaffoldMessenger.of(context);
    final csv = const CsvExporter().export(
      sessions: log.sessions,
      tasks: tasks.tasks,
      projects: tasks.projects,
    );
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}${Platform.pathSeparator}teddoro-sessions.csv',
      );
      await file.writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Teddoro sessions'),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w800),
  );
}
