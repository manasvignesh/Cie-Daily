import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(Supabase.instance.client));

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signInWithEmail(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  Future<AuthResponse> verifyOtp(String email, String token) async {
    return await _supabase.auth.verifyOTP(
      type: OtpType.magiclink, // or OtpType.signup/email depending on strict OTP behavior
      token: token,
      email: email,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<bool> isAdmin(String email) async {
    try {
      final response = await _supabase
          .from('admin_users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }
}
