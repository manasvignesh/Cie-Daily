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
    return showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actionsPadding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 8),
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
