import 'package:flutter/material.dart';

/// Centralized responsive breakpoints for the application layout.
abstract class AppBreakpoints {
  static const double compact = 360.0;
  static const double medium = 600.0;
  static const double large = 900.0;
}

/// Dynamic, safe-area aware layout responsive helper class.
class AppResponsive {
  /// Returns `true` if screen width is less than compact breakpoint (360dp).
  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AppBreakpoints.compact;
  }

  /// Returns `true` if screen width is medium or tablet sized (>= 600dp).
  static bool isMedium(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;
  }

  /// Returns `true` if orientation is landscape (width > height).
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  /// System top safe-area inset (Status bar, Notch, Dynamic Island).
  static double systemTopInset(BuildContext context) {
    return MediaQuery.paddingOf(context).top;
  }

  /// System bottom safe-area inset (Home indicator / Android gesture navigation bar).
  static double systemBottomInset(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom;
  }

  /// Active software keyboard height (viewInsets.bottom).
  static double keyboardBottomInset(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom;
  }

  /// Dynamic floating navigation bar height depending on screen size/orientation.
  static double bottomNavHeight(BuildContext context) {
    if (isLandscape(context)) {
      return 52.0;
    }
    return isCompact(context) ? 58.0 : 64.0;
  }

  /// Returns total bottom offset required ONLY for floating overlays above navigation shell.
  static double overlayBottomOffset(BuildContext context) {
    final navHeight = bottomNavHeight(context);
    final safeBottom = systemBottomInset(context);
    return safeBottom + navHeight + 8.0;
  }

  /// Returns the vertical padding used by the bottom navigation bar.
  static double bottomNavVerticalPadding(BuildContext context) {
    final isLandscape = AppResponsive.isLandscape(context);
    final isCompactScreen = isCompact(context);
    return isLandscape ? 6.0 : (isCompactScreen ? 10.0 : 14.0);
  }

  /// Returns the total height occupied by the bottom navigation including padding.
  static double totalBottomNavSpace(BuildContext context) {
    final navHeight = bottomNavHeight(context);
    final verticalPadding = bottomNavVerticalPadding(context);
    final safeBottom = systemBottomInset(context);
    // Total space = system inset + top padding + nav bar + bottom padding
    return safeBottom + (verticalPadding * 2) + navHeight;
  }

  /// Returns bottom offset for left metadata in Reels (positioned low near bottom nav).
  static double reelMetadataBottomOffset(BuildContext context) {
    final safeBottom = systemBottomInset(context);
    // Position low, just above system navigation area
    return safeBottom + 5.0;
  }

  /// Returns bottom offset for right action buttons in Reels (positioned low near bottom nav).
  static double reelActionsBottomOffset(BuildContext context) {
    final safeBottom = systemBottomInset(context);
    // Position low, just above system navigation area
    return safeBottom + 8.0;
  }
}
