import 'package:flutter/material.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

class AppDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
          elevation: isDark ? 24 : 12,
          shadowColor: Colors.black.withValues(alpha: isDark ? 0.8 : 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: isDark
                ? BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  )
                : BorderSide.none,
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          title: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (confirmText != null)
                  PrimaryButton(
                    text: confirmText,
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onConfirm != null) onConfirm();
                    },
                  ),
                if (cancelText != null) ...[
                  const SizedBox(height: 12),
                  SecondaryButton(
                    text: cancelText,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}
