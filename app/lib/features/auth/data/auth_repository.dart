import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/utils/role_utils.dart';
import '../../../core/errors/error_mapper.dart';
import '../../user/data/firebase_user_repository.dart';

final authRepositoryProvider = Provider(
    (ref) => AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance));

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._firebaseAuth, this._firestore);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      if (cred.user != null) {
        unawaited(FirebaseUserRepository(_firestore).ensureConnectionCode(cred.user!.uid));
      }
    } catch (error, stackTrace) {
      throw ErrorMapper.normalize(error, stackTrace: stackTrace);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      if (cred.user != null) {
        unawaited(FirebaseUserRepository(_firestore).ensureConnectionCode(cred.user!.uid));
      }
    } catch (error, stackTrace) {
      throw ErrorMapper.normalize(error, stackTrace: stackTrace);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '226102698550-fkcmj8it32dpfvqree9msc44vv57sfgj.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn().timeout(const Duration(seconds: 30));

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final cred = await _firebaseAuth
            .signInWithCredential(credential)
            .timeout(const Duration(seconds: 15));
        if (cred.user != null) {
          unawaited(FirebaseUserRepository(_firestore).ensureConnectionCode(cred.user!.uid));
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Google Sign-In failed');
      throw ErrorMapper.normalize(e, stackTrace: stackTrace);
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut().timeout(const Duration(seconds: 10));
    await GoogleSignIn().signOut().timeout(const Duration(seconds: 10));
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth
          .sendPasswordResetEmail(email: email)
          .timeout(const Duration(seconds: 15));
    } catch (error, stackTrace) {
      throw ErrorMapper.normalize(error, stackTrace: stackTrace);
    }
  }

  Future<bool> isAdmin(String email) async {
    return getUserRole(email) == UserRole.mainAdmin;
  }

  Future<bool> hasProfile(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .get()
        .timeout(const Duration(seconds: 10));
    return doc.exists;
  }
}
