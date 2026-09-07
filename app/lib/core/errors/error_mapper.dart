import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'app_exception.dart';

abstract final class ErrorMapper {
  static AppException normalize(
    Object error, {
    StackTrace? stackTrace,
    String? fallbackMessage,
  }) {
    if (error is AppException) return error;
    if (error is FirebaseAuthException) return _auth(error, stackTrace);
    if (error is FirebaseException) return _firebase(error, stackTrace);
    if (error is SocketException) {
      return AppException(
        code: AppErrorCode.network,
        userMessage:
            "We couldn't connect to the internet. Check your connection and try again.",
        cause: error,
        stackTrace: stackTrace,
        retryable: true,
      );
    }
    if (error is TimeoutException) {
      return AppException(
        code: AppErrorCode.timeout,
        userMessage: 'That took too long. Please try again.',
        cause: error,
        stackTrace: stackTrace,
        retryable: true,
      );
    }
    if (error is PlatformException && error.code == 'sign_in_canceled') {
      return AppException(
        code: AppErrorCode.cancelled,
        userMessage: 'Sign-in was cancelled.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return AppException(
      code: AppErrorCode.unknown,
      userMessage: fallbackMessage ??
          "We couldn't complete that request. Please try again.",
      cause: error,
      stackTrace: stackTrace,
      retryable: true,
    );
  }

  static AppException _auth(
      FirebaseAuthException error, StackTrace? stackTrace) {
    switch (error.code.replaceFirst('auth/', '')) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return _mapped(
            AppErrorCode.invalidCredentials,
            'The email or password you entered is incorrect.',
            error,
            stackTrace);
      case 'email-already-in-use':
        return _mapped(
            AppErrorCode.emailAlreadyExists,
            'An account already exists with this email address.',
            error,
            stackTrace);
      case 'weak-password':
        return _mapped(
            AppErrorCode.weakPassword,
            'Choose a stronger password with at least 8 characters.',
            error,
            stackTrace);
      case 'invalid-email':
        return _mapped(AppErrorCode.invalidEmail,
            'Enter a valid email address.', error, stackTrace);
      case 'user-disabled':
        return _mapped(
            AppErrorCode.forbidden,
            'This account is unavailable. Contact support if you need help.',
            error,
            stackTrace);
      case 'too-many-requests':
        return _mapped(
            AppErrorCode.rateLimited,
            'Too many attempts. Wait a moment and try again.',
            error,
            stackTrace,
            retryable: true);
      case 'network-request-failed':
        return _mapped(
            AppErrorCode.network,
            "We couldn't connect to the internet. Check your connection and try again.",
            error,
            stackTrace,
            retryable: true);
      default:
        return _mapped(AppErrorCode.unknown,
            "We couldn't sign you in. Please try again.", error, stackTrace,
            retryable: true);
    }
  }

  static AppException _firebase(
      FirebaseException error, StackTrace? stackTrace) {
    switch (error.code) {
      case 'permission-denied':
        return _mapped(
            AppErrorCode.forbidden,
            "You don't have permission to perform this action.",
            error,
            stackTrace);
      case 'not-found':
        return _mapped(AppErrorCode.notFound,
            'That item is no longer available.', error, stackTrace);
      case 'unavailable':
      case 'network-request-failed':
        return _mapped(
            AppErrorCode.network,
            "We couldn't connect right now. Check your connection and try again.",
            error,
            stackTrace,
            retryable: true);
      case 'deadline-exceeded':
        return _mapped(AppErrorCode.timeout,
            'That took too long. Please try again.', error, stackTrace,
            retryable: true);
      case 'resource-exhausted':
        return _mapped(
            AppErrorCode.rateLimited,
            'The service is busy right now. Please try again shortly.',
            error,
            stackTrace,
            retryable: true);
      case 'unauthenticated':
        return _mapped(
            AppErrorCode.unauthenticated,
            'Your session has expired. Sign in again to continue.',
            error,
            stackTrace);
      default:
        return _mapped(
            AppErrorCode.serviceUnavailable,
            "We couldn't complete that request. Please try again.",
            error,
            stackTrace,
            retryable: true);
    }
  }

  static AppException _mapped(
    AppErrorCode code,
    String message,
    Object cause,
    StackTrace? stackTrace, {
    bool retryable = false,
  }) {
    return AppException(
        code: code,
        userMessage: message,
        cause: cause,
        stackTrace: stackTrace,
        retryable: retryable);
  }

  static String userMessage(Object error, {String? fallbackMessage}) {
    return normalize(error, fallbackMessage: fallbackMessage).userMessage;
  }
}
