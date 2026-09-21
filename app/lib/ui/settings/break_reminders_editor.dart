import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/models/app_settings.dart';
import 'package:teddoro/state/settings_controller.dart';
import 'package:teddoro/ui/settings/settings_widgets.dart';

/// Edit the rotating "stand up and stretch" prompts shown during breaks.
class BreakRemindersEditor extends StatelessWidget {
  const BreakRemindersEditor({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const BreakRemindersEditor()));

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final reminders = settings.settings.breakReminders;

    Future<void> save(List<String> updated) =>
        settings.update((s) => s.copyWith(breakReminders: updated));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Break reminders'),
        actions: [
          TextButton(
            onPressed: () => save(AppSettings.defaultBreakReminders),
            child: const Text('Reset'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add reminder',
        onPressed: () async {
          final text = await promptForText(context, title: 'New reminder');
          if (text != null && text.isNotEmpty) await save([...reminders, text]);
        },
        child: const Icon(Icons.add),
      ),
      body: reminders.isEmpty
          ? const Center(
              child: Text('No reminders. Add one with the + button.'),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
              itemCount: reminders.length,
              onReorderItem: (oldIndex, newIndex) {
                final list = [...reminders];
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                save(list);
              },
              itemBuilder: (context, i) => ListTile(
                key: ValueKey('$i-${reminders[i]}'),
                title: Text(reminders[i]),
                onTap: () async {
                  final text = await promptForText(
                    context,
                    title: 'Edit reminder',
                    initial: reminders[i],
                  );
                  if (text == null || text.isEmpty) return;
                  await save([
                    for (final (j, r) in reminders.indexed) j == i ? text : r,
                  ]);
                },
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => save([
                    for (final (j, r) in reminders.indexed)
                      if (j != i) r,
                  ]),
                ),
              ),
            ),
    );
  }
}
