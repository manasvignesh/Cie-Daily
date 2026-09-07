import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import 'dart:async';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticatedStudent,
  authenticatedAdmin,
  profileIncomplete,
  error
}

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthStatus>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthStatus> {
  final AuthRepository _repository;
  AppException? lastError;
  StreamSubscription<User?>? _authSubscription;
  int _authGeneration = 0;

  AuthController(this._repository) : super(AuthStatus.initial) {
    _checkInitialState();
    try {
      _authSubscription = _repository.authStateChanges.listen((user) {
        _handleAuthChange(user);
      }, onError: (err) {
        lastError = ErrorMapper.normalize(err);
        state = AuthStatus.error;
      });
    } catch (error, stackTrace) {
      lastError = ErrorMapper.normalize(error, stackTrace: stackTrace);
      state = AuthStatus.error;
    }
  }

  Future<void> _checkInitialState() async {
    try {
      final user = _repository.currentUser;
      await _handleAuthChange(user);
    } catch (error, stackTrace) {
      lastError = ErrorMapper.normalize(error, stackTrace: stackTrace);
      state = AuthStatus.error;
    }
  }

  Future<void> _handleAuthChange(User? user) async {
    final generation = ++_authGeneration;
    try {
      if (user == null) {
        lastError = null;
        state = AuthStatus.unauthenticated;
        return;
      }

      final email = user.email ?? '';

      // Let Firestore handle network delays and offline caching.
      final isAdmin = await _repository.isAdmin(email);
      if (generation != _authGeneration) return;

      if (isAdmin) {
        lastError = null;
        state = AuthStatus.authenticatedAdmin;
        return;
      }

      final hasProfile = await _repository.hasProfile(user.uid);
      if (generation != _authGeneration) return;

      if (!hasProfile) {
        lastError = null;
        state = AuthStatus.profileIncomplete;
      } else {
        lastError = null;
        state = AuthStatus.authenticatedStudent;
      }
    } catch (error, stackTrace) {
      lastError = ErrorMapper.normalize(error, stackTrace: stackTrace);
      state = AuthStatus.error;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _repository.signInWithEmailAndPassword(email, password);
    final user = _repository.currentUser;
    if (user != null) {
      await _handleAuthChange(user);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    await _repository.signUpWithEmailAndPassword(email, password);
    final user = _repository.currentUser;
    if (user != null) {
      await _handleAuthChange(user);
    }
  }

  Future<void> signInWithGoogle() async {
    await _repository.signInWithGoogle();
    final user = _repository.currentUser;
    if (user != null) {
      await _handleAuthChange(user);
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _repository.sendPasswordResetEmail(email);
  }

  Future<void> retryInitialization() async {
    state = AuthStatus.initial;
    await _checkInitialState();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
