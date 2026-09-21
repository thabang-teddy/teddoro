import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teddoro/ui/theme/app_theme.dart';

/// The Teddoro mark: a round clock face with bear ears, a friendly bear face
/// in the centre, and clock hands over it. Drawn with vectors so it scales
/// from a 24px empty-state icon to the 1024px app icon.
class TeddyClockLogo extends StatelessWidget {
  const TeddyClockLogo({
    super.key,
    this.size = 120,
    this.furColor = AppTheme.cocoa,
    this.faceColor = AppTheme.cream,
    this.accentColor = AppTheme.honey,
    this.handColor = AppTheme.cocoa,
    this.progress,
  });

  final double size;
  final Color furColor;
  final Color faceColor;
  final Color accentColor;
  final Color handColor;

  /// When set (0..1) the minute hand sweeps with the session instead of
  /// sitting at the resting "ten past ten" pose.
  final double? progress;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Teddoro logo: a teddy bear clock',
    child: CustomPaint(
      size: Size.square(size),
      painter: TeddyClockPainter(
        furColor: furColor,
        faceColor: faceColor,
        accentColor: accentColor,
        handColor: handColor,
        progress: progress,
      ),
    ),
  );
}

class TeddyClockPainter extends CustomPainter {
  const TeddyClockPainter({
    required this.furColor,
    required this.faceColor,
    required this.accentColor,
    required this.handColor,
    this.progress,
  });

  final Color furColor;
  final Color faceColor;
  final Color accentColor;
  final Color handColor;
  final double? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2 + s * 0.04);
    final r = s * 0.36;

    _paintEars(canvas, c, r);
    _paintClockFace(canvas, c, r);
    _paintBearFace(canvas, c, r);
    _paintHands(canvas, c, r);
  }

  void _paintEars(Canvas canvas, Offset c, double r) {
    final fur = Paint()..color = furColor;
    final inner = Paint()..color = accentColor;
    for (final sign in [-1, 1]) {
      final ear = c + Offset(sign * r * 0.78, -r * 0.78);
      canvas.drawCircle(ear, r * 0.30, fur);
      canvas.drawCircle(ear, r * 0.16, inner);
    }
  }

  void _paintClockFace(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r * 1.08, Paint()..color = furColor);
    canvas.drawCircle(c, r * 0.96, Paint()..color = faceColor);

    // Hour ticks at 12, 3, 6, 9.
    final tick = Paint()
      ..color = furColor
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(c + dir * r * 0.86, c + dir * r * 0.74, tick);
    }
  }

  void _paintBearFace(Canvas canvas, Offset c, double r) {
    final fur = Paint()..color = furColor;
    // Muzzle.
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.40),
        width: r * 0.62,
        height: r * 0.46,
      ),
      Paint()..color = accentColor.withValues(alpha: 0.55),
    );
    // Eyes.
    for (final sign in [-1, 1]) {
      canvas.drawCircle(c + Offset(sign * r * 0.28, r * 0.10), r * 0.075, fur);
    }
    // Nose.
    final nose = c + Offset(0, r * 0.31);
    final nosePath = Path()
      ..moveTo(nose.dx - r * 0.13, nose.dy - r * 0.05)
      ..lineTo(nose.dx + r * 0.13, nose.dy - r * 0.05)
      ..lineTo(nose.dx, nose.dy + r * 0.10)
      ..close();
    canvas.drawPath(nosePath, fur);
    // Smile.
    final smile = Paint()
      ..color = furColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.44),
        width: r * 0.30,
        height: r * 0.22,
      ),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      smile,
    );
  }

  void _paintHands(Canvas canvas, Offset c, double r) {
    final hand = Paint()
      ..color = handColor
      ..strokeWidth = r * 0.09
      ..strokeCap = StrokeCap.round;
    // Hour hand rests at 10 o'clock; minute hand sweeps with progress or
    // rests at 2 o'clock.
    const hourAngle = -math.pi / 3;
    final minuteAngle = progress == null
        ? math.pi / 3
        : (progress!.clamp(0.0, 1.0)) * 2 * math.pi;
    canvas.drawLine(c, c + _dir(hourAngle) * r * 0.42, hand);
    canvas.drawLine(c, c + _dir(minuteAngle) * r * 0.62, hand);
    canvas.drawCircle(c, r * 0.09, Paint()..color = accentColor);
  }

  static Offset _dir(double angle) => Offset(math.sin(angle), -math.cos(angle));

  @override
  bool shouldRepaint(TeddyClockPainter old) =>
      old.furColor != furColor ||
      old.faceColor != faceColor ||
      old.accentColor != accentColor ||
      old.handColor != handColor ||
      old.progress != progress;
}
