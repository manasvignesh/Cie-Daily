import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app_exception.dart';

abstract final class AppErrorReporter {
  static Future<void> record(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  }) async {
    final original = error is AppException ? error.cause ?? error : error;
    if (kDebugMode) {
      debugPrint('[$operation] ${original.runtimeType}');
    }
    await Sentry.captureException(
      original,
      stackTrace: stackTrace,
      withScope: (scope) => scope.setTag('operation', operation),
    );
  }
}
