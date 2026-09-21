import 'package:flutter/material.dart';
import 'package:teddoro/domain/stats/stats_calculator.dart';

/// GitHub-style grid: one column per week, one row per weekday, colour
/// intensity by pomodoros that day. Covers the last [weeks] weeks.
class FocusHeatmap extends StatelessWidget {
  const FocusHeatmap({
    super.key,
    required this.countsByDay,
    required this.today,
    this.weeks = 52,
  });

  final Map<DateTime, int> countsByDay;
  final DateTime today;
  final int weeks;

  static const _cell = 12.0;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final track = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.08);
    final end = StatsCalculator.weekStart(today).add(const Duration(days: 6));
    final start = end.subtract(Duration(days: weeks * 7 - 1));
    final max = countsByDay.values.fold(0, (m, v) => v > m ? v : m);
    final totalDays = countsByDay.values.where((v) => v > 0).length;

    return Semantics(
      label: 'Focus heatmap: $totalDays active days in the last $weeks weeks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: SizedBox(
              width: weeks * (_cell + _gap),
              height: 7 * (_cell + _gap),
              child: CustomPaint(
                painter: _HeatmapPainter(
                  start: start,
                  weeks: weeks,
                  counts: countsByDay,
                  color: color,
                  track: track,
                  max: max,
                  today: StatsCalculator.dayOf(today),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 6),
              for (final a in [0.0, 0.3, 0.55, 0.8, 1.0])
                Container(
                  width: _cell,
                  height: _cell,
                  margin: const EdgeInsets.only(right: _gap),
                  decoration: BoxDecoration(
                    color: a == 0 ? track : color.withValues(alpha: a),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const SizedBox(width: 3),
              Text('More', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  const _HeatmapPainter({
    required this.start,
    required this.weeks,
    required this.counts,
    required this.color,
    required this.track,
    required this.max,
    required this.today,
  });

  final DateTime start;
  final int weeks;
  final Map<DateTime, int> counts;
  final Color color;
  final Color track;
  final int max;
  final DateTime today;

  @override
  void paint(Canvas canvas, Size size) {
    const step = FocusHeatmap._cell + FocusHeatmap._gap;
    final paint = Paint();
    for (var w = 0; w < weeks; w++) {
      for (var d = 0; d < 7; d++) {
        final day = start.add(Duration(days: w * 7 + d));
        if (day.isAfter(today)) continue;
        final count = counts[day] ?? 0;
        paint.color = count == 0
            ? track
            : color.withValues(alpha: _alpha(count));
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * step,
            d * step,
            FocusHeatmap._cell,
            FocusHeatmap._cell,
          ),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  double _alpha(int count) {
    if (max <= 0) return 0.3;
    final t = count / max;
    if (t < 0.25) return 0.3;
    if (t < 0.5) return 0.55;
    if (t < 0.75) return 0.8;
    return 1;
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.counts != counts || old.color != color || old.today != today;
}
