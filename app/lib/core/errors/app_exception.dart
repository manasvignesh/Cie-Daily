enum AppErrorCode {
  invalidCredentials,
  emailAlreadyExists,
  weakPassword,
  invalidEmail,
  validation,
  unauthenticated,
  forbidden,
  notFound,
  network,
  timeout,
  rateLimited,
  uploadFailed,
  serviceUnavailable,
  cancelled,
  unknown,
}

class AppException implements Exception {
  const AppException({
    required this.code,
    required this.userMessage,
    this.cause,
    this.stackTrace,
    this.retryable = false,
  });

  final AppErrorCode code;
  final String userMessage;
  final Object? cause;
  final StackTrace? stackTrace;
  final bool retryable;

  @override
  String toString() => 'AppException(${code.name})';
}
