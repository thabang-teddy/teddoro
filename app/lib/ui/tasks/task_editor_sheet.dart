import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/models/task.dart';
import 'package:teddoro/state/task_controller.dart';
import 'package:teddoro/ui/tasks/project_editor_dialog.dart';

/// Create or edit a task. Returns the saved task, or null if dismissed.
Future<Task?> showTaskEditorSheet(BuildContext context, {Task? existing}) =>
    showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TaskEditor(existing: existing),
    );

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({this.existing});

  final Task? existing;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _ticket = TextEditingController(text: widget.existing?.ticket);
  late final _tags = TextEditingController(
    text: widget.existing?.tags.join(', '),
  );
  late int _estimate = widget.existing?.estimatedPomodoros ?? 1;
  late String? _projectId = widget.existing?.projectId;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _ticket.dispose();
    _tags.dispose();
    super.dispose();
  }

  List<String> get _parsedTags => _tags.text
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toSet()
      .toList();

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give the task a name');
      return;
    }
    final tasks = context.read<TaskController>();
    final existing = widget.existing;
    final Task saved;
    if (existing == null) {
      saved = await tasks.addTask(
        title: title,
        estimatedPomodoros: _estimate,
        projectId: _projectId,
        tags: _parsedTags,
        ticket: _ticket.text,
      );
    } else {
      saved = existing.copyWith(
        title: title,
        estimatedPomodoros: _estimate,
        projectId: _projectId,
        clearProject: _projectId == null,
        tags: _parsedTags,
        ticket: _ticket.text.trim(),
      );
      await tasks.updateTask(saved);
    }
    if (mounted) Navigator.pop(context, saved);
  }

  Future<void> _newProject() async {
    final project = await showProjectEditorDialog(context);
    if (project != null) setState(() => _projectId = project.id);
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<TaskController>().projects;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'New task' : 'Edit task',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            _EstimateStepper(
              value: _estimate,
              onChanged: (v) => setState(() => _estimate = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _projectId,
              decoration: const InputDecoration(labelText: 'Project'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                for (final p in projects)
                  DropdownMenuItem(
                    value: p.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor: Color(p.color),
                        ),
                        const SizedBox(width: 8),
                        Text(p.name),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _projectId = v),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _newProject,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New project'),
              ),
            ),
            TextField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Tags',
                helperText: 'Comma separated, e.g. writing, deep',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ticket,
              decoration: const InputDecoration(
                labelText: 'Ticket / reference',
                hintText: 'JIRA-123',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: Text(widget.existing == null ? 'Add task' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateStepper extends StatelessWidget {
  const _EstimateStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Text('Estimated pomodoros')),
      IconButton(
        tooltip: 'Fewer',
        onPressed: value > 1 ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove_circle_outline),
      ),
      SizedBox(
        width: 32,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      IconButton(
        tooltip: 'More',
        onPressed: value < 99 ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}
