import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/models/post_model.dart';
import '../models/article_chronology.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _transientFirestoreCodes = <String>{
  'aborted',
  'cancelled',
  'deadline-exceeded',
  'resource-exhausted',
  'unavailable',
};

List<PostModel> _parseDiscoverArticles(
  QuerySnapshot<Map<String, dynamic>> snapshot,
  String userId, {
  bool requireApprovedStatus = false,
}) {
  final posts = <PostModel>[];
  for (final doc in snapshot.docs) {
    try {
      final data = Map<String, dynamic>.from(doc.data());
      if (requireApprovedStatus &&
          data['status'] != 'approved' &&
          data['status'] != 'published') {
        continue;
      }

      final likedBy = List<String>.from(data['likedBy'] ?? const []);
      final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? const []);
      data['isLikedByCurrentUser'] = likedBy.contains(userId);
      data['isBookmarkedByCurrentUser'] = bookmarkedBy.contains(userId);
      final post = PostModel.fromMap(data, doc.id);
      if (post.schemaVersion >= 2 || post.category == 'Article') {
        posts.add(post);
      }
    } on Object {
      // One malformed producer document must not hide every published story.
    }
  }
  return sortArticlesNewestFirst(posts);
}

Stream<List<PostModel>> _discoverStream(String userId) async* {
  final posts = FirebaseFirestore.instance.collection('posts');
  final primaryQuery = posts
      .where('status', whereIn: const ['approved', 'published']);

  var retryCount = 0;
  while (true) {
    try {
      await for (final snapshot in primaryQuery.snapshots()) {
        retryCount = 0;
        yield _parseDiscoverArticles(snapshot, userId);
      }
      return;
    } on FirebaseException catch (error) {
      // Older/new Firebase projects may briefly lack the compound index. The
      // single-field query keeps Discover usable while that index is prepared.
      if (error.code == 'failed-precondition') {
        yield* posts.snapshots()
            .map((snapshot) => _parseDiscoverArticles(
                  snapshot,
                  userId,
                  requireApprovedStatus: true,
                ));
        return;
      }

      if (!_transientFirestoreCodes.contains(error.code) || retryCount >= 3) {
        rethrow;
      }
      retryCount++;
      await Future<void>.delayed(Duration(seconds: retryCount));
    }
  }
}

final discoverArticlesProvider =
    StreamProvider.autoDispose<List<PostModel>>((ref) async* {
  // Prefer the already-restored session, but wait for Firebase Auth during a
  // cold start so Firestore never races an unauthenticated request.
  final user = FirebaseAuth.instance.currentUser ??
      await FirebaseAuth.instance.authStateChanges().firstWhere(
            (candidate) => candidate != null,
          );
  yield* _discoverStream(user!.uid);
});

final discoverArticleByIdProvider =
    StreamProvider.autoDispose.family<PostModel?, String>((ref, articleId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .doc(articleId)
      .snapshots(includeMetadataChanges: true)
      .map((doc) {
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final likedBy = List<String>.from(data['likedBy'] ?? const []);
    final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? const []);
    data['isLikedByCurrentUser'] = userId != null && likedBy.contains(userId);
    data['isBookmarkedByCurrentUser'] =
        userId != null && bookmarkedBy.contains(userId);
    return PostModel.fromMap(data, doc.id);
  });
});
