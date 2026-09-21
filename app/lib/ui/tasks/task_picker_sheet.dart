import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/models/task.dart';
import 'package:teddoro/state/task_controller.dart';
import 'package:teddoro/ui/tasks/task_editor_sheet.dart';

/// Bottom sheet to choose which task the timer counts towards.
Future<void> showTaskPickerSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _TaskPicker(),
    );

class _TaskPicker extends StatelessWidget {
  const _TaskPicker();

  String _subtitle(TaskController tasks, Task task) {
    final project = tasks.projectById(task.projectId);
    final base =
        '${task.completedPomodoros} / ${task.estimatedPomodoros} pomodoros';
    return project == null ? base : '$base · ${project.name}';
  }

  Future<void> _createAndSelect(
    BuildContext context,
    TaskController tasks,
  ) async {
    final created = await showTaskEditorSheet(context);
    if (created == null || !context.mounted) return;
    await tasks.setActiveTask(created.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskController>();
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'Focus on',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<String?>(
            groupValue: tasks.activeTaskId,
            onChanged: (id) {
              tasks.setActiveTask(id);
              Navigator.pop(context);
            },
            child: Column(
              children: [
                const RadioListTile<String?>(
                  value: null,
                  title: Text('No specific task'),
                ),
                for (final task in tasks.openTasks)
                  RadioListTile<String?>(
                    value: task.id,
                    title: Text(task.title),
                    subtitle: Text(_subtitle(tasks, task)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _createAndSelect(context, tasks),
            icon: const Icon(Icons.add),
            label: const Text('New task'),
          ),
        ],
      ),
    );
  }
}
