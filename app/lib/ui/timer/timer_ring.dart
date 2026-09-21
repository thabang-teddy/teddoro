import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teddoro/core/formatting.dart';

/// Circular countdown: a thick progress arc with the time in the middle.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.remainingSeconds,
    required this.progress,
    required this.label,
    required this.color,
    this.size = 280,
    this.child,
  });

  final int remainingSeconds;
  final double progress;
  final String label;
  final Color color;
  final double size;

  /// Optional content under the time, e.g. the focus message.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = formatCountdown(remainingSeconds);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: '$label, $time remaining',
      liveRegion: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              builder: (context, value, _) => CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  progress: value,
                  color: color,
                  track: color.withValues(alpha: 0.18),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ExcludeSemantics(
                  child: Text(
                    time,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: size * 0.24,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      height: 1,
                    ),
                  ),
                ),
                if (child != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(width: size * 0.62, child: child),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.055;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        base..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
