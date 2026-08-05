import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

enum AuthStatus { initial, unauthenticated, authenticatedStudent, authenticatedAdmin, profileIncomplete }

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthStatus>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthStatus> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(AuthStatus.initial) {
    _checkInitialState();
    _repository.authStateChanges.listen((data) {
      _handleAuthChange(data.session?.user);
    });
  }

  Future<void> _checkInitialState() async {
    final user = _repository.currentUser;
    await _handleAuthChange(user);
  }

  Future<void> _handleAuthChange(User? user) async {
    if (user == null) {
      state = AuthStatus.unauthenticated;
      return;
    }

    final email = user.email ?? '';
    final isAdmin = await _repository.isAdmin(email);

    if (isAdmin) {
      state = AuthStatus.authenticatedAdmin;
      return;
    }

    final hasProfile = await _repository.hasProfile(user.id);
    if (!hasProfile) {
      state = AuthStatus.profileIncomplete;
    } else {
      state = AuthStatus.authenticatedStudent;
    }
  }

  Future<void> sendOtp(String email) async {
    await _repository.signInWithEmail(email);
  }

  Future<void> verifyOtp(String email, String otp) async {
    await _repository.verifyOtp(email, otp);
  }

  Future<void> logout() async {
    await _repository.signOut();
  }
}
