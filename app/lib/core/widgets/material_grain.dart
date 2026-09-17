import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

class MaterialGrain extends StatelessWidget {
  const MaterialGrain({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: const _MaterialGrainPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MaterialGrainPainter extends CustomPainter {
  const _MaterialGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final light = Paint()
      ..color = Colors.white.withValues(alpha: 0.010)
      ..strokeWidth = 0.7;
    final dark = Paint()
      ..color = Colors.black.withValues(alpha: 0.035)
      ..strokeWidth = 0.8;
    final lightPoints = <Offset>[];
    final darkPoints = <Offset>[];

    for (var i = 0; i < 420; i++) {
      final x = ((i * 73 + (i * i * 17)) % 997) / 997 * size.width;
      final y = ((i * 151 + (i * i * 29)) % 991) / 991 * size.height;
      (i.isEven ? lightPoints : darkPoints).add(Offset(x, y));
    }
    canvas.drawPoints(PointMode.points, lightPoints, light);
    canvas.drawPoints(PointMode.points, darkPoints, dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
