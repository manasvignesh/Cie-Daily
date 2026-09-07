import 'package:flutter/material.dart';

class AppTheme {
  // Brand Accent Color
  static const Color primaryOrange = Color(0xFFFF5A1F);

  // Dark Theme Palette (iOS-Inspired Near-Black & Charcoal)
  static const Color darkBackground = Color(0xFF08080A);
  static const Color darkSurface = Color(0xFF141419);
  static const Color darkSurfaceElevated = Color(0xFF1C1C22);
  static const Color darkBorder = Color(0xFF22222A);
  static const Color darkPrimaryText = Color(0xFFF5F5F7);
  static const Color darkSecondaryText = Color(0xFF8E8E93);
  static const Color darkTertiaryText = Color(0xFF545458);

  // Light Theme Palette (Warm Off-White Editorial)
  static const Color lightBackground = Color(0xFFF6F6F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF0F0EE);
  static const Color lightBorder = Color(0xFFE5E5EA);
  static const Color lightPrimaryText = Color(0xFF1C1C1E);
  static const Color lightSecondaryText = Color(0xFF6E6E73);
  static const Color lightTertiaryText = Color(0xFF8E8E93);

  static const Color secondaryOrange = Color(0xFFFF8A00);

  // Theme Helpers
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color backgroundColor(BuildContext context) {
    return isDark(context) ? darkBackground : lightBackground;
  }

  static Color cardColor(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  static Color elevatedSurfaceColor(BuildContext context) {
    return isDark(context) ? darkSurfaceElevated : lightSurfaceElevated;
  }

  static Color surfaceElevatedColor(BuildContext context) {
    return elevatedSurfaceColor(context);
  }

  static Color cardBorderColor(BuildContext context) {
    return isDark(context) ? darkBorder : lightBorder;
  }

  static Color primaryTextColor(BuildContext context) {
    return isDark(context) ? darkPrimaryText : lightPrimaryText;
  }

  static Color secondaryTextColor(BuildContext context) {
    return isDark(context) ? darkSecondaryText : lightSecondaryText;
  }

  static Color tertiaryTextColor(BuildContext context) {
    return isDark(context) ? darkTertiaryText : lightTertiaryText;
  }

  static Color inputFillColor(BuildContext context) {
    return isDark(context) ? darkSurfaceElevated : lightSurfaceElevated;
  }

  static Color surfaceMutedColor(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  // ── DARK THEME SPECIFICATION ──────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        surface: darkSurface,
        onSurface: darkPrimaryText,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkPrimaryText),
        titleTextStyle: TextStyle(
          color: darkPrimaryText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),

      // ── TYPOGRAPHY HIERARCHY (SF PRO FEEL) ─────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: darkPrimaryText,
            fontFamily: 'Outfit',
            letterSpacing: -0.8),
        displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkPrimaryText,
            fontFamily: 'Outfit',
            letterSpacing: -0.5),
        titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: darkPrimaryText,
            fontFamily: 'Outfit',
            letterSpacing: -0.4),
        titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkPrimaryText,
            fontFamily: 'Outfit',
            letterSpacing: -0.2),
        bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: darkPrimaryText,
            fontFamily: 'Inter',
            height: 1.45),
        bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: darkSecondaryText,
            fontFamily: 'Inter',
            height: 1.4),
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkPrimaryText,
            fontFamily: 'Inter'),
        labelSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTertiaryText,
            fontFamily: 'Inter'),
      ),
    );
  }

  // ── LIGHT THEME SPECIFICATION ─────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        surface: lightSurface,
        onSurface: lightPrimaryText,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightPrimaryText),
        titleTextStyle: TextStyle(
          color: lightPrimaryText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),

      // ── TYPOGRAPHY HIERARCHY (LIGHT) ───────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: lightPrimaryText,
            fontFamily: 'Outfit',
            letterSpacing: -0.8),
        displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: lightPrimaryText,
            fontFamily: 'Outfit',
            letterSpacing: -0.5),
        titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: lightPrimaryText,
            fontFamily: 'Outfit',
            letterSpacing: -0.4),
        titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: lightPrimaryText,
            fontFamily: 'Outfit',
            letterSpacing: -0.2),
        bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: lightPrimaryText,
            fontFamily: 'Inter',
            height: 1.45),
        bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: lightSecondaryText,
            fontFamily: 'Inter',
            height: 1.4),
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: lightPrimaryText,
            fontFamily: 'Inter'),
        labelSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: lightTertiaryText,
            fontFamily: 'Inter'),
      ),
    );
  }
}
