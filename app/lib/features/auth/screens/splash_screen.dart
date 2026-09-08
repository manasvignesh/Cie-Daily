import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

const _ink = AppTheme.darkBackground;
const _orange = AppTheme.primaryOrange;
const _warmWhite = AppTheme.darkPrimaryText;
const _muted = Color(0xFF96938D);

const _overlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: _ink,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarDividerColor: _ink,
);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _reveal;
  late final AnimationController _exit;
  ProviderSubscription<AuthStatus>? _authSubscription;
  late AuthStatus _authStatus;
  bool _started = false;
  bool _revealFinished = false;
  bool _exitStarted = false;

  @override
  void initState() {
    super.initState();
    _authStatus = ref.read(authControllerProvider);
    _authSubscription = ref.listenManual<AuthStatus>(
      authControllerProvider,
      (_, next) {
        _authStatus = next;
        _exitWhenReady();
      },
    );
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _revealFinished = true;
          _exitWhenReady();
        }
      });
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _navigate();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.duration = const Duration(milliseconds: 300);
      _exit.duration = const Duration(milliseconds: 150);
    }
    _reveal.forward();
  }

  String? get _destination => switch (_authStatus) {
        AuthStatus.unauthenticated => '/login',
        AuthStatus.authenticatedAdmin => '/admin/dashboard',
        AuthStatus.profileIncomplete => '/profile_setup',
        AuthStatus.authenticatedStudent => '/home',
        AuthStatus.initial || AuthStatus.error => null,
      };

  void _exitWhenReady() {
    if (!mounted || !_revealFinished || _exitStarted || _destination == null) {
      return;
    }
    _exitStarted = true;
    _exit.forward();
  }

  void _navigate() {
    final destination = _destination;
    if (mounted && destination != null) context.go(destination);
  }

  double _phase(double start, double end, Curve curve) {
    final value = ((_reveal.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(value).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _reveal.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        backgroundColor: _ink,
        body: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_reveal, _exit]),
            builder: (context, _) {
              final entrance = _phase(0.00, 0.38, Curves.easeOutBack);
              final auraExpand = _phase(0.15, 0.50, Curves.easeOutCubic);
              final shimmer = _phase(0.32, 0.68, Curves.easeInOutCubic);
              final textFade = _phase(0.46, 0.76, Curves.easeOutCubic);
              final idleBreath = _phase(0.70, 1.00, Curves.easeInOut);
              final exit = Curves.easeInOutCubic.transform(_exit.value);

              final floatY = idleBreath > 0
                  ? math.sin(idleBreath * 2 * math.pi) * 3.0
                  : 0.0;

              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _AtmospherePainter(
                      expand: auraExpand,
                      shimmer: shimmer,
                      idle: idleBreath,
                    ),
                  ),
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, -16 + floatY - exit * 16),
                      child: Opacity(
                        opacity: (1 - exit).clamp(0.0, 1.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scale: (0.75 + entrance * 0.25) * (1 + exit * 0.06),
                              child: Opacity(
                                opacity: entrance.clamp(0.0, 1.0),
                                child: _OriginalLogoCard(shimmerProgress: shimmer),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Transform.translate(
                              offset: Offset(0, (1 - textFade) * 12),
                              child: Opacity(
                                opacity: textFade.clamp(0.0, 1.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: _orange,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _orange.withValues(alpha: 0.7),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'BY MANAS',
                                          style: TextStyle(
                                            color: _muted,
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 3.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: _orange,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _orange.withValues(alpha: 0.7),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Worth stopping for.',
                                      style: TextStyle(
                                        color: _warmWhite,
                                        fontFamily: 'Inter',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (exit > 0)
                    IgnorePointer(
                      child: Opacity(
                        opacity: math.sin(exit * math.pi) * 0.35,
                        child: ColoredBox(
                          color: _orange.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OriginalLogoCard extends StatelessWidget {
  final double shimmerProgress;

  const _OriginalLogoCard({required this.shimmerProgress});

  @override
  Widget build(BuildContext context) {
    const double cardSize = 124.0;
    const double borderRadius = 28.0;

    return Container(
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.32),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset(
                'assets/icons/app_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'app/assets/icons/app_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: _orange,
                    ),
                  ),
                ),
              ),
            ),
            if (shimmerProgress > 0 && shimmerProgress < 1)
              CustomPaint(
                painter: _GleamSweepPainter(progress: shimmerProgress),
              ),
          ],
        ),
      ),
    );
  }
}

class _GleamSweepPainter extends CustomPainter {
  final double progress;

  const _GleamSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double travel = size.width * 2.2;
    final double startX = -size.width * 0.6 + progress * travel;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
      ).createShader(
        Rect.fromLTWH(startX, -size.height * 0.3, size.width * 0.8, size.height * 1.6),
      )
      ..blendMode = BlendMode.srcATop;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _GleamSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AtmospherePainter extends CustomPainter {
  final double expand;
  final double shimmer;
  final double idle;

  const _AtmospherePainter({
    required this.expand,
    required this.shimmer,
    required this.idle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 16);
    final baseRadius = size.width * 0.65;
    final dynamicRadius = baseRadius * (0.8 + expand * 0.2 + math.sin(idle * 2 * math.pi) * 0.03);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _orange.withValues(alpha: 0.18 + expand * 0.06),
          _orange.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: dynamicRadius),
      );

    canvas.drawCircle(center, dynamicRadius, glow);

    if (expand > 0.3) {
      final ringAlpha = ((expand - 0.3) / 0.7).clamp(0.0, 1.0);
      final ringPaint = Paint()
        ..color = _orange.withValues(alpha: ringAlpha * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(center, 92 + expand * 18, ringPaint);

      final outerRingPaint = Paint()
        ..color = Colors.white.withValues(alpha: ringAlpha * 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(center, 138 + expand * 26, outerRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) =>
      oldDelegate.expand != expand ||
      oldDelegate.shimmer != shimmer ||
      oldDelegate.idle != idle;
}
