import 'package:flutter/material.dart';

enum ToastType { success, error, info }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        backgroundColor = Colors.green.shade800;
        icon = Icons.check_circle_outline_rounded;
        break;
      case ToastType.error:
        backgroundColor = Colors.red.shade800;
        icon = Icons.error_outline_rounded;
        break;
      case ToastType.info:
      default:
        backgroundColor = const Color(0xFF333333);
        icon = Icons.info_outline_rounded;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }
}
