import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirebaseUserRepository(FirebaseFirestore.instance);
});

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserRepository(this._firestore);

  static String generateConnectionCode(String name) {
    final prefix = name.trim().split(' ').first.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final cleanPrefix = prefix.isNotEmpty ? prefix : 'STUDENT';
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rnd = math.Random();
    final codeSuffix = String.fromCharCodes(Iterable.generate(5, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return '$cleanPrefix-$codeSuffix';
  }

  @override
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String department,
    required int yearOfStudy,
  }) async {
    final code = generateConnectionCode(fullName);
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'name': fullName,
      'department': department,
      'yearOfStudy': yearOfStudy,
      'connectionCode': code,
      'autoAcceptRequests': false,
      'blockedUserIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data != null && (data['connectionCode'] == null || (data['connectionCode'] as String).isEmpty)) {
      final code = generateConnectionCode(data['name'] ?? 'Student');
      await _firestore.collection('users').doc(uid).update({'connectionCode': code});
      data['connectionCode'] = code;
    }
    return data;
  }
}
