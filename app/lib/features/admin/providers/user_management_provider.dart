import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList());
});

final userManagementProvider = Provider((ref) => UserManagementService());

class UserManagementService {
  Future<void> updateRole(String userId, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> banUser(String userId, bool isBanned) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBanned': isBanned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
