import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

const _splashBackground = AppTheme.darkBackground; // Ink Black #080B0C
const _signalOrange = AppTheme.primaryOrange; // Signal Orange #FF6A1A
const _boneWhite = AppTheme.darkPrimaryText; // Bone White #EDE9E0
const _mutedGray = Color(0xFF8E8E93);

const _splashOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: _splashBackground,
  systemNavigationBarIconBrightness: Brightness.light,
);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _totalSplashDuration = Duration(milliseconds: 3400);

  late final AnimationController _animController;
  late final AnimationController _exitController;

  ProviderSubscription<AuthStatus>? _authSubscription;
  late AuthStatus _authStatus;
  bool _animationStarted = false;
  bool _animFinished = false;
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

    _animController = AnimationController(
      vsync: this,
      duration: _totalSplashDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animFinished = true;
          _beginExitIfReady();
        }
      });

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
      _animController.duration = const Duration(milliseconds: 350);
      _exitController.duration = const Duration(milliseconds: 180);
    }
    _animController.forward();
  }

  String? get _destination => switch (_authStatus) {
        AuthStatus.unauthenticated => '/login',
        AuthStatus.authenticatedAdmin => '/admin/dashboard',
        AuthStatus.profileIncomplete => '/profile_setup',
        AuthStatus.authenticatedStudent => '/home',
        AuthStatus.initial || AuthStatus.error => null,
      };

  void _beginExitIfReady() {
    if (!mounted || !_animFinished || _exitStarted || _destination == null) {
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
    _animController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _splashOverlayStyle,
      child: Scaffold(
        backgroundColor: _splashBackground,
        body: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_animController, _exitController]),
            builder: (context, _) {
              final exitVal = _exitController.value;

              // ── PHASE 1: Signal Orange dot appears (0.00 to 0.14 / ~0.5s)
              final dotOpacity = CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.00, 0.12, curve: Curves.easeOut),
              ).value;
              final dotScale = CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.00, 0.14, curve: Curves.easeOutCubic),
              ).value;

              // ── PHASE 2: Execution line travels & stops instantly at dot (0.14 to 0.31 / ~1.1s)
              final lineProgress = CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.14, 0.31, curve: Curves.easeOutCubic),
              ).value;

              // Micro impact pulse on dot when line stops (0.31 to 0.38)
              final impactPulse = CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.31, 0.38, curve: Curves.elasticOut),
              ).value;

              // ── PHASE 3: Wordmark BREAKP & INT resolve around fixed dot (0.31 to 0.57 / ~2.0s)
              final textOpacity = CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.31, 0.57, curve: Curves.easeOutCubic),
              ).value;
              final textSlide = (1.0 - textOpacity) * 14.0;

              // ── PHASE 4: Founder lockup "By MANAS" fades in (0.57 to 0.71 / ~2.5s)
              final lockupOpacity = CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.57, 0.71, curve: Curves.easeOutCubic),
              ).value;
              final lockupTranslateY = (1.0 - lockupOpacity) * 6.0;

              // ── PHASE 5: Tagline "Worth stopping for." plain text (0.71 to 0.85 / ~3.0s)
              final taglineOpacity = CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.71, 0.85, curve: Curves.easeOutCubic),
              ).value;
              final taglineTranslateY = (1.0 - taglineOpacity) * 4.0;

              // ── PHASE 6: Transition into app (0.85 to 1.0 + ExitController / 3.0s - 3.6s)
              // Text elements fade out while the Signal Orange dot remains visible into app launch
              final textExitOpacity = (1.0 - exitVal).clamp(0.0, 1.0);
              final dotExitScale = 1.0 + (exitVal * 0.15);
              final dotExitOpacity = (1.0 - (exitVal * 0.4)).clamp(0.0, 1.0);

              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0), // Slightly higher position for balance
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── MAIN ANIMATION SURFACE: LINE + BREAKP●INT ─────────────────
                      SizedBox(
                        height: 70,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Horizontal Execution Line (Stops instantly at dot)
                            if (lineProgress > 0 && textOpacity < 0.9)
                              Positioned(
                                left: 0,
                                right: 0,
                                child: _LineTravelPainterWidget(
                                  progress: lineProgress,
                                  lineColor: _boneWhite.withValues(
                                      alpha: 0.85 * (1.0 - (textOpacity * 0.8))),
                                ),
                              ),

                            // BREAKP ● INT Brand Lockup
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // BREAKP
                                Transform.translate(
                                  offset: Offset(-textSlide, 0),
                                  child: Opacity(
                                    opacity: textOpacity * textExitOpacity,
                                    child: const Text(
                                      'BREAKP',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: _boneWhite,
                                        letterSpacing: 2.2,
                                        fontFamily: 'Outfit',
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 1),

                                // Signal Orange Breakpoint Dot (Anchor)
                                Transform.scale(
                                  scale: (0.6 + (0.4 * dotScale) + (impactPulse * 0.12)) * dotExitScale,
                                  child: Opacity(
                                    opacity: dotOpacity * dotExitOpacity,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: _signalOrange,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _signalOrange.withValues(
                                                alpha: 0.45 + (0.25 * impactPulse)),
                                            blurRadius: 12 + (8 * impactPulse),
                                            spreadRadius: 1 + (2 * impactPulse),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 1),

                                // INT
                                Transform.translate(
                                  offset: Offset(textSlide, 0),
                                  child: Opacity(
                                    opacity: textOpacity * textExitOpacity,
                                    child: const Text(
                                      'INT',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: _boneWhite,
                                        letterSpacing: 2.2,
                                        fontFamily: 'Outfit',
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ── FOUNDER LOCKUP: By MANAS ──────────────────────────────────
                      Transform.translate(
                        offset: Offset(0, lockupTranslateY),
                        child: Opacity(
                          opacity: lockupOpacity * textExitOpacity,
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'By ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _mutedGray,
                                    letterSpacing: 2.0,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                TextSpan(
                                  text: 'MANAS',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _boneWhite,
                                    letterSpacing: 3.0,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── TAGLINE: Worth stopping for. (Plain Text Only) ────────────
                      Transform.translate(
                        offset: Offset(0, taglineTranslateY),
                        child: Opacity(
                          opacity: taglineOpacity * textExitOpacity,
                          child: const Text(
                            'Worth stopping for.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              color: _mutedGray,
                              letterSpacing: 0.6,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LineTravelPainterWidget extends StatelessWidget {
  final double progress;
  final Color lineColor;

  const _LineTravelPainterWidget({
    required this.progress,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 2),
      painter: _LineTravelPainter(
        progress: progress,
        lineColor: lineColor,
      ),
    );
  }
}

class _LineTravelPainter extends CustomPainter {
  final double progress;
  final Color lineColor;

  _LineTravelPainter({required this.progress, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    // Line travels from left edge of screen and STOPS INSTANTLY at the orange dot center (centerX)
    final startX = (centerX - 180) + ((180) * progress);
    final endX = centerX - 10;

    if (startX < endX) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(endX, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineTravelPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
