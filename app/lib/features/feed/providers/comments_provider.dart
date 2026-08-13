import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';

final commentsProvider = StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  return FirebaseFirestore.instance
      .collection('comments')
      .where('parentId', isEqualTo: postId)
      .snapshots()
      .map((snapshot) {
        final comments = snapshot.docs.map((doc) {
          return CommentModel.fromMap(doc.data(), doc.id);
        }).toList();
        
        comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          authorName = userDoc.data()?['name'] ?? 'Anonymous';
          authorAvatar = userDoc.data()?['photoUrl'] ?? userDoc.data()?['avatarUrl'];
        }
      } catch (e) {
        // ignore
      }
    }

    await FirebaseFirestore.instance.collection('comments').add({
      'parentId': postId,
      'authorId': user.uid,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content.trim(),
      'likesCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Optionally increment comment count on post
    // Wrapped in try-catch because Firestore rules might deny users from updating posts they don't own.
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Could not update commentsCount: $e');
    }
  }
}
