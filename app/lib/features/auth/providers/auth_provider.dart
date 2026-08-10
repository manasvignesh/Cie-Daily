import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';

enum AuthStatus { initial, unauthenticated, authenticatedStudent, authenticatedAdmin, profileIncomplete }

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthStatus>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthStatus> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(AuthStatus.initial) {
    _checkInitialState();
    try {
      _repository.authStateChanges.listen((user) {
        _handleAuthChange(user);
      }, onError: (err) {
        state = AuthStatus.unauthenticated;
      });
    } catch (_) {
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> _checkInitialState() async {
    try {
      // Give a maximum of 2 seconds for initial auth check before falling back
      final user = await Future<User?>.value(_repository.currentUser).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      await _handleAuthChange(user);
    } catch (e) {
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> _handleAuthChange(User? user) async {
    try {
      if (user == null) {
        state = AuthStatus.unauthenticated;
        return;
      }

      final email = user.email ?? '';
      final isAdmin = await _repository.isAdmin(email).timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );

      if (isAdmin) {
        state = AuthStatus.authenticatedAdmin;
        return;
      }

      final hasProfile = await _repository.hasProfile(user.uid).timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (!hasProfile) {
        state = AuthStatus.profileIncomplete;
      } else {
        state = AuthStatus.authenticatedStudent;
      }
    } catch (e) {
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _repository.signInWithEmailAndPassword(email, password);
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    await _repository.signUpWithEmailAndPassword(email, password);
  }

  Future<void> signInWithGoogle() async {
    await _repository.signInWithGoogle();
  }

  Future<void> logout() async {
    await _repository.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _repository.sendPasswordResetEmail(email);
  }
}
