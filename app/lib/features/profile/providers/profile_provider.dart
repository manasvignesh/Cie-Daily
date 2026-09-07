import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/models/post_model.dart';

final userProfileProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.data());
});

final bookmarkedPostsProvider =
    StreamProvider.autoDispose<List<PostModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(const <PostModel>[]);

  return FirebaseFirestore.instance
      .collection('posts')
      .where('bookmarkedBy', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) {
    final posts = snapshot.docs
        .map((doc) => _safePost(doc, user.uid))
        .whereType<PostModel>()
        .toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  });
});

final likedPostsProvider = StreamProvider.autoDispose<List<PostModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(const <PostModel>[]);

  return FirebaseFirestore.instance
      .collection('posts')
      .where('likedBy', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) {
    final posts = snapshot.docs
        .map((doc) => _safePost(doc, user.uid))
        .whereType<PostModel>()
        .toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  });
});

final userPostsProvider = StreamProvider.autoDispose<List<PostModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(const <PostModel>[]);

  return FirebaseFirestore.instance
      .collection('posts')
      .where('authorId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
    final posts = snapshot.docs
        .map((doc) => _safePost(doc, user.uid))
        .whereType<PostModel>()
        .toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  });
});

PostModel? _safePost(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
  String userId,
) {
  try {
    final data = Map<String, dynamic>.from(doc.data());
    final status = data['status'] as String?;
    if (status != null && status != 'approved') return null;

    final likedBy = List<String>.from(data['likedBy'] ?? const []);
    final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? const []);
    data['isLikedByCurrentUser'] = likedBy.contains(userId);
    data['isBookmarkedByCurrentUser'] = bookmarkedBy.contains(userId);
    return PostModel.fromJson({...data, 'id': doc.id});
  } on Object {
    return null;
  }
}
