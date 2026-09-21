// Renders the TeddyClockPainter to PNGs for the launcher-icon generator.
// It's written as a Flutter test so it can use dart:ui offscreen:
//
//   flutter test tool/render_icon_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teddoro/ui/logo/teddy_clock_logo.dart';
import 'package:teddoro/ui/theme/app_theme.dart';

Future<void> _render({
  required String path,
  required double size,
  required double scale,
  Color? background,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (background != null) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size, size),
      Paint()..color = background,
    );
  }
  final inset = size * (1 - scale) / 2;
  canvas.translate(inset, inset);
  const TeddyClockPainter(
    furColor: AppTheme.cocoa,
    faceColor: AppTheme.cream,
    accentColor: AppTheme.honey,
    handColor: AppTheme.cocoa,
  ).paint(canvas, Size.square(size * scale));
  final image = await recorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('render launcher icons', () async {
    Directory('assets/icon').createSync(recursive: true);
    // Full icon on a warm background (iOS + legacy Android).
    await _render(
      path: 'assets/icon/icon.png',
      size: 1024,
      scale: 0.92,
      background: AppTheme.honey,
    );
    // Adaptive foreground: transparent, logo within the safe zone.
    await _render(
      path: 'assets/icon/icon_foreground.png',
      size: 1024,
      scale: 0.62,
    );
    expect(File('assets/icon/icon.png').lengthSync(), greaterThan(1000));
  });
}
