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
  @override
  void initState() {
    super.initState();

    // Display exact poster splash for 2.5 seconds before navigating
    Timer(const Duration(milliseconds: 2500), () {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/illustrations/splash_poster.png'), context);
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
