import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Refined modern color palette
  static const Color primaryOrange = Color(0xFFFF5A1F);
  static const Color secondaryOrange = Color(0xFFFF7A3D);
  static const Color cream = Color(0xFFFCF9F7); // Warmer, softer cream
  static const Color primaryText = Color(0xFF1A1A1A);
  static const Color secondaryText = Color(0xFF737373);
  static const Color trueBlack = Color(0xFF000000); // True black for AMOLED
  static const Color darkSurface = Color(0xFF141414); // Elevated dark surface

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme(ThemeData.light().textTheme);
    
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: cream,
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        secondary: secondaryOrange,
        surface: Colors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: primaryText, fontWeight: FontWeight.bold),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: primaryText),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: secondaryText),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryText),
        titleTextStyle: GoogleFonts.outfit(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);
    
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: trueBlack,
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: secondaryOrange,
        surface: darkSurface,
      ),
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: trueBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
