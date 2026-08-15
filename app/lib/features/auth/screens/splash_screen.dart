import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _scheduleNavigation();
  }

  void _scheduleNavigation() {
    final authStatus = ref.read(authControllerProvider);
    // 4.0 seconds for first install/unauthenticated users; 2.5 seconds for signed-in users reopening the app
    final int durationMs = (authStatus == AuthStatus.unauthenticated) ? 4000 : 2500;

    _navigationTimer?.cancel();
    _navigationTimer = Timer(Duration(milliseconds: durationMs), () {
      if (mounted) {
        final currentAuthStatus = ref.read(authControllerProvider);
        switch (currentAuthStatus) {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/illustrations/splash_poster.png'), context);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/illustrations/splash_poster.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.black),
        ),
      ),
    );
  }
}
