import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';

final commentsProvider = StreamProvider.autoDispose
    .family<List<CommentModel>, String>((ref, postId) {
  return FirebaseFirestore.instance
      .collection('comments')
      .where('parentId', isEqualTo: postId)
      .orderBy('createdAt')
      .limit(100)
      .snapshots()
      .map((snapshot) {
    final comments = snapshot.docs.map((doc) {
      return CommentModel.fromMap(doc.data(), doc.id);
    }).toList();

        return comments;
  });
});

final addCommentProvider = Provider((ref) => AddCommentService());

class AddCommentService {
  Future<void> addComment(String postId, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || content.trim().isEmpty) return;

    String authorName = user.displayName ?? 'Anonymous';
    String? authorAvatar = user.photoURL;

    // Fallback if not available in FirebaseAuth
    if (authorName == 'Anonymous') {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          authorName = userDoc.data()?['name'] ?? 'Anonymous';
          authorAvatar =
              userDoc.data()?['photoUrl'] ?? userDoc.data()?['avatarUrl'];
        }
      } catch (e) {
        // ignore
      }
    }

    final firestore = FirebaseFirestore.instance;
    final commentRef = firestore.collection('comments').doc();
    final postRef = firestore.collection('posts').doc(postId);
    await firestore.runTransaction((transaction) async {
      final post = await transaction.get(postRef);
      if (!post.exists) throw StateError('Post no longer exists');
      final currentCount = post.data()?['commentsCount'] as num? ?? 0;
      transaction.set(commentRef, {
        'parentId': postId,
        'authorId': user.uid,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'content': content.trim(),
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {'commentsCount': currentCount + 1});
    }).timeout(const Duration(seconds: 10));
  }
}
