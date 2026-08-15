import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Auto-navigate after artistic entrance reveal
    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        final authStatus = ref.read(authControllerProvider);
        switch (authStatus) {
          case AuthStatus.unauthenticated:
            context.go('/login');
            break;
          case AuthStatus.authenticatedAdmin:
            context.go('/admin/dashboard');
            break;
          case AuthStatus.profileIncomplete:
            context.go('/profile_setup');
            break;
          case AuthStatus.authenticatedStudent:
            context.go('/home');
            break;
          default:
            context.go('/home');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Cinematic Poster Image
          Image.asset(
            'assets/illustrations/splash_poster.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackArtBackground(),
          )
          .animate()
          .fadeIn(duration: 1200.ms, curve: Curves.easeIn)
          .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1.0, 1.0),
            duration: 2500.ms,
            curve: Curves.easeOutCubic,
          ),

          // Shimmering Golden Particle & Light Overlay
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ArtisticLightRaysPainter(
                  progress: _glowController.value,
                ),
              );
            },
          ),

          // Dark Vignette Gradient for Depth
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.85),
                ],
              ),
            ),
          ),

          // Central Glowing Artistic Hexagon Lens Core
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Pulsing Hexagon Lens Flare Ring
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B00).withOpacity(0.3 + 0.3 * _glowController.value),
                            blurRadius: 35,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF9E00).withOpacity(0.2 + 0.2 * _glowController.value),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Animated Floating Artistic Hints Banner (Bottom Overlay)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Glowing Tagline
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFFF9E00), Color(0xFFFFFFFF)],
                  ).createShader(bounds),
                  child: const Text(
                    'STAY INFORMED. STAY AHEAD.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.5,
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 800.ms, duration: 800.ms)
                .slideY(begin: 0.3, end: 0, duration: 800.ms),

                const SizedBox(height: 24),

                // Progress Indicator Line
                SizedBox(
                  width: size.width * 0.4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      color: Color(0xFFFF6B00),
                      minHeight: 2,
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 1200.ms, duration: 600.ms),

                const SizedBox(height: 16),

                // Sub-footer
                Text(
                  'POWERED BY MLR CIE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                )
                .animate()
                .fadeIn(delay: 1400.ms, duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackArtBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F0B08), Color(0xFF1E0E05), Color(0xFF050302)],
        ),
      ),
    );
  }
}

class _ArtisticLightRaysPainter extends CustomPainter {
  final double progress;

  _ArtisticLightRaysPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.08 + 0.04 * progress)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height * 0.45);

    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5) * (3.1415926535 / 180);
      final end = Offset(
        center.dx + (size.width * 1.2) * (1 + 0.05 * progress) * (angle == 0 ? 1 : (i % 2 == 0 ? 0.9 : 1.1)) * (i % 4 == 0 ? 1 : 0.7),
        center.dy + (size.height * 1.2) * (1 + 0.05 * progress) * (i % 2 == 0 ? 1 : -1),
      );
      canvas.drawLine(center, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArtisticLightRaysPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
