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
      final user = _repository.currentUser;
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
      
      // Let Firestore handle network delays and offline caching.
      final isAdmin = await _repository.isAdmin(email);

      if (isAdmin) {
        state = AuthStatus.authenticatedAdmin;
        return;
      }

      final hasProfile = await _repository.hasProfile(user.uid);
      
      if (!hasProfile) {
        state = AuthStatus.profileIncomplete;
      } else {
        state = AuthStatus.authenticatedStudent;
      }
    } catch (e) {
      // If user is non-null, default to authenticatedStudent so user enters app seamlessly
      state = AuthStatus.authenticatedStudent;
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
}
