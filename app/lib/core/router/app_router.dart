import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';

import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/feed/screens/home_screen.dart';
import '../../features/feed/screens/create_video_post_screen.dart';
import '../../features/feed/screens/create_article_post_screen.dart';
import '../../features/spaces/screens/spaces_home_screen.dart';
import '../../features/spaces/screens/active_space_screen.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/discover/screens/article_detail_screen.dart';
import '../../features/feed/models/post_model.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/individual_chat_screen.dart';
import '../widgets/navigation/app_bottom_nav.dart';

import '../../features/admin/widgets/admin_bottom_nav.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_spaces_screen.dart';
import '../../features/admin/screens/admin_moderation_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      
      switch (authStatus) {
        case AuthStatus.initial:
          return '/'; 
        case AuthStatus.unauthenticated:
          return isLoggingIn ? null : '/login';
        case AuthStatus.authenticatedAdmin:
          if (state.matchedLocation.startsWith('/admin')) {
            return null;
          }
          return '/admin/dashboard';
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
        path: '/profile_setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/create_video_post',
        builder: (context, state) => const CreateVideoPostScreen(),
      ),
      GoRoute(
        path: '/create_article_post',
        builder: (context, state) => const CreateArticlePostScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return IndividualChatScreen(
            conversationId: conversationId,
            partnerUid: extra['partnerUid'] ?? '',
            partnerName: extra['partnerName'] ?? 'Student',
            partnerPhoto: extra['partnerPhoto'],
          );
        },
      ),
      GoRoute(
        path: '/spaces/:spaceId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final spaceId = state.pathParameters['spaceId']!;
          final roomName = state.extra as String?;
          return ActiveSpaceScreen(spaceId: spaceId, roomName: roomName);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          int index = 0;
          if (state.matchedLocation.startsWith('/admin/dashboard')) index = 0;
          if (state.matchedLocation.startsWith('/admin/spaces')) index = 1;
          if (state.matchedLocation.startsWith('/admin/moderation')) index = 2;
          if (state.matchedLocation.startsWith('/admin/users')) index = 3;

          return Scaffold(
            body: child,
            bottomNavigationBar: AdminBottomNav(
              currentIndex: index,
              onItemSelected: (i) {
                switch (i) {
                  case 0:
                    context.go('/admin/dashboard');
                    break;
                  case 1:
                    context.go('/admin/spaces');
                    break;
                  case 2:
                    context.go('/admin/moderation');
                    break;
                  case 3:
                    context.go('/admin/users');
                    break;
                }
              },
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/spaces',
            builder: (context, state) => const AdminSpacesScreen(),
          ),
          GoRoute(
            path: '/admin/moderation',
            builder: (context, state) => const AdminModerationScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          int index = 0;
          if (state.matchedLocation.startsWith('/home')) index = 0;
          if (state.matchedLocation.startsWith('/discover')) index = 1;
          if (state.matchedLocation.startsWith('/spaces')) index = 2;
          if (state.matchedLocation.startsWith('/chat')) index = 3;
          if (state.matchedLocation.startsWith('/profile')) index = 4;

          return Scaffold(
            extendBody: true,
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
                    context.go('/chat');
                    break;
                  case 4:
                    context.go('/profile');
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
            builder: (context, state) => const DiscoverScreen(),
            routes: [
              GoRoute(
                path: 'article',
                builder: (context, state) {
                  final article = state.extra as PostModel;
                  return ArticleDetailScreen(article: article);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/spaces',
            builder: (context, state) => const SpacesHomeScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});
