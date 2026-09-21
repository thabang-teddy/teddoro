import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/models/task.dart';
import 'package:teddoro/state/task_controller.dart';
import 'package:teddoro/ui/common/empty_state.dart';
import 'package:teddoro/ui/tasks/project_editor_dialog.dart';
import 'package:teddoro/ui/tasks/task_editor_sheet.dart';
import 'package:teddoro/ui/tasks/task_tile.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String? _projectFilter;
  String? _tagFilter;
  bool _showDone = false;

  bool _matches(Task t) =>
      (_projectFilter == null || t.projectId == _projectFilter) &&
      (_tagFilter == null || t.tags.contains(_tagFilter));

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskController>();
    final open = tasks.openTasks.where(_matches).toList();
    final done = tasks.doneTasks.where(_matches).toList();
    final filtering = _projectFilter != null || _tagFilter != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tasks',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Manage projects',
            onPressed: () => _showProjects(context),
            icon: const Icon(Icons.folder_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskEditorSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Task'),
      ),
      body: Column(
        children: [
          _FilterBar(
            projectFilter: _projectFilter,
            tagFilter: _tagFilter,
            showDone: _showDone,
            onProject: (id) => setState(() => _projectFilter = id),
            onTag: (tag) => setState(() => _tagFilter = tag),
            onShowDone: (v) => setState(() => _showDone = v),
          ),
          Expanded(
            child: open.isEmpty && (!_showDone || done.isEmpty)
                ? EmptyState(
                    title: filtering ? 'Nothing matches' : 'No tasks yet',
                    message: filtering ? 'Try clearing the filters.' : 'Add something to work on and estimate how many pomodoros it needs.',
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    buildDefaultDragHandles: !filtering,
                    onReorderItem: filtering
                        ? (_, _) {}
                        : (a, b) => tasks.reorderOpenTasks(a, b),
                    itemCount: open.length + (_showDone ? done.length + 1 : 0),
                    itemBuilder: (context, i) {
                      if (i < open.length) {
                        return TaskTile(
                          key: ValueKey(open[i].id),
                          task: open[i],
                        );
                      }
                      if (i == open.length) {
                        return Padding(
                          key: const ValueKey('done-header'),
                          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                          child: Text(
                            'Done',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        );
                      }
                      final t = done[i - open.length - 1];
                      return TaskTile(key: ValueKey(t.id), task: t);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProjects(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const _ProjectManager(),
      );
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.projectFilter,
    required this.tagFilter,
    required this.showDone,
    required this.onProject,
    required this.onTag,
    required this.onShowDone,
  });

  final String? projectFilter;
  final String? tagFilter;
  final bool showDone;
  final ValueChanged<String?> onProject;
  final ValueChanged<String?> onTag;
  final ValueChanged<bool> onShowDone;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskController>();
    final tags = tasks.allTags.toList()..sort();
    if (tasks.projects.isEmpty && tags.isEmpty && tasks.doneTasks.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final p in tasks.projects) ...[
            FilterChip(
              avatar: CircleAvatar(backgroundColor: Color(p.color), radius: 6),
              label: Text(p.name),
              selected: projectFilter == p.id,
              onSelected: (v) => onProject(v ? p.id : null),
            ),
            const SizedBox(width: 8),
          ],
          for (final tag in tags) ...[
            FilterChip(
              label: Text('#$tag'),
              selected: tagFilter == tag,
              onSelected: (v) => onTag(v ? tag : null),
            ),
            const SizedBox(width: 8),
          ],
          if (tasks.doneTasks.isNotEmpty)
            FilterChip(
              label: const Text('Show done'),
              selected: showDone,
              onSelected: onShowDone,
            ),
        ],
      ),
    );
  }
}

class _ProjectManager extends StatelessWidget {
  const _ProjectManager();

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskController>();
    final theme = Theme.of(context);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          'Projects',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (tasks.projects.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Projects group your tasks and show up in stats.'),
          ),
        for (final p in tasks.projects)
          ListTile(
            leading: CircleAvatar(backgroundColor: Color(p.color), radius: 10),
            title: Text(p.name),
            trailing: IconButton(
              tooltip: 'Delete project',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => tasks.deleteProject(p.id),
            ),
            onTap: () => showProjectEditorDialog(context, existing: p),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => showProjectEditorDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('New project'),
        ),
      ],
    );
  }
}
