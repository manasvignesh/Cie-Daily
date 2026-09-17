import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'splash_experience.dart';
import 'splash_preferences.dart';

/// Route restoration may notify during a descendant's build. Observe after
/// paint, both to avoid ancestor setState and to expose a laid-out destination.
class RoutedSplash extends StatefulWidget {
  const RoutedSplash(
      {super.key,
      required this.router,
      required this.child,
      this.startupError = false,
      this.preferences});
  final GoRouter router;
  final Widget child;
  final bool startupError;
  final SplashPreferences? preferences;
  @override
  State<RoutedSplash> createState() => _RoutedSplashState();
}

class _RoutedSplashState extends State<RoutedSplash> {
  bool _ready = false;
  bool _scheduled = false;
  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_changed);
    _changed();
  }

  @override
  void didUpdateWidget(covariant RoutedSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_changed);
      widget.router.routerDelegate.addListener(_changed);
      _ready = false;
      _changed();
    }
  }

  void _changed() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final path = widget.router.routerDelegate.currentConfiguration.uri.path;
      final ready = path.isNotEmpty && path != '/';
      if (_ready != ready) setState(() => _ready = ready);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SplashExperience(
        destinationReady: _ready || widget.startupError,
        preferences: widget.preferences,
        child: widget.child,
      );
}
