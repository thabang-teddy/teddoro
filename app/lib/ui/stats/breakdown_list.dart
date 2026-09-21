import 'package:flutter/material.dart';
import 'package:teddoro/core/formatting.dart';
import 'package:teddoro/domain/stats/stats_calculator.dart';

/// Horizontal bars showing where focus time went.
class BreakdownList extends StatelessWidget {
  const BreakdownList({
    super.key,
    required this.entries,
    required this.labelFor,
    required this.colorFor,
    this.maxRows = 8,
  });

  final List<BreakdownEntry> entries;
  final String Function(String? key) labelFor;
  final Color? Function(String? key) colorFor;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Text(
        'No focus time logged for this period yet.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }
    final top = entries.take(maxRows).toList();
    final max = top.first.focusSeconds;
    return Column(
      children: [
        for (final e in top)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              label:
                  '${labelFor(e.key)}: ${formatFocusTime(e.focusSeconds)}, '
                  '${e.pomodoros} pomodoros',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelFor(e.key),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${formatFocusTime(e.focusSeconds)} · ${e.pomodoros}',
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: max == 0 ? 0 : e.focusSeconds / max,
                      minHeight: 8,
                      color: colorFor(e.key) ?? theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
