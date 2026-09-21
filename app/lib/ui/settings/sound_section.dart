import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/models/sounds.dart';
import 'package:teddoro/services/audio_service.dart';
import 'package:teddoro/state/settings_controller.dart';
import 'package:teddoro/ui/settings/settings_widgets.dart';

/// Alarm and ambient sound settings, with preview.
class SoundSection extends StatelessWidget {
  const SoundSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final audio = context.read<AudioService>();
    final s = controller.settings;

    return SettingsSection(
      title: 'Sounds',
      children: [
        ListTile(
          leading: const Icon(Icons.alarm),
          title: const Text('Alarm'),
          subtitle: Wrap(
            spacing: 8,
            children: [
              for (final sound in AlarmSound.values)
                ChoiceChip(
                  label: Text(sound.label),
                  selected: s.alarmSound == sound,
                  onSelected: (_) async {
                    await controller.update(
                      (s) => s.copyWith(alarmSound: sound),
                    );
                    await audio.playAlarm(sound, s.alarmVolume);
                  },
                ),
            ],
          ),
          trailing: IconButton(
            tooltip: 'Preview alarm',
            icon: const Icon(Icons.play_arrow),
            onPressed: () => audio.playAlarm(s.alarmSound, s.alarmVolume),
          ),
        ),
        VolumeSlider(
          label: 'Alarm volume',
          value: s.alarmVolume,
          onChanged: (v) =>
              controller.update((s) => s.copyWith(alarmVolume: v)),
          onChangeEnd: (v) => audio.playAlarm(s.alarmSound, v),
        ),
        ListTile(
          leading: const Icon(Icons.waves),
          title: const Text('Ambient sound during work'),
          subtitle: Wrap(
            spacing: 8,
            children: [
              for (final sound in AmbientSound.values)
                ChoiceChip(
                  label: Text(sound.label),
                  selected: s.ambientSound == sound,
                  onSelected: (_) =>
                      controller.update((s) => s.copyWith(ambientSound: sound)),
                ),
            ],
          ),
        ),
        VolumeSlider(
          label: 'Ambient volume',
          value: s.ambientVolume,
          enabled: s.ambientSound != AmbientSound.none,
          onChanged: (v) =>
              controller.update((s) => s.copyWith(ambientVolume: v)),
        ),
      ],
    );
  }
}
