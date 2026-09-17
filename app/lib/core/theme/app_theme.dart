import 'package:flutter/material.dart';

class BreakpointThemeExtension
    extends ThemeExtension<BreakpointThemeExtension> {
  final Color background;
  final Color surface;
  final Color elevatedSurface;
  final Color border;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color nearGlow;
  final Color ambientGlow;

  const BreakpointThemeExtension({
    required this.background,
    required this.surface,
    required this.elevatedSurface,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.nearGlow,
    required this.ambientGlow,
  });

  @override
  BreakpointThemeExtension copyWith({
    Color? background,
    Color? surface,
    Color? elevatedSurface,
    Color? border,
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? nearGlow,
    Color? ambientGlow,
  }) =>
      BreakpointThemeExtension(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        elevatedSurface: elevatedSurface ?? this.elevatedSurface,
        border: border ?? this.border,
        primaryText: primaryText ?? this.primaryText,
        secondaryText: secondaryText ?? this.secondaryText,
        tertiaryText: tertiaryText ?? this.tertiaryText,
        nearGlow: nearGlow ?? this.nearGlow,
        ambientGlow: ambientGlow ?? this.ambientGlow,
      );

  @override
  BreakpointThemeExtension lerp(
      covariant ThemeExtension<BreakpointThemeExtension>? other, double t) {
    if (other is! BreakpointThemeExtension) return this;
    return BreakpointThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      nearGlow: Color.lerp(nearGlow, other.nearGlow, t)!,
      ambientGlow: Color.lerp(ambientGlow, other.ambientGlow, t)!,
    );
  }
}

class AppTheme {
  static const Color primaryOrange = Color(0xFFE85A20);
  static const Color secondaryOrange = Color(0xFFA84C22);
  static const Color softEmber = Color(0xFF5A3423);
  static const Color sunlightChampagne = Color(0xFF8A654B);
  static const Color moonlightAccent = Color(0xFFD8E1E8);

  static const _warmBackground = Color(0xFF090A0A);
  static const _warmSurface = Color(0xFF101110);
  static const _warmElevated = Color(0xFF151411);
  static const _warmBorder = Color(0xFF302A26);
  static const _coolBackground = Color(0xFF07090D);
  static const _coolSurface = Color(0xFF0E1218);
  static const _coolElevated = Color(0xFF131922);
  static const _coolBorder = Color(0xFF27313C);
  static const _warmPrimaryText = Color(0xFFF3F0E9);
  static const _coolPrimaryText = Color(0xFFF0F1EE);
  static const _warmSecondaryText = Color(0xFF969792);
  static const _warmTertiaryText = Color(0xFF73746F);
  static const _coolSecondaryText = Color(0xFF939CA7);
  static const _coolTertiaryText = Color(0xFF68727D);

  static BreakpointThemeExtension colors(double coolFactor) =>
      BreakpointThemeExtension(
        background: Color.lerp(_warmBackground, _coolBackground, coolFactor)!,
        surface: Color.lerp(_warmSurface, _coolSurface, coolFactor)!,
        elevatedSurface: Color.lerp(_warmElevated, _coolElevated, coolFactor)!,
        border: Color.lerp(_warmBorder, _coolBorder, coolFactor)!,
        primaryText:
            Color.lerp(_warmPrimaryText, _coolPrimaryText, coolFactor)!,
        secondaryText: Color.lerp(
            _warmSecondaryText, _coolSecondaryText, coolFactor)!,
        tertiaryText:
            Color.lerp(_warmTertiaryText, _coolTertiaryText, coolFactor)!,
        nearGlow: Color.lerp(
            const Color(0xFFA84C22), const Color(0xFFD8E1E8), coolFactor)!,
        ambientGlow:
            Color.lerp(softEmber, const Color(0xFF56647A), coolFactor)!,
      );

