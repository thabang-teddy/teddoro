import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/models/timer_preset.dart';
import 'package:teddoro/state/settings_controller.dart';
import 'package:teddoro/state/timer_controller.dart';
import 'package:teddoro/ui/settings/preset_editor_dialog.dart';

/// One-tap switching between timer presets, plus create/edit/delete for
/// custom ones.
Future<void> showPresetPickerSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _PresetPicker(),
    );

class _PresetPicker extends StatelessWidget {
  const _PresetPicker();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final running = context.select<TimerController, bool>((t) => !t.isIdle);
    final s = settings.settings;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'Timer presets',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (running)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'The current session keeps its length; the new preset applies from the next one.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: s.activePresetId,
            onChanged: (id) {
              if (id != null) settings.selectPreset(id);
            },
            child: Column(
              children: [
                for (final p in s.allPresets)
                  RadioListTile<String>(
                    value: p.id,
                    title: Text(p.name),
                    subtitle: Text(
                      '${p.summary} min · long break every ${p.longBreakEvery}',
                    ),
                    secondary: p.isBuiltIn
                        ? null
                        : IconButton(
                            tooltip: 'Edit preset',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                showPresetEditorDialog(context, existing: p),
                          ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showPresetEditorDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Custom preset'),
          ),
        ],
      ),
    );
  }
}

/// Small helper so other screens can describe the active preset.
extension PresetDescription on TimerPreset {
  String get longDescription => '$name · $summary min';
}
