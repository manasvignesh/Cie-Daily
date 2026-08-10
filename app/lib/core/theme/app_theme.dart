import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryOrange = Color(0xFFFF5A1F);
  static const Color secondaryOrange = Color(0xFFFF7A3D);
  static const Color cream = Color(0xFFFFF8F4);
  static const Color primaryText = Color(0xFF111111);
  static const Color secondaryText = Color(0xFF666666);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: cream,
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        secondary: secondaryOrange,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryText),
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: primaryText),
        bodyMedium: TextStyle(color: secondaryText),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Basic dark theme mapping maintaining the brand where possible
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: secondaryOrange,
        surface: Color(0xFF1E1E1E),
      ),
    );
  }
}
