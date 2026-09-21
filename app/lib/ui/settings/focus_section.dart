import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/services/platform_services.dart';
import 'package:teddoro/state/settings_controller.dart';
import 'package:teddoro/ui/settings/settings_widgets.dart';

/// Keep-awake, strict mode, focus message and (where the platform supports
/// it) app blocking.
class FocusSection extends StatefulWidget {
  const FocusSection({super.key});

  @override
  State<FocusSection> createState() => _FocusSectionState();
}

class _FocusSectionState extends State<FocusSection> {
  bool _blockingSupported = false;

  @override
  void initState() {
    super.initState();
    context.read<AppBlockingService>().isSupported().then((supported) {
      if (mounted) setState(() => _blockingSupported = supported);
    });
  }

  Future<void> _confirmStrict(SettingsController controller) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turn on strict mode?'),
        content: const Text(
          'While a session is running you will not be able to pause, skip or '
          'reset it. You can still turn strict mode off here between sessions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Turn on'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.update((s) => s.copyWith(strictMode: true));
    }
  }

  Future<void> _pickApps(SettingsController controller) async {
    final blocking = context.read<AppBlockingService>();
    final chosen = await blocking.pickApps(controller.settings.blockedApps);
    await controller.update((s) => s.copyWith(blockedApps: chosen));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final s = controller.settings;

    return SettingsSection(
      title: 'Focus aids',
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.phone_android),
          title: const Text('Keep screen awake'),
          subtitle: const Text('Screen stays on while a timer runs'),
          value: s.keepAwake,
          onChanged: (v) => controller.update((s) => s.copyWith(keepAwake: v)),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.lock_outline),
          title: const Text('Strict mode'),
          subtitle: const Text('No pause, skip or reset mid-session'),
          value: s.strictMode,
          onChanged: (v) => v
              ? _confirmStrict(controller)
              : controller.update((s) => s.copyWith(strictMode: false)),
        ),
        ListTile(
          leading: const Icon(Icons.chat_bubble_outline),
          title: const Text('Focus message'),
          subtitle: Text(s.focusMessage),
          onTap: () async {
            final text = await promptForText(
              context,
              title: 'Focus message',
              initial: s.focusMessage,
              helper: 'Use {time} to show the remaining time',
            );
            if (text != null && text.isNotEmpty) {
              await controller.update((s) => s.copyWith(focusMessage: text));
            }
          },
        ),
        if (_blockingSupported) ...[
          SwitchListTile(
            secondary: const Icon(Icons.block),
            title: const Text('Block apps during work'),
            subtitle: Text(
              s.blockedApps.isEmpty
                  ? 'No apps chosen'
                  : '${s.blockedApps.length} apps blocked',
            ),
            value: s.blockingEnabled,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(blockingEnabled: v)),
          ),
          ListTile(
            leading: const SizedBox(width: 24),
            title: const Text('Choose apps to block'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickApps(controller),
          ),
        ],
      ],
    );
  }
}
