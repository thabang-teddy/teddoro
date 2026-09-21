import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/models/task.dart';
import 'package:teddoro/state/task_controller.dart';
import 'package:teddoro/ui/tasks/task_editor_sheet.dart';

/// One row in the task list: checkbox, title, meta, pomodoro count and a
/// menu for edit / focus / archive / delete.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskController>();
    final project = tasks.projectById(task.projectId);
    final isActive = tasks.activeTaskId == task.id;
    final theme = Theme.of(context);

    final meta = [
      if (project != null) project.name,
      if (task.ticket.isNotEmpty) task.ticket,
      for (final tag in task.tags) '#$tag',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: () => showTaskEditorSheet(context, existing: task),
        leading: Checkbox(
          value: task.isDone,
          onChanged: (_) => tasks.toggleDone(task.id),
          semanticLabel: 'Mark ${task.title} done',
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: meta.isEmpty
            ? null
            : Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (project != null)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Color(project.color),
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              '${task.completedPomodoros}/${task.estimatedPomodoros}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: task.completedPomodoros >= task.estimatedPomodoros
                    ? theme.colorScheme.primary
                    : null,
              ),
            ),
            PopupMenuButton<_Action>(
              tooltip: 'Task options',
              onSelected: (a) => _handle(context, tasks, a),
              itemBuilder: (_) => [
                if (task.isActive)
                  PopupMenuItem(
                    value: _Action.focus,
                    child: Text(isActive ? 'Stop focusing' : 'Focus on this'),
                  ),
                const PopupMenuItem(value: _Action.edit, child: Text('Edit')),
                const PopupMenuItem(
                  value: _Action.archive,
                  child: Text('Archive'),
                ),
                const PopupMenuItem(
                  value: _Action.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handle(
    BuildContext context,
    TaskController tasks,
    _Action action,
  ) async {
    switch (action) {
      case _Action.focus:
        await tasks.setActiveTask(
          tasks.activeTaskId == task.id ? null : task.id,
        );
      case _Action.edit:
        await showTaskEditorSheet(context, existing: task);
      case _Action.archive:
        await tasks.archiveTask(task.id);
      case _Action.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete task?'),
            content: Text(
              '"${task.title}" and its pomodoro count will be removed. '
              'Logged sessions are kept.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok == true) await tasks.deleteTask(task.id);
    }
  }
}

enum _Action { focus, edit, archive, delete }
