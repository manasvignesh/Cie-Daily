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
import '../../features/feed/screens/single_reel_screen.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/discover/screens/article_detail_screen.dart';
import '../../features/feed/models/post_model.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/individual_chat_screen.dart';
import '../../features/chat/screens/group_chat_screen.dart';
import '../widgets/navigation/app_bottom_nav.dart';
import '../theme/app_theme.dart';

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
    errorBuilder: (context, state) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 54, color: AppTheme.primaryOrange),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTextColor(context),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We couldn't open this page.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.secondaryTextColor(context),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back to Discover',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    },
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';

      switch (authStatus) {
        case AuthStatus.initial:
        case AuthStatus.error:
          return '/';
        case AuthStatus.unauthenticated:
          if (state.matchedLocation == '/') return null;
          return isLoggingIn ? null : '/login';
        case AuthStatus.authenticatedAdmin:
          if (isLoggingIn) return '/admin/dashboard';
          if (state.matchedLocation == '/') return null;
          if (state.matchedLocation.startsWith('/admin')) {
            return null;
          }
          return '/admin/dashboard';
        case AuthStatus.profileIncomplete:
          if (isLoggingIn) return '/profile_setup';
          if (state.matchedLocation == '/') return null;
          return '/profile_setup';
        case AuthStatus.authenticatedStudent:
          if (isLoggingIn || state.matchedLocation == '/profile_setup') {
            return '/home';
          }
          if (state.matchedLocation == '/') return null;
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
        path: '/group_chat/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GroupChatScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/spaces/:spaceId',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/spaces',
      ),
      GoRoute(
        path: '/article/:id',
        name: 'articleDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final articleId = state.pathParameters['id']!;
          final article = state.extra as PostModel?;
          return ArticleDetailScreen(
              articleId: articleId, initialArticle: article);
        },
      ),
      GoRoute(
        path: '/article_detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final article = state.extra as PostModel?;
          return ArticleDetailScreen(
              articleId: article?.id, initialArticle: article);
        },
      ),
      GoRoute(
        path: '/discover/article',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final article = state.extra as PostModel?;
          return ArticleDetailScreen(
              articleId: article?.id, initialArticle: article);
        },
      ),
      GoRoute(
        path: '/reel/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final reelId = state.pathParameters['id']!;
          final post = state.extra as PostModel?;
          return SingleReelScreen(reelId: reelId, post: post);
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
          return MainSwipeShell(
            location: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DiscoverScreen(),
            routes: [
              GoRoute(
                path: 'article',
                builder: (context, state) {
                  final article = state.extra as PostModel;
                  return ArticleDetailScreen(initialArticle: article);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const HomeScreen(),
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
      GoRoute(
        path: '/profile/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(targetUserId: userId);
        },
      ),
    ],
  );
});

class MainSwipeShell extends StatefulWidget {
  final Widget child;
  final String location;

  const MainSwipeShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  State<MainSwipeShell> createState() => _MainSwipeShellState();
}

class _MainSwipeShellState extends State<MainSwipeShell> {
  static const List<String> _routes = [
    '/home',
    '/discover',
    '/spaces',
    '/chat',
    '/profile',
  ];

  int _calculateIndex(String loc) {
    if (loc.startsWith('/home')) return 0;
    if (loc.startsWith('/discover')) return 1;
    if (loc.startsWith('/spaces')) return 2;
    if (loc.startsWith('/chat')) return 3;
    if (loc.startsWith('/profile')) return 4;
    return 0;
  }

  bool _isMainRoute(String loc) {
    return loc == '/home' ||
        loc == '/discover' ||
        loc == '/spaces' ||
        loc == '/chat' ||
        loc == '/profile';
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateIndex(widget.location);
    final isTopLevel = _isMainRoute(widget.location);

    return Scaffold(
      extendBody: true,
      body: isTopLevel
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey(widget.location),
                child: widget.child,
              ),
            )
          : widget.child,
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onItemSelected: (index) {
          if (currentIndex != index) {
            context.go(_routes[index]);
          }
        },
      ),
    );
  }
}
