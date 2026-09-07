import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

const _splashBackground = Color(0xFFF6F6F4);
const _brandInk = Color(0xFF121212);
const _brandOrange = Color(0xFFFF641E);
const _splashOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: _splashBackground,
  systemNavigationBarIconBrightness: Brightness.dark,
);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _brandController;
  late final AnimationController _exitController;
  ProviderSubscription<AuthStatus>? _authSubscription;
  late AuthStatus _authStatus;
  bool _animationStarted = false;
  bool _brandFinished = false;
  bool _exitStarted = false;

  @override
  void initState() {
    super.initState();
    _authStatus = ref.read(authControllerProvider);
    _authSubscription = ref.listenManual<AuthStatus>(
      authControllerProvider,
      (_, next) {
        if (!mounted) return;
        setState(() => _authStatus = next);
        _beginExitIfReady();
      },
    );
    _brandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2650),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _brandFinished = true;
          _beginExitIfReady();
        }
      });
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _navigateToDestination();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationStarted) return;
    _animationStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _brandController.duration = const Duration(milliseconds: 300);
      _exitController.duration = const Duration(milliseconds: 180);
    }
    _brandController.forward();
  }

  String? get _destination => switch (_authStatus) {
        AuthStatus.unauthenticated => '/login',
        AuthStatus.authenticatedAdmin => '/admin/dashboard',
        AuthStatus.profileIncomplete => '/profile_setup',
        AuthStatus.authenticatedStudent => '/home',
        AuthStatus.initial || AuthStatus.error => null,
      };

  void _beginExitIfReady() {
    if (!mounted || !_brandFinished || _exitStarted || _destination == null) {
      return;
    }
    _exitStarted = true;
    _exitController.forward();
  }

  void _navigateToDestination() {
    final route = _destination;
    if (!mounted || route == null) return;
    context.go(route);
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _brandController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_brandFinished && _authStatus == AuthStatus.error) {
      return _StartupError(
        onRetry: () =>
            ref.read(authControllerProvider.notifier).retryInitialization(),
      );
    }

    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _splashOverlayStyle,
      child: Scaffold(
        backgroundColor: _splashBackground,
        body: ColoredBox(
          color: _splashBackground,
          child: SafeArea(
            child: Center(
              child: Semantics(
                label: 'CIE Daily. Fresh ideas for curious minds.',
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation:
                          Listenable.merge([_brandController, _exitController]),
                      builder: (context, _) {
                        final exit = Curves.easeInOutCubic
                            .transform(_exitController.value);
                        final brandProgress =
                            reducedMotion ? 1.0 : _brandController.value;
                        final entranceOpacity = reducedMotion
                            ? Curves.easeOutCubic
                                .transform(_brandController.value)
                            : 1.0;
                        final tilt = reducedMotion
                            ? 0.0
                            : _playfulTilt(_brandController.value);
                        return Opacity(
                          opacity: entranceOpacity * (1 - exit),
                          child: Transform.scale(
                            scale: 1 - (.06 * exit),
                            child: Transform.rotate(
                              angle: tilt,
                              child: SizedBox(
                                width: math.min(
                                    MediaQuery.sizeOf(context).width * .88,
                                    360),
                                height: 500,
                                child: CustomPaint(
                                  painter: _CieDailyBrandPainter(brandProgress),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _playfulTilt(double progress) {
    final t = _segment(progress, .885, .985, Curves.easeInOutCubic);
    return math.sin(t * math.pi) * .045;
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _splashOverlayStyle,
      child: Scaffold(
        backgroundColor: _splashBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      color: _brandOrange, size: 52),
                  const SizedBox(height: 20),
                  const Text(
                    "CIE Daily couldn't start correctly.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _brandInk,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6E6E73), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CieDailyBrandPainter extends CustomPainter {
  const _CieDailyBrandPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const designSize = Size(320, 470);
    final scale = math.min(
      size.width / designSize.width,
      size.height / designSize.height,
    );
    canvas.translate(
      (size.width - designSize.width * scale) / 2,
      (size.height - designSize.height * scale) / 2,
    );
    canvas.scale(scale);

    final outlineProgress = _segment(progress, .075, .245, Curves.easeOutCubic);
    final foldProgress = _segment(progress, .205, .320, Curves.fastOutSlowIn);
    final leftEye = _segment(progress, .255, .310, Curves.easeOutBack);
    final mouthProgress = _segment(progress, .285, .360, Curves.easeOutCubic);
    final temporaryEye = _segment(progress, .300, .335, Curves.easeOutBack) *
        (1 - _segment(progress, .345, .385));
    final winkProgress = _segment(progress, .345, .415, Curves.easeOutBack);
    final rayOne = _segment(progress, .375, .420, Curves.easeOutBack);
    final rayTwo = _segment(progress, .405, .450, Curves.easeOutBack);
    final rayThree = _segment(progress, .435, .480, Curves.easeOutBack);
    final wordProgress = _segment(progress, .470, .675, Curves.easeOutCubic);
    final underlineProgress =
        _segment(progress, .660, .755, Curves.easeOutCubic);
    final taglineProgress = _segment(progress, .745, .865, Curves.easeOutCubic);
    final spark = math.sin(
      _segment(progress, .885, .965, Curves.easeInOutCubic) * math.pi,
    );
    final rayBounce = math.sin(rayThree * math.pi) * 1.7;

    canvas.save();
    canvas.translate(0, rayBounce);
    _drawFold(canvas, foldProgress);
    _drawMascotOutline(canvas, outlineProgress);
    _drawFace(
      canvas,
      leftEye: leftEye,
      mouthProgress: mouthProgress,
      temporaryEye: temporaryEye,
      winkProgress: winkProgress,
    );
    _drawIdeaRay(canvas, const Offset(132, 68), -.34, rayOne, 26);
    _drawIdeaRay(canvas, const Offset(171, 57), .17, rayTwo, 30);
    _drawIdeaRay(canvas, const Offset(207, 76), .92, rayThree, 28);
    canvas.restore();

    _drawWordmark(canvas, wordProgress);
    _drawUnderline(canvas, underlineProgress);
    _drawTagline(canvas, taglineProgress);
    if (spark > 0) _drawSpark(canvas, const Offset(254, 78), spark);
  }

  Paint _marker(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _drawMascotOutline(Canvas canvas, double amount) {
    final path = Path()
      ..moveTo(75, 93)
      ..cubicTo(111, 88, 208, 96, 246, 109)
      ..cubicTo(251, 111, 249, 120, 247, 128)
      ..cubicTo(241, 167, 231, 220, 216, 264)
      ..lineTo(163, 224)
      ..lineTo(104, 272)
      ..lineTo(79, 258)
      ..cubicTo(79, 210, 74, 141, 75, 93);
    _drawAnimatedPath(canvas, path, _marker(_brandInk, 8.5), amount);

    if (amount > .42) {
      final dryMarker = _marker(const Color(0x5A121212), 1.8);
      canvas.save();
      canvas.translate(.8, -1.1);
      _drawAnimatedPath(canvas, path, dryMarker, amount);
      canvas.restore();
    }
  }

  void _drawFold(Canvas canvas, double amount) {
    if (amount <= 0) return;
    final scale = .12 + (.88 * amount);
    final angle = (1 - amount) * .18;
    canvas.save();
    canvas.translate(235, 216);
    canvas.rotate(angle);
    canvas.scale(scale, scale);
    canvas.translate(-235, -216);
    final fold = Path()
      ..moveTo(246, 128)
      ..lineTo(245, 242)
      ..lineTo(217, 255)
      ..close();
    canvas.drawPath(
      fold,
      Paint()
        ..color = _brandOrange
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(fold, _marker(_brandInk, 5));
    canvas.restore();
  }

  void _drawFace(
    Canvas canvas, {
    required double leftEye,
    required double mouthProgress,
    required double temporaryEye,
    required double winkProgress,
  }) {
    if (leftEye > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(126, 157),
          width: 17 * leftEye,
          height: 25 * leftEye,
        ),
        Paint()..color = _brandInk,
      );
    }
    if (temporaryEye > 0) {
      canvas.drawCircle(
        const Offset(185, 156),
        7 * temporaryEye,
        Paint()..color = _brandInk,
      );
    }
    final mouth = Path()
      ..moveTo(131, 190)
      ..cubicTo(145, 202, 163, 203, 177, 187);
    _drawAnimatedPath(canvas, mouth, _marker(_brandInk, 7), mouthProgress);

    final wink = Path()
      ..moveTo(199, 140)
      ..lineTo(174, 155)
      ..lineTo(198, 169);
    canvas.save();
    canvas.translate(186, 155);
    canvas.scale(
      1 + (.07 * math.sin(winkProgress * math.pi)),
      1 - (.05 * math.sin(winkProgress * math.pi)),
    );
    canvas.translate(-186, -155);
    _drawAnimatedPath(canvas, wink, _marker(_brandInk, 7.5), winkProgress);
    canvas.restore();
  }

  void _drawIdeaRay(
    Canvas canvas,
    Offset center,
    double rotation,
    double amount,
    double length,
  ) {
    if (amount <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation + ((1 - amount) * .14));
    canvas.scale(amount, amount);
    canvas.drawLine(
      Offset(0, -length / 2),
      Offset(0, length / 2),
      _marker(_brandOrange, 9),
    );
    canvas.restore();
  }

  void _drawWordmark(Canvas canvas, double amount) {
    final cie = Path()
      ..moveTo(111, 302)
      ..cubicTo(93, 287, 77, 298, 77, 317)
      ..cubicTo(77, 337, 94, 345, 111, 331)
      ..moveTo(132, 297)
      ..lineTo(131, 340)
      ..moveTo(157, 298)
      ..lineTo(156, 341)
      ..moveTo(158, 299)
      ..lineTo(183, 300)
      ..moveTo(157, 318)
      ..lineTo(177, 319)
      ..moveTo(156, 341)
      ..lineTo(184, 340);

    final daily = Path()
      ..moveTo(58, 354)
      ..lineTo(58, 395)
      ..cubicTo(88, 399, 91, 354, 58, 354)
      ..moveTo(94, 394)
      ..lineTo(109, 352)
      ..lineTo(125, 394)
      ..moveTo(100, 378)
      ..lineTo(120, 379)
      ..moveTo(142, 353)
      ..lineTo(141, 395)
      ..moveTo(164, 353)
      ..lineTo(163, 394)
      ..lineTo(189, 394)
      ..moveTo(198, 353)
      ..lineTo(213, 374)
      ..lineTo(228, 352)
      ..moveTo(213, 374)
      ..lineTo(213, 396);

    final cieAmount = (amount / .48).clamp(0.0, 1.0);
    final dailyAmount = ((amount - .38) / .62).clamp(0.0, 1.0);
    _drawAnimatedPath(canvas, cie, _marker(_brandInk, 7.5), cieAmount);
    _drawAnimatedPath(canvas, daily, _marker(_brandOrange, 8), dailyAmount);
  }

  void _drawUnderline(Canvas canvas, double amount) {
    if (amount <= 0) return;
    final overshoot = amount < .78
        ? (amount / .78) * 1.08
        : 1.08 - (((amount - .78) / .22) * .08);
    final endX = 105 + (123 * overshoot);
    final underline = Path()
      ..moveTo(105, 414)
      ..quadraticBezierTo((105 + endX) / 2, 410, endX, 413);
    canvas.drawPath(underline, _marker(_brandInk, 6));
  }

  void _drawTagline(Canvas canvas, double amount) {
    if (amount <= 0) return;
    final painter = TextPainter(
      text: TextSpan(
        text: 'Fresh ideas for curious minds',
        style: TextStyle(
          color: const Color(0xFF4D4D50).withValues(alpha: amount),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          letterSpacing: .35,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        (320 - painter.width) / 2,
        433 + ((1 - amount) * 7),
      ),
    );
  }

  void _drawSpark(Canvas canvas, Offset center, double amount) {
    final paint = _marker(_brandOrange.withValues(alpha: amount), 3.2);
    final radius = 8 * amount;
    canvas.drawLine(
        center - Offset(radius, 0), center + Offset(radius, 0), paint);
    canvas.drawLine(
        center - Offset(0, radius), center + Offset(0, radius), paint);
  }

  void _drawAnimatedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double amount,
  ) {
    if (amount <= 0) return;
    final metrics = path.computeMetrics().toList();
    final totalLength =
        metrics.fold<double>(0, (sum, metric) => sum + metric.length);
    var remaining = totalLength * amount.clamp(0.0, 1.0);
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final length = math.min(metric.length, remaining);
      canvas.drawPath(metric.extractPath(0, length), paint);
      remaining -= metric.length;
    }
  }

  @override
  bool shouldRepaint(covariant _CieDailyBrandPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

double _segment(
  double value,
  double begin,
  double end, [
  Curve curve = Curves.easeOutCubic,
]) {
  final t = ((value - begin) / (end - begin)).clamp(0.0, 1.0);
  return curve.transform(t);
}
