import 'package:flutter/material.dart';

/// Section heading used throughout the settings screen.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Slider with a label; used for volumes.
class VolumeSlider extends StatelessWidget {
  const VolumeSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: Slider(
      value: value,
      onChanged: enabled ? onChanged : null,
      onChangeEnd: onChangeEnd,
      semanticFormatterCallback: (v) => '${(v * 100).round()} percent',
    ),
  );
}

/// A row of selectable colour swatches.
class ColorSwatchRow extends StatelessWidget {
  const ColorSwatchRow({
    super.key,
    required this.label,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final int selected;
  final List<int> options;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        children: [
          for (final c in options)
            Semantics(
              button: true,
              selected: c == selected,
              label: '$label colour option',
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelected(c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: c == selected
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
    ),
  );
}

/// Prompts for a single line of text; returns null on cancel.
Future<String?> promptForText(
  BuildContext context, {
  required String title,
  String? initial,
  String? helper,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: null,
        decoration: InputDecoration(helperText: helper),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

/// Prompts for an integer within [min]..[max]; returns null on cancel/invalid.
Future<int?> promptForNumber(
  BuildContext context, {
  required String title,
  required int initial,
  required int min,
  required int max,
}) async {
  final text = await promptForText(
    context,
    title: title,
    initial: '$initial',
    helper: '$min–$max',
  );
  final value = int.tryParse(text ?? '');
  if (value == null || value < min || value > max) return null;
  return value;
}
