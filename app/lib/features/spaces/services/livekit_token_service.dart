import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/utils/role_utils.dart';

class LiveKitTokenService {
  static const String liveKitUrl = 'wss://cie-daily-79ts1icb.livekit.cloud';
  static const String _tokenEndpoint = String.fromEnvironment(
    'LIVEKIT_TOKEN_ENDPOINT',
    defaultValue: '',
  );
  static const String _temporaryApiKey = String.fromEnvironment(
    'LIVEKIT_API_KEY',
    defaultValue: 'APIRdnqfgkFQ6CP',
  );
  static const String _temporaryApiSecret = String.fromEnvironment(
    'LIVEKIT_API_SECRET',
    defaultValue: 'vcFGzW6W2NV5qzSdlXtuN2vbFcMytIXyO90sAXV7NQF',
  );

  static Future<String> fetchToken({
    required String spaceId,
    required String roomName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const AppException(
        code: AppErrorCode.unauthenticated,
        userMessage: 'Sign in again to join this space.',
      );
    }
    if (_tokenEndpoint.isEmpty) {
      return _createTemporaryEmbeddedToken(user, roomName);
    }
    if (!_tokenEndpoint.startsWith('https://')) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Invalid live service configuration.',
      );
    }

    try {
      final idToken = await user.getIdToken(true);
      final response = await http
          .post(
            Uri.parse(_tokenEndpoint),
            headers: {
              'Authorization': 'Bearer ${idToken ?? ''}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'spaceId': spaceId,
              'roomName': roomName,
              'requestedRole': 'participant',
            }),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {}
      final providerCode = body?['error']?.toString();
      developer.log(
        'token_response spaceId=$spaceId roomName=$roomName '
        'status=${response.statusCode} providerError=$providerCode',
        name: 'cie_daily.live_spaces',
      );

      switch (response.statusCode) {
        case 200:
          final token = body?['token']?.toString() ?? '';
          if (token.isNotEmpty) return token;
          break;
        case 401:
          throw const AppException(
            code: AppErrorCode.unauthenticated,
            userMessage: 'Sign in again to join this space.',
          );
        case 403:
          throw const AppException(
            code: AppErrorCode.forbidden,
            userMessage: "You don't have permission to join this space.",
          );
        case 404:
          if (providerCode == 'room_not_found' || providerCode == 'not_found') {
            throw const AppException(
              code: AppErrorCode.notFound,
              userMessage: 'This live space is no longer available.',
            );
          }
          break;
        case 409:
          throw const AppException(
            code: AppErrorCode.notFound,
            userMessage: 'This live space is no longer available.',
          );
        case 429:
          throw const AppException(
            code: AppErrorCode.rateLimited,
            userMessage: 'Too many join attempts. Wait a moment and try again.',
            retryable: true,
          );
      }

      throw const AppException(
        code: AppErrorCode.serviceUnavailable,
        userMessage:
            'Live spaces are temporarily unavailable. Please try again later.',
        retryable: true,
      );
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw ErrorMapper.normalize(
        error,
        stackTrace: stackTrace,
        fallbackMessage:
            'Live spaces are temporarily unavailable. Please try again later.',
      );
    }
  }

  static String _createTemporaryEmbeddedToken(
    User user,
    String roomName,
  ) {
    if (_temporaryApiKey.isEmpty || _temporaryApiSecret.isEmpty) {
      throw const AppException(
        code: AppErrorCode.serviceUnavailable,
        userMessage:
            'Live spaces are temporarily unavailable. Please try again later.',
        retryable: true,
      );
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final isHostOrAdmin = canHostLiveSpace(user.email);
    final payload = <String, dynamic>{
      'exp': now + 3600,
      'nbf': now - 5,
      'iss': _temporaryApiKey,
      'sub': user.uid,
      'name': user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Student'),
      'video': {
        'room': roomName,
        'roomJoin': true,
        'canSubscribe': true,
        'canPublish': isHostOrAdmin,
        'canPublishData': isHostOrAdmin,
      },
    };
    String encode(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final unsigned =
        '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode(payload)}';
    final signature = base64Url
        .encode(Hmac(sha256, utf8.encode(_temporaryApiSecret))
            .convert(utf8.encode(unsigned))
            .bytes)
        .replaceAll('=', '');
    developer.log(
      'temporary_embedded_token roomName=$roomName identity=${user.uid} canPublish=$isHostOrAdmin ttl=3600',
      name: 'cie_daily.live_spaces',
    );
    return '$unsigned.$signature';
  }
}
