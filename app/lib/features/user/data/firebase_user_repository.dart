import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirebaseUserRepository(FirebaseFirestore.instance);
});

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserRepository(this._firestore);

  @override
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String department,
    required int yearOfStudy,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'name': fullName,
      'department': department,
      'yearOfStudy': yearOfStudy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }
}
