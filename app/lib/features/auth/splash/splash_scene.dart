import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'splash_world.dart';

const splashInk = Color(0xFF080808);
const splashOrange = Color(0xFFFF6500);
const splashBone = Color(0xFFF5F1EA);
const _entrance = Cubic(0.16, 1, 0.3, 1);

double splashPhase(double t, double start, double end) =>
    ((t - start) / (end - start)).clamp(0.0, 1.0);

/// One deterministic canvas. No random values allocated per frame, network
/// assets, blur filters, screenshots, or per-particle widgets.
///
/// Cinematic timeline (full mode, ~4.8s story controller):
///   0.00–0.30s  Orange point appears, pulses
///   0.30–1.10s  Energy line stretches from point
///   1.10–1.50s  Fracture — the breaking point
///   1.50–2.20s  BREAKP●INT wordmark constructs from fragments
///   2.20–2.60s  "By MANAS" signature fades in
///   2.60–2.90s  "Worth stopping for." tagline fades in
///   2.90–4.00s  Orange sun / mountain world reveals
///   4.00–4.80s  Hero hold — a moment to breathe
///
///   Then door controller (~1.2s) splits the canvas for handoff.
class SplashScene extends CustomPainter {
  const SplashScene(
      {required this.progress,
      required this.opening,
      required this.full,
      required this.reducedMotion});
  final double progress, opening;
  final bool full, reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * (full ? 4.80 : 0.9);
    if (reducedMotion) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = splashInk.withValues(alpha: 1 - opening));
      _wordmark(canvas, size, 1, progress * (1 - opening), true);
      return;
    }
    final open = const Cubic(0.22, 1, 0.36, 1).transform(opening);
    if (opening == 0) {
      _panel(canvas, size, t);
    } else {
      // Draw the same world on two moving halves; the transparent slit shows
      // the live Navigator child, including its actual loading/data state.
      final travel = (size.width / 2 + 2) * open;
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(side * travel, 0);
        canvas.clipRect(Rect.fromLTWH(
            side < 0 ? 0 : size.width / 2, 0, size.width / 2, size.height));
        _panel(canvas, size, t);
        final seam = Paint()
          ..color = splashOrange.withValues(alpha: (1 - open) * 0.55)
          ..strokeWidth = 0.8;
        canvas.drawLine(Offset(size.width / 2, 0),
            Offset(size.width / 2, size.height), seam);
        canvas.restore();
      }
    }
  }

  void _panel(Canvas canvas, Size size, double t) {
    canvas.drawRect(Offset.zero & size, Paint()..color = splashInk);
    final center = Offset(size.width / 2, size.height * 0.5);
    final reveal = _entrance
        .transform(splashPhase(t, full ? 1.50 : 0.64, full ? 2.20 : 0.90));
    final world = full
        ? Curves.easeInOutCubic.transform(splashPhase(t, 2.90, 4.00))
        : 0.0;
    if (world > 0) {
      paintSplashWorld(
          canvas, size, world, Offset(_layout(size).dotX, size.height * 0.44));
    }
    final snapAt = full ? 1.10 : 0.62;
    final stretch =
        _entrance.transform(splashPhase(t, full ? 0.30 : 0.38, snapAt));
    final snap = splashPhase(t, snapAt, snapAt + (full ? 0.42 : 0.12));
    if (stretch > 0 && snap < 1) {
      final half = math.min(size.width * 0.44, 260.0) * stretch;
      final gap = snap * size.width * 0.18;
      final paint = Paint()
        ..color = splashOrange.withValues(alpha: (1 - snap) * 0.85)
        ..strokeWidth = 1.1;
      canvas.drawLine(
          center - Offset(half + gap, 0), center - Offset(gap, 0), paint);
      canvas.drawLine(
          center + Offset(gap, 0), center + Offset(half + gap, 0), paint);
    }
    if (t >= snapAt && snap < 1) _fracture(canvas, center, snap, full);
    // The original point travels into the actual dot position of the wordmark.
    final layout = _layout(size);
    final dotTarget = Offset(layout.dotX, size.height * 0.44);
    final dotCenter = Offset.lerp(center, dotTarget, reveal)!;
    final appear = _entrance
        .transform(splashPhase(t, full ? 0.08 : 0.20, full ? 0.28 : 0.38));
    final pulse =
        t < 0.45 ? math.sin(splashPhase(t, 0.25, 0.45) * math.pi) * 0.6 : 0.0;
    final radius = (4 + pulse) * (1 - reveal) + layout.font * 0.29 * reveal;
    if (appear > 0) {
      final glowRadius = radius * 3.0;
      canvas.drawCircle(
          dotCenter,
          glowRadius,
          Paint()
            ..shader = RadialGradient(colors: [
              splashOrange.withValues(alpha: 0.13 * appear),
              Colors.transparent,
            ]).createShader(
                Rect.fromCircle(center: dotCenter, radius: glowRadius)));
      canvas.drawCircle(
          dotCenter, radius * appear, Paint()..color = splashOrange);
    }
    if (reveal > 0) _wordmark(canvas, size, reveal, 1, false);
  }

  ({double font, double left, double dotX, double width}) _layout(Size size) {
    final font = math.min(38.0, (size.width - 48) / 7.1);
    final a = _text('BREAKP', font, 1.5);
    final b = _text('INT', font, 1.5);
    final dot = font * 0.58;
    final width = a.width + b.width + dot + font * 0.12 + 4;
    final left = (size.width - width) / 2;
    return (
      font: font,
      left: left,
      dotX: left + a.width + 2 + font * 0.06 + dot / 2,
      width: width
    );
  }

  TextPainter _text(String value, double font, double tracking,
          {double alpha = 1, FontWeight weight = FontWeight.w900}) =>
      TextPainter(
          text: TextSpan(
              text: value,
              style: TextStyle(
                  fontFamily: 'BreakpointSplashOutfit',
                  fontSize: font,
                  fontWeight: weight,
                  letterSpacing: tracking,
                  height: 1,
                  color: splashBone.withValues(alpha: alpha))),
          textDirection: TextDirection.ltr)
        ..layout();

  void _wordmark(
      Canvas canvas, Size size, double reveal, double alpha, bool drawDot) {
    final l = _layout(size);
    final y = size.height * 0.44; // Slightly higher for better balance
    final tracking = 1.5 + (1 - reveal) * 1.3;
    final a = _text('BREAKP', l.font, tracking, alpha: alpha);
    final b = _text('INT', l.font, tracking, alpha: alpha);
    final left = l.left - (1 - reveal) * 16;
    final right =
        l.dotX + l.font * 0.29 + 2 + l.font * 0.06 + (1 - reveal) * 16;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(
        l.left, y - l.font, l.left + (l.dotX - l.left) * reveal, y + l.font));
    a.paint(canvas, Offset(left, y - a.height / 2));
    canvas.restore();
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(l.left + l.width - b.width * reveal,
        y - l.font, l.left + l.width + 3, y + l.font));
    b.paint(canvas, Offset(right, y - b.height / 2));
    canvas.restore();
    if (drawDot) {
      canvas.drawCircle(Offset(l.dotX, y), l.font * 0.29,
          Paint()..color = splashOrange.withValues(alpha: alpha));
    }

    // ── "By MANAS" signature ──────────────────────────────────────────────
    final signature = splashPhase(reveal, 0.70, 1) * alpha;
    if (signature > 0) {
      // "By" in lighter weight, "MANAS" in heavier weight, both same size
      final byPainter = TextPainter(
          text: TextSpan(
              text: 'By ',
              style: TextStyle(
                  fontFamily: 'BreakpointSplashOutfit',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.8,
                  height: 1,
                  color: splashBone.withValues(alpha: signature * 0.55))),
          textDirection: TextDirection.ltr)
        ..layout();
      final manasPainter = TextPainter(
          text: TextSpan(
              text: 'MANAS',
              style: TextStyle(
                  fontFamily: 'BreakpointSplashOutfit',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.8,
                  height: 1,
                  color: splashBone.withValues(alpha: signature * 0.72))),
          textDirection: TextDirection.ltr)
        ..layout();
      final totalWidth = byPainter.width + manasPainter.width;
      final sigY = y + l.font * 0.85 + (1 - signature) * 4;
      byPainter.paint(
          canvas, Offset((size.width - totalWidth) / 2, sigY));
      manasPainter.paint(canvas,
          Offset((size.width - totalWidth) / 2 + byPainter.width, sigY));
    }

    // ── "Worth stopping for." tagline — plain text, no pill ────────────
    if (full) {
      // Use actual time from progress to control tagline independently
      final tagProgress = splashPhase(reveal, 0.85, 1) * alpha;
      if (tagProgress > 0) {
        final tagline = TextPainter(
            text: TextSpan(
                text: 'Worth stopping for.',
                style: TextStyle(
                    fontFamily: 'BreakpointSplashOutfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.8,
                    height: 1,
                    color: splashBone.withValues(alpha: tagProgress * 0.45))),
            textDirection: TextDirection.ltr)
          ..layout();
        tagline.paint(
            canvas,
            Offset((size.width - tagline.width) / 2,
                y + l.font * 0.85 + 20 + (1 - tagProgress) * 6));
      }
    }
  }

  void _fracture(Canvas canvas, Offset center, double p, bool particles) {
    final fade = (1 - p) * (1 - p);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1;
    final count = particles ? 14 : 6;
    for (var i = 0; i < count; i++) {
      final angle = i * 2.39996;
      final distance = (12 + i % 5 * 9) * Curves.easeOutCubic.transform(p);
      final direction = Offset(math.cos(angle), math.sin(angle));
      paint.color = (i % 3 == 0 ? splashBone : splashOrange)
          .withValues(alpha: fade * 0.9);
      final at = center + direction * distance;
      canvas.drawLine(at, at + direction * (1 + (i % 3)), paint);
    }
    final crack = Path()
      ..moveTo(center.dx, center.dy - 26 * (1 - p))
      ..lineTo(center.dx - 1.5, center.dy - 5)
      ..lineTo(center.dx + 1, center.dy + 3)
      ..lineTo(center.dx, center.dy + 23 * (1 - p));
    canvas.drawPath(
        crack,
        paint
          ..color = splashBone.withValues(alpha: fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant SplashScene old) =>
      progress != old.progress ||
      opening != old.opening ||
      full != old.full ||
      reducedMotion != old.reducedMotion;
}
