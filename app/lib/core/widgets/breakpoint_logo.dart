import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Canonical Breakpoint Logo and Marker System for Breakpoint by Manas.
class BreakpointLogo extends StatelessWidget {
  final double fontSize;
  final bool showLockup;
  final bool showTagline;
  final Color? textColor;
  final Color dotColor;
  final MainAxisAlignment alignment;

  const BreakpointLogo({
    super.key,
    this.fontSize = 24,
    this.showLockup = true,
    this.showTagline = false,
    this.textColor,
    this.dotColor = AppTheme.primaryOrange,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = textColor ?? AppTheme.primaryTextColor(context);
    final dotSize = fontSize * 0.58;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment == MainAxisAlignment.center
          ? CrossAxisAlignment.center
          : (alignment == MainAxisAlignment.start
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end),
      children: [
        // Wordmark: BREAKP●INT
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'BREAKP',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: defaultTextColor,
                letterSpacing: 1.5,
                fontFamily: 'Outfit',
                height: 1.0,
              ),
            ),
            const SizedBox(width: 1),
            // Signal Orange Breakpoint Marker
            Container(
              width: dotSize,
              height: dotSize,
              margin: EdgeInsets.symmetric(horizontal: fontSize * 0.06),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.4),
                    blurRadius: dotSize * 0.8,
                    spreadRadius: dotSize * 0.1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 1),
            Text(
              'INT',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: defaultTextColor,
                letterSpacing: 1.5,
                fontFamily: 'Outfit',
                height: 1.0,
              ),
            ),
          ],
        ),
        if (showLockup) ...[
          SizedBox(height: fontSize * 0.18),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'By ',
                  style: TextStyle(
                    fontSize: fontSize * 0.38,
                    fontWeight: FontWeight.w500,
                    color: defaultTextColor.withValues(alpha: 0.6),
                    letterSpacing: 3.0,
                    fontFamily: 'Inter',
                  ),
                ),
                TextSpan(
                  text: 'MANAS',
                  style: TextStyle(
                    fontSize: fontSize * 0.38,
                    fontWeight: FontWeight.w700,
                    color: defaultTextColor.withValues(alpha: 0.85),
                    letterSpacing: 3.0,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
        if (showTagline) ...[
          SizedBox(height: fontSize * 0.14),
          Text(
            'Worth stopping for.',
            style: TextStyle(
              fontSize: fontSize * 0.36,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppTheme.secondaryTextColor(context),
              letterSpacing: 0.5,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ],
    );
  }
}

/// System Breakpoint Dot Marker for active states, live indicators & section signals
class BreakpointDotMarker extends StatelessWidget {
  final double size;
  final Color color;
  final bool isLive;

  const BreakpointDotMarker({
    super.key,
    this.size = 8.0,
    this.color = AppTheme.primaryOrange,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLive) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, val, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: val),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6 * val),
                blurRadius: size * 1.2,
                spreadRadius: size * 0.2,
              ),
            ],
          ),
        );
      },
    );
  }
}
