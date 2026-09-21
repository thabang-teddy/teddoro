import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/state/task_controller.dart';
import 'package:teddoro/ui/tasks/task_picker_sheet.dart';

/// Shows which task the timer is counting towards; tap to change.
class ActiveTaskCard extends StatelessWidget {
  const ActiveTaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskController>();
    final task = tasks.activeTask;
    final project = tasks.projectById(task?.projectId);
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showTaskPickerSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                task == null ? Icons.add_task : Icons.push_pin_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task?.title ?? 'Pick a task to focus on',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task != null)
                      Text(
                        [
                          if (project != null) project.name,
                          if (task.ticket.isNotEmpty) task.ticket,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (task != null) ...[
                const SizedBox(width: 12),
                _PomodoroCount(
                  completed: task.completedPomodoros,
                  estimated: task.estimatedPomodoros,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PomodoroCount extends StatelessWidget {
  const _PomodoroCount({required this.completed, required this.estimated});

  final int completed;
  final int estimated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$completed of $estimated pomodoros done',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$completed / $estimated',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
