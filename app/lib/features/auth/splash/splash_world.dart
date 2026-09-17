import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Local vector landscape: restrained exposure, faceted ridges, one person.
/// Normalized geometry crops with aspect ratio; it never stretches artwork.
void paintSplashWorld(Canvas canvas, Size size, double exposure, Offset point) {
  final unit = math.min(size.width, 600.0);
  final origin = Offset(size.width / 2, size.height * 0.68);
  canvas.save();
  canvas.translate(origin.dx, origin.dy + (1 - exposure) * 5);
  canvas.scale(unit / 400 * (1 + exposure * 0.015));
  final glow = Rect.fromCircle(center: const Offset(0, 0), radius: 200);
  canvas.drawCircle(
      Offset.zero,
      200,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFF6500).withValues(alpha: 0.14 * exposure),
          const Color(0xFFFF6500).withValues(alpha: 0.035 * exposure),
          Colors.transparent,
        ], stops: const [
          0,
          0.5,
          1
        ]).createShader(glow));
  canvas.drawCircle(
      (point - origin) *
          (400 / unit) *
          (1 - Curves.easeOutCubic.transform(exposure)),
      11 + 43 * exposure,
      Paint()
        ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                  const Color(0xFF080808), const Color(0xFFFF6500), exposure)!,
              Color.lerp(
                  const Color(0xFF080808), const Color(0xFF823000), exposure)!
            ]).createShader(const Rect.fromLTWH(-54, -54, 108, 108)));
  for (var layer = 0; layer < 3; layer++) {
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i <= 80; i++) {
      final x = -400.0 + i * 10;
      final valley =
          48 - math.pow((x.abs() / 200).clamp(0, 2), 0.85) * (100 - layer * 15);
      final seed = math.sin(i * 12.9898 + layer * 78.233) * 43758.5453;
      final rough = (seed - seed.floor() - 0.5) * (20 + layer * 4);
      points.add(Offset(x, valley + rough + layer * 24));
    }
    path.moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final edge = Path.from(path);
    path
      ..lineTo(400, 900)
      ..lineTo(-400, 900)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
              const Color(0xFF080808),
              [
                const Color(0xFF1A1715),
                const Color(0xFF100F0E),
                const Color(0xFF080808)
              ][layer],
              exposure)!);
    canvas.drawPath(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65
          ..color = const Color(0xFFAC7048)
              .withValues(alpha: exposure * (0.20 - layer * 0.05)));
    // Fine angular rock faces catch a trace of the sun, with no texture asset.
    final facet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0xFFAE784D).withValues(alpha: exposure * 0.075);
    for (var i = 1; i < points.length - 1; i += 2) {
      final p = points[i];
      canvas.drawPath(
          Path()
            ..moveTo(p.dx, p.dy + 1)
            ..lineTo(p.dx + 4, p.dy + 12 + i % 9)
            ..lineTo(points[i + 1].dx, points[i + 1].dy + 5),
          facet);
    }
  }
  // Tiny human scale against the sun, placed on the near ridge.
  final human = Paint()
    ..color = const Color(0xFF050505).withValues(alpha: exposure);
  canvas.drawCircle(const Offset(0, 59), 3, human);
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, 63, 8, 12), const Radius.circular(2)),
      human);
  human
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(const Offset(-2, 73), const Offset(-3, 83), human);
  canvas.drawLine(const Offset(2, 73), const Offset(3, 83), human);
  canvas.restore();
}
