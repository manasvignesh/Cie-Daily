import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../domain/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => FirebaseNotificationRepository(
  FirebaseFirestore.instance,
  FirebaseAuth.instance,
));

class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseNotificationRepository(this._firestore, this._auth);

  @override
  Stream<List<NotificationModel>> streamNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        } else if (data['createdAt'] == null) {
          data['createdAt'] = DateTime.now().toIso8601String();
        }
        return NotificationModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
