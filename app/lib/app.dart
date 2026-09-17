import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/services/notification_service.dart';
import 'core/widgets/indicators/offline_banner.dart';
import 'core/widgets/material_grain.dart';
import 'core/services/in_app_update_service.dart';
import 'features/auth/splash/routed_splash.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class CIEConnectApp extends ConsumerStatefulWidget {
  const CIEConnectApp({super.key});

  @override
  ConsumerState<CIEConnectApp> createState() => _CIEConnectAppState();
}

class _CIEConnectAppState extends ConsumerState<CIEConnectApp>
    with WidgetsBindingObserver {
  late final NotificationService _notifications;
  late final InAppUpdateService _inAppUpdates;
  bool _notificationServiceReady = false;
  bool _updateCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications = NotificationService();
    _inAppUpdates = InAppUpdateService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifications.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notifications.syncForAuthenticatedUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(appRouterProvider);
    final appearance = ref.watch(appearanceProvider);
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
      title: 'Breakpoint',
      theme: AppTheme.themeFor(appearance.coolFactor),
      themeMode: ThemeMode.dark,
      routerConfig: goRouter,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      builder: (context, child) => RoutedSplash(
        router: goRouter,
        startupError: authStatus == AuthStatus.error,
        child: _mainAppBody(
          context,
          child ?? const SizedBox.shrink(),
          authStatus,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _mainAppBody(BuildContext context, Widget child, AuthStatus status) {
    final inMainApp = status == AuthStatus.authenticatedStudent ||
        status == AuthStatus.authenticatedAdmin;
    if (inMainApp && !_updateCheckScheduled) {
      _updateCheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inAppUpdates.checkAndOffer(context);
      });
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        OfflineAwareBody(child: child),
        const MaterialGrain(),
      ],
    );
  }
}
