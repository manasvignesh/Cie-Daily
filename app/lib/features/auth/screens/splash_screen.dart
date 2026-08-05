import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.blur_on_rounded, // Placeholder logo icon
              size: 80,
              color: Colors.white,
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .fadeIn(),
            const SizedBox(height: 24),
            const Text(
              'CIE Connect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            )
            .animate()
            .slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOut)
            .fadeIn(),
          ],
        ),
      ),
    );
  }
}
