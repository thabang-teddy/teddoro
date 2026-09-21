import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/models/timer_preset.dart';
import 'package:teddoro/state/settings_controller.dart';

const _minMinutes = 1;
const _maxMinutes = 180;

/// Create or edit a custom preset.
Future<void> showPresetEditorDialog(
  BuildContext context, {
  TimerPreset? existing,
}) => showDialog<void>(
  context: context,
  builder: (_) => _PresetEditor(existing: existing),
);

class _PresetEditor extends StatefulWidget {
  const _PresetEditor({this.existing});

  final TimerPreset? existing;

  @override
  State<_PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends State<_PresetEditor> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _work = TextEditingController(
    text: '${widget.existing?.workMinutes ?? 25}',
  );
  late final _short = TextEditingController(
    text: '${widget.existing?.shortBreakMinutes ?? 5}',
  );
  late final _long = TextEditingController(
    text: '${widget.existing?.longBreakMinutes ?? 15}',
  );
  late final _every = TextEditingController(
    text: '${widget.existing?.longBreakEvery ?? 4}',
  );
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _work, _short, _long, _every]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _minutes(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    if (v == null || v < _minMinutes || v > _maxMinutes) return null;
    return v;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final work = _minutes(_work);
    final short = _minutes(_short);
    final long = _minutes(_long);
    final every = int.tryParse(_every.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Name the preset');
      return;
    }
    if (work == null || short == null || long == null) {
      setState(
        () => _error = 'Durations must be $_minMinutes–$_maxMinutes minutes',
      );
      return;
    }
    if (every == null || every < 1 || every > 12) {
      setState(() => _error = 'Long break cadence must be 1–12');
      return;
    }
    final settings = context.read<SettingsController>();
    final existing = widget.existing;
    if (existing == null) {
      await settings.addCustomPreset(
        name: name,
        work: work,
        shortBreak: short,
        longBreak: long,
        longBreakEvery: every,
      );
    } else {
      await settings.updateCustomPreset(
        existing.copyWith(
          name: name,
          workMinutes: work,
          shortBreakMinutes: short,
          longBreakMinutes: long,
          longBreakEvery: every,
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    await context.read<SettingsController>().deleteCustomPreset(id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Custom preset' : 'Edit preset'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MinutesField(controller: _work, label: 'Work'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MinutesField(controller: _short, label: 'Short'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MinutesField(controller: _long, label: 'Long'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MinutesField(
            controller: _every,
            label: 'Long break every N work sessions',
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      if (widget.existing != null)
        TextButton(onPressed: _delete, child: const Text('Delete')),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

class _MinutesField extends StatelessWidget {
  const _MinutesField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
  );
}
