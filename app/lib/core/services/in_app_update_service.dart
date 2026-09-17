import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class InAppUpdateService {
  static const _channel = MethodChannel('com.ciedaily.app/in_app_update');
  bool _checkedThisSession = false;

  Future<void> checkAndOffer(BuildContext context) async {
    if (_checkedThisSession || !Platform.isAndroid || kDebugMode) return;
    _checkedThisSession = true;
    try {
      final info = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkForUpdate');
      if (info?['updateAvailable'] != true || info?['flexibleAllowed'] != true || !context.mounted) return;
      final start = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final colors = Theme.of(dialogContext).extension<BreakpointThemeExtension>();
          final accent = AppTheme.accentColor(dialogContext);
          return AlertDialog(
            backgroundColor: colors?.elevatedSurface ?? AppTheme.cardColor(dialogContext),
            title: const Text('A new Breakpoint is ready.'),
            content: const Text('We\'ve made a few things better. Update to get the latest version.'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: accent.withOpacity(0.45)),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Later')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Update now')),
            ],
          );
        },
      );
      if (start == true) await _channel.invokeMethod<void>('startFlexibleUpdate');
    } catch (_) {
      // Play services, debug, sideloaded, and unavailable-update failures are silent.
    }
  }
}
