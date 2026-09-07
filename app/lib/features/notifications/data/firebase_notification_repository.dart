import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../domain/notification_repository.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => FirebaseNotificationRepository(
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
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final notifications = <NotificationModel>[];
      for (final doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] =
                (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          notifications.add(NotificationModel.fromJson(data));
        } on FormatException {
          // One malformed legacy record must not make the inbox unusable.
        } on TypeError {
          // Invalid server data is isolated; diagnostics remain provider-side.
        }
      }
      return notifications;
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
