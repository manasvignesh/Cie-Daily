import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';

const String trustedBackendBaseUrl = String.fromEnvironment(
  'CIE_TRUSTED_BACKEND_URL',
  // This is a public endpoint, not a credential. Keeping the production URL
  // as the default prevents otherwise valid APK/AAB builds from silently
  // shipping with messaging disabled when a Dart define is omitted.
  defaultValue: 'https://fuvquwhphuheqgfdmtbh.supabase.co/functions/v1',
);

class TrustedBackendClient {
  TrustedBackendClient({
    FirebaseAuth? auth,
    http.Client? httpClient,
    String? baseUrl,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _http = httpClient ?? http.Client(),
        _baseUrl =
            (baseUrl ?? trustedBackendBaseUrl).replaceAll(RegExp(r'/+$'), '');

  final FirebaseAuth _auth;
  final http.Client _http;
  final String _baseUrl;

  bool get isConfigured => _baseUrl.startsWith('https://');

  static String newRequestId() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<Map<String, dynamic>> post(
    String functionName,
    Map<String, dynamic> body, {
    bool retryOnce = true,
  }) async {
    if (!isConfigured) {
      throw const AppException(
        code: AppErrorCode.serviceUnavailable,
        userMessage:
            'Messaging is temporarily unavailable. Please try again later.',
        retryable: true,
      );
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        code: AppErrorCode.unauthenticated,
        userMessage: 'Sign in again to continue.',
      );
    }

    Future<http.Response> attempt({required bool forceRefresh}) async {
      final token = await user.getIdToken(forceRefresh);
      if (token == null || token.isEmpty) {
        throw const AppException(
          code: AppErrorCode.unauthenticated,
          userMessage: 'Sign in again to continue.',
        );
      }
      return _http
          .post(
            Uri.parse('$_baseUrl/$functionName'),
            headers: {
              'authorization': 'Bearer $token',
              'content-type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 18));
    }

    try {
      var response = await attempt(forceRefresh: true);
      if (retryOnce &&
          (response.statusCode == 401 || response.statusCode >= 500)) {
        response = await attempt(forceRefresh: response.statusCode == 401);
      }
      final decoded = _decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      throw _exceptionFor(response.statusCode, decoded);
    } on TimeoutException {
      throw const AppException(
        code: AppErrorCode.timeout,
        userMessage: 'The request timed out. Please try again.',
        retryable: true,
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      throw AppException(
        code: AppErrorCode.network,
        userMessage: 'Check your connection and try again.',
        cause: error,
        stackTrace: stackTrace,
        retryable: true,
      );
    }
  }

  Map<String, dynamic> _decode(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  AppException _exceptionFor(int status, Map<String, dynamic> body) {
    final retryable = status == 408 || status == 429 || status >= 500;
    if (status == 401) {
      return const AppException(
        code: AppErrorCode.unauthenticated,
        userMessage: 'Your session expired. Sign in again.',
      );
    }
    if (status == 403) {
      return const AppException(
        code: AppErrorCode.forbidden,
        userMessage: 'You do not have permission to do that.',
      );
    }
    if (status == 429) {
      return const AppException(
        code: AppErrorCode.rateLimited,
        userMessage: 'Too many requests. Please wait a moment.',
        retryable: true,
      );
    }
    return AppException(
      code:
          retryable ? AppErrorCode.serviceUnavailable : AppErrorCode.validation,
      userMessage: retryable
          ? 'The service is temporarily unavailable. Please try again.'
          : (body['message'] as String? ??
              'That request could not be completed.'),
      retryable: retryable,
    );
  }
}
