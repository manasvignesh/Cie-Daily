import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/models/post_model.dart';

final pendingPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) {
            try {
              return PostModel.fromMap(doc.data(), doc.id);
            } catch (_) {
              return null;
            }
          })
          .whereType<PostModel>()
          .toList());
});

final moderationActionProvider = Provider((ref) => ModerationActionService());

class ModerationActionService {
  Future<void> approvePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectPost(String postId, String reason) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
