import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cie_connect/core/errors/app_exception.dart';
import 'package:cie_connect/core/errors/error_mapper.dart';

void main() {
  group('ErrorMapper', () {
    test('hides invalid credential implementation details', () {
      final result = ErrorMapper.normalize(
        FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Firebase: auth/invalid-credential',
        ),
      );

      expect(result.code, AppErrorCode.invalidCredentials);
      expect(
        result.userMessage,
        'The email or password you entered is incorrect.',
      );
      expect(result.userMessage, isNot(contains('Firebase')));
      expect(result.userMessage, isNot(contains('auth/')));
    });

    test('does not reveal whether a login account exists', () {
      final result = ErrorMapper.normalize(
        FirebaseAuthException(code: 'user-not-found'),
      );

      expect(result.code, AppErrorCode.invalidCredentials);
      expect(
        result.userMessage,
        'The email or password you entered is incorrect.',
      );
    });

    test('maps duplicate signup and weak password safely', () {
      final duplicate = ErrorMapper.normalize(
        FirebaseAuthException(code: 'email-already-in-use'),
      );
      final weak = ErrorMapper.normalize(
        FirebaseAuthException(code: 'weak-password'),
      );

      expect(duplicate.code, AppErrorCode.emailAlreadyExists);
      expect(duplicate.userMessage, isNot(contains('email-already-in-use')));
      expect(weak.code, AppErrorCode.weakPassword);
      expect(weak.userMessage, isNot(contains('weak-password')));
    });

    test('marks auth throttling as retryable without leaking provider codes',
        () {
      final result = ErrorMapper.normalize(
        FirebaseAuthException(code: 'too-many-requests'),
      );

      expect(result.code, AppErrorCode.rateLimited);
      expect(result.retryable, isTrue);
      expect(result.userMessage, isNot(contains('too-many-requests')));
    });

    test('maps permission denied to a safe message', () {
      final result = ErrorMapper.normalize(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        ),
      );

      expect(result.code, AppErrorCode.forbidden);
      expect(result.userMessage,
          "You don't have permission to perform this action.");
      expect(result.userMessage, isNot(contains('Firestore')));
    });

    test('unknown errors use a stable product message', () {
      final result = ErrorMapper.normalize(
        StateError('internal_database_table_name'),
      );

      expect(result.code, AppErrorCode.unknown);
      expect(result.retryable, isTrue);
      expect(result.userMessage, isNot(contains('internal_database')));
    });
  });
}