  static Color accentColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color backgroundColor(BuildContext context) =>
      _colors(context).background;
  static Color cardColor(BuildContext context) => _colors(context).surface;
  static Color elevatedSurfaceColor(BuildContext context) =>
      _colors(context).elevatedSurface;
  static Color surfaceElevatedColor(BuildContext context) =>
      elevatedSurfaceColor(context);
  static Color cardBorderColor(BuildContext context) => _colors(context).border;
  static Color primaryTextColor(BuildContext context) =>
      _colors(context).primaryText;
  static Color secondaryTextColor(BuildContext context) =>
      _colors(context).secondaryText;
  static Color tertiaryTextColor(BuildContext context) =>
      _colors(context).tertiaryText;
  static Color inputFillColor(BuildContext context) =>
      _colors(context).elevatedSurface;
  static Color surfaceMutedColor(BuildContext context) =>
      _colors(context).surface;
  static bool isDark(BuildContext context) => true;
  static Color nearGlowColor(BuildContext context) => _colors(context).nearGlow;
  static Color ambientGlowColor(BuildContext context) =>
      _colors(context).ambientGlow;
  static Color materialEdgeColor(BuildContext context) => Color.lerp(
        const Color(0xFF302A26),
        const Color(0xFF27313C),
        1 - sunlightStrength(context),
      )!;
  static Color metalHighlightColor(BuildContext context) => Color.lerp(
        sunlightChampagne,
        const Color(0xFFD8E1E8),
        1 - sunlightStrength(context),
      )!;
  static Color glassSurfaceColor(BuildContext context) => Color.lerp(
        const Color(0xFF171612),
        const Color(0xB3141B25),
        1 - sunlightStrength(context),
      )!;
  static Color selectedSurfaceColor(BuildContext context) => Color.lerp(
        const Color(0xFF2A1C16),
        const Color(0xFF1A222D),
        1 - sunlightStrength(context),
      )!;

  static double sunlightStrength(BuildContext context) {
    final blue = Theme.of(context).colorScheme.primary.blue.toDouble();
    return (((moonlightAccent.blue - blue) /
                (moonlightAccent.blue - primaryOrange.blue))
            .clamp(0.0, 1.0))
        .toDouble();
  }

  static double atmosphereValue(
    BuildContext context, {
    required double sunlight,
    required double moonlight,
  }) {
    final warmth = sunlightStrength(context);
    return moonlight + ((sunlight - moonlight) * warmth);
  }

  static LinearGradient premiumSurfaceGradient(BuildContext context) {
    final palette = _colors(context);
    final warmth = sunlightStrength(context);
    final highlight = metalHighlightColor(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(palette.surface, highlight, 0.025 + (0.015 * warmth))!,
        palette.surface,
        Color.lerp(palette.surface, palette.background, 0.22 + (0.10 * warmth))!,
      ],
      stops: const [0, 0.26, 1],
    );
  }

  static LinearGradient raisedSurfaceGradient(BuildContext context) {
    final palette = _colors(context);
    final highlight = metalHighlightColor(context);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(palette.elevatedSurface, highlight, 0.035)!,
        palette.elevatedSurface,
        Color.lerp(palette.elevatedSurface, palette.background, 0.18)!,
      ],
      stops: const [0, 0.22, 1],
    );
  }

  static LinearGradient atmosphereGradient(BuildContext context) {
    final palette = _colors(context);
    final warmth = sunlightStrength(context);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        palette.nearGlow.withValues(alpha: 0.065 - (0.04 * warmth)),
        palette.elevatedSurface.withValues(alpha: 0.88 + (0.06 * warmth)),
        palette.background,
        palette.ambientGlow.withValues(alpha: 0.04 - (0.025 * warmth)),
      ],
      stops: const [0, 0.10, 0.42, 1],
    );
  }

  static BreakpointThemeExtension _colors(BuildContext context) =>
      Theme.of(context).extension<BreakpointThemeExtension>() ?? colors(0);

  static ThemeData themeFor(double coolFactor) {
    final palette = colors(coolFactor);
    final accent = Color.lerp(primaryOrange, moonlightAccent, coolFactor)!;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: palette.surface,
        onSurface: palette.primaryText,
        outline: palette.border,
      ),
      extensions: [palette],
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: palette.primaryText),
        titleTextStyle: TextStyle(
          color: palette.primaryText,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          fontFamily: 'Sora',
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: _text(34, FontWeight.w900, palette.primaryText, 'Sora'),
        displayMedium: _text(28, FontWeight.w800, palette.primaryText, 'Sora'),
        titleLarge: _text(22, FontWeight.w700, palette.primaryText, 'Sora'),
        titleMedium: _text(18, FontWeight.w600, palette.primaryText, 'Sora'),
        bodyLarge: _text(16, FontWeight.normal, palette.primaryText, 'Inter',
            height: 1.45),
        bodyMedium: _text(14, FontWeight.normal, palette.secondaryText, 'Inter',
            height: 1.4),
        labelLarge: _text(14, FontWeight.w600, palette.primaryText, 'Inter'),
        labelSmall: _text(12, FontWeight.w500, palette.secondaryText, 'Inter'),
      ),
      dividerTheme:
          DividerThemeData(color: palette.border, thickness: 1, space: 1),
    );
  }

  static TextStyle _text(
          double size, FontWeight weight, Color color, String family,
          {double? height}) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFamily: family,
        height: height,
      );

  static ThemeData get darkTheme => themeFor(0);

  // Compatibility alias for older widget tests. It is still dark-only.
  static ThemeData get lightTheme => darkTheme;
}
