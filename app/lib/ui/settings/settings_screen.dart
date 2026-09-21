import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/models/app_settings.dart';
import 'package:teddoro/domain/models/session_type.dart';
import 'package:teddoro/state/settings_controller.dart';
import 'package:teddoro/ui/logo/teddy_clock_logo.dart';
import 'package:teddoro/ui/settings/break_reminders_editor.dart';
import 'package:teddoro/ui/settings/focus_section.dart';
import 'package:teddoro/ui/settings/preset_picker_sheet.dart';
import 'package:teddoro/ui/settings/settings_widgets.dart';
import 'package:teddoro/ui/settings/sound_section.dart';

const _modeColorOptions = [
  0xFFE0523F,
  0xFFC7573D,
  0xFFE8A33D,
  0xFF3E9C6A,
  0xFF2F8F8F,
  0xFF3D7BC7,
  0xFF6B5B95,
  0xFF8E6C88,
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final s = controller.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsSection(
            title: 'Timer',
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Preset'),
                subtitle: Text(s.activePreset.longDescription),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showPresetPickerSheet(context),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.play_circle_outline),
                title: const Text('Auto-start breaks'),
                value: s.autoStartBreaks,
                onChanged: (v) =>
                    controller.update((s) => s.copyWith(autoStartBreaks: v)),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.replay_circle_filled_outlined),
                title: const Text('Auto-start work'),
                value: s.autoStartWork,
                onChanged: (v) =>
                    controller.update((s) => s.copyWith(autoStartWork: v)),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Daily goal'),
                subtitle: Text('${s.dailyGoal} pomodoros a day'),
                onTap: () async {
                  final v = await promptForNumber(
                    context,
                    title: 'Daily goal',
                    initial: s.dailyGoal,
                    min: 1,
                    max: 40,
                  );
                  if (v != null) {
                    await controller.update((s) => s.copyWith(dailyGoal: v));
                  }
                },
              ),
            ],
          ),
          const SoundSection(),
          const FocusSection(),
          SettingsSection(
            title: 'Breaks',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.self_improvement),
                title: const Text('Break reminders'),
                subtitle: const Text(
                  'Rotating prompts like "stand up and stretch"',
                ),
                value: s.breakRemindersEnabled,
                onChanged: (v) => controller.update(
                  (s) => s.copyWith(breakRemindersEnabled: v),
                ),
              ),
              ListTile(
                leading: const SizedBox(width: 24),
                title: const Text('Edit reminders'),
                subtitle: Text('${s.breakReminders.length} prompts'),
                trailing: const Icon(Icons.chevron_right),
                enabled: s.breakRemindersEnabled,
                onTap: () => BreakRemindersEditor.open(context),
              ),
            ],
          ),
          SettingsSection(
            title: 'Appearance',
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Theme'),
                trailing: SegmentedButton<ThemePreference>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ThemePreference.system,
                      label: Text('Auto'),
                    ),
                    ButtonSegment(
                      value: ThemePreference.light,
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemePreference.dark,
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {s.theme},
                  onSelectionChanged: (v) =>
                      controller.update((s) => s.copyWith(theme: v.first)),
                ),
              ),
              ColorSwatchRow(
                label: SessionType.work.label,
                selected: s.workColor,
                options: _modeColorOptions,
                onSelected: (c) =>
                    controller.update((s) => s.copyWith(workColor: c)),
              ),
              ColorSwatchRow(
                label: SessionType.shortBreak.label,
                selected: s.shortBreakColor,
                options: _modeColorOptions,
                onSelected: (c) =>
                    controller.update((s) => s.copyWith(shortBreakColor: c)),
              ),
              ColorSwatchRow(
                label: SessionType.longBreak.label,
                selected: s.longBreakColor,
                options: _modeColorOptions,
                onSelected: (c) =>
                    controller.update((s) => s.copyWith(longBreakColor: c)),
              ),
            ],
          ),
          const _About(),
        ],
      ),
    );
  }
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        children: [
          TeddyClockLogo(size: 64, accentColor: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            'Teddoro',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Everything stays on this device.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
