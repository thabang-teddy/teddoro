import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/models/task.dart';
import 'package:teddoro/state/task_controller.dart';

const projectPalette = [
  0xFFE0523F,
  0xFFE8A33D,
  0xFF3E9C6A,
  0xFF3D7BC7,
  0xFF8E6C88,
  0xFFC7573D,
  0xFF2F8F8F,
  0xFF6B5B95,
];

/// Create or rename a project. Returns the saved project or null.
Future<Project?> showProjectEditorDialog(
  BuildContext context, {
  Project? existing,
}) => showDialog<Project>(
  context: context,
  builder: (_) => _ProjectEditor(existing: existing),
);

class _ProjectEditor extends StatefulWidget {
  const _ProjectEditor({this.existing});

  final Project? existing;

  @override
  State<_ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends State<_ProjectEditor> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late int _color = widget.existing?.color ?? projectPalette.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final tasks = context.read<TaskController>();
    final existing = widget.existing;
    final Project saved;
    if (existing == null) {
      saved = await tasks.addProject(name: name, color: _color);
    } else {
      saved = existing.copyWith(name: name, color: _color);
      await tasks.updateProject(saved);
    }
    if (mounted) Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'New project' : 'Edit project'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in projectPalette)
              Semantics(
                button: true,
                selected: c == _color,
                label: 'Colour',
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: c == _color
                          ? Border.all(
                              width: 3,
                              color: Theme.of(context).colorScheme.onSurface,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
