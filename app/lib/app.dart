import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/services/notification_service.dart';
import 'core/widgets/indicators/offline_banner.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class CIEConnectApp extends ConsumerStatefulWidget {
  const CIEConnectApp({super.key});

  @override
  ConsumerState<CIEConnectApp> createState() => _CIEConnectAppState();
}

class _CIEConnectAppState extends ConsumerState<CIEConnectApp> {
  late final NotificationService _notifications;
  bool _notificationServiceReady = false;

  @override
  void initState() {
    super.initState();
    _notifications = NotificationService();
  }

  @override
  void dispose() {
    _notifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final authStatus = ref.watch(authControllerProvider);

    if (!_notificationServiceReady) {
      _notificationServiceReady = true;
      _notifications.initialize(
        router: goRouter,
        messengerKey: rootScaffoldMessengerKey,
      );
    }
    if (authStatus == AuthStatus.authenticatedStudent ||
        authStatus == AuthStatus.authenticatedAdmin) {
      _notifications.syncForAuthenticatedUser();
    } else if (authStatus == AuthStatus.unauthenticated) {
      _notifications.clearForLogout();
    }

    return MaterialApp.router(
      title: 'CIE Connect',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      builder: (context, child) => OfflineAwareBody(
        child: child ?? const SizedBox.shrink(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
