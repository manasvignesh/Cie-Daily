import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

/// Auth gate. The cinematic overlay stays above the router during handoff.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authControllerProvider);
    final destination = switch (status) {
      AuthStatus.unauthenticated => '/login',
      AuthStatus.authenticatedAdmin => '/admin/dashboard',
      AuthStatus.profileIncomplete => '/profile_setup',
      AuthStatus.authenticatedStudent => '/home',
      AuthStatus.initial || AuthStatus.error => null,
    };
    if (destination != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted &&
            GoRouterState.of(context).uri.path == '/' &&
            ref.read(authControllerProvider) == status) {
          context.go(destination);
        }
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: status == AuthStatus.error
          ? Center(
              child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('We couldn’t open your account.',
                    style: TextStyle(color: Color(0xFFF5F1EA))),
                const SizedBox(height: 16),
                TextButton(
                    onPressed: () => ref
                        .read(authControllerProvider.notifier)
                        .retryInitialization(),
                    child: const Text('Try again')),
              ]),
            ))
          : null,
    );
  }
}
