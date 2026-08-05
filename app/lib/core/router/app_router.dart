import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/feed/screens/home_screen.dart';
import '../../features/social/screens/inbox_screen.dart';
import '../../features/social/screens/chat_screen.dart';
import '../../features/spaces/screens/spaces_home_screen.dart';
import '../../features/spaces/screens/active_space_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../widgets/navigation/app_bottom_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/otp';
      
      switch (authStatus) {
        case AuthStatus.initial:
          return '/'; 
        case AuthStatus.unauthenticated:
          return isLoggingIn ? null : '/login';
        case AuthStatus.authenticatedAdmin:
          return '/admin_placeholder';
        case AuthStatus.profileIncomplete:
          return '/profile_setup';
        case AuthStatus.authenticatedStudent:
          if (isLoggingIn || state.matchedLocation == '/' || state.matchedLocation == '/profile_setup') {
            return '/home';
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => OtpScreen(email: state.extra as String),
      ),
      GoRoute(
        path: '/profile_setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/admin_placeholder',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Please use the web dashboard for admin access.'),
          ),
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          int index = 0;
          if (state.matchedLocation.startsWith('/home')) index = 0;
          if (state.matchedLocation.startsWith('/discover')) index = 1;
          if (state.matchedLocation.startsWith('/spaces')) index = 2;
          if (state.matchedLocation.startsWith('/inbox')) index = 3;

          return Scaffold(
            body: child,
            bottomNavigationBar: AppBottomNav(
              currentIndex: index,
              onItemSelected: (i) {
                switch (i) {
                  case 0:
                    context.go('/home');
                    break;
                  case 1:
                    context.go('/discover');
                    break;
                  case 2:
                    context.go('/spaces');
                    break;
                  case 3:
                    context.go('/inbox');
                    break;
                }
              },
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Discover Page'))),
          ),
          GoRoute(
            path: '/spaces',
            builder: (context, state) => const SpacesHomeScreen(),
          ),
          GoRoute(
            path: '/inbox',
            builder: (context, state) => const InboxScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ChatScreen(conversationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/space/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ActiveSpaceScreen(spaceId: state.pathParameters['id']!),
      ),
    ],
  );
});
