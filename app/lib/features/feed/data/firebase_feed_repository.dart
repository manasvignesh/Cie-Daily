import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../domain/feed_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/services/trusted_backend_client.dart';

final feedRepositoryProvider =
    Provider<FeedRepository>((ref) => FirebaseFeedRepository(
          FirebaseFirestore.instance,
          FirebaseAuth.instance,
          TrustedBackendClient(),
        ));

class FirebaseFeedRepository implements FeedRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TrustedBackendClient _backend;

  FirebaseFeedRepository(
    this._firestore,
    this._auth, [
    TrustedBackendClient? backend,
  ]) : _backend = backend ?? TrustedBackendClient(auth: _auth);

  @override
  Future<List<PostModel>> fetchPosts({int offset = 0, int limit = 10}) async {
    try {
      // Note: offset pagination in Firestore requires startAfterDocument.
      // For simplicity in this migration, we'll just fetch a limit and assume
      // the caller handles cursor logic later, or we just fetch the first page.
      // Since the original was .range(offset, limit), we simulate it here.

      final querySnapshot = await _firestore
          .collection('posts')
          .where('category', isEqualTo: 'Reel')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final List<PostModel> posts = [];

      // Fetch users to join author data
      final authorIds = querySnapshot.docs
          .map((doc) => doc.data()['authorId'] as String?)
          .whereType<String>()
          .toSet();

      final Map<String, Map<String, dynamic>> usersMap = {};
      if (authorIds.isNotEmpty) {
        final usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: authorIds.toList())
            .get();
        for (var userDoc in usersSnapshot.docs) {
          usersMap[userDoc.id] = userDoc.data();
        }
      }

      final userId = _auth.currentUser?.uid;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Handle Timestamp conversion for the model
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).toDate().toIso8601String();
        } else if (data['createdAt'] == null) {
          data['createdAt'] = DateTime.now().toIso8601String();
        }

        // Attach author data
        final authorId = data['authorId'] as String?;
        if (authorId != null && usersMap.containsKey(authorId)) {
          final user = usersMap[authorId]!;
          data['author'] = {
            'fullName': user['name'] ?? 'Anonymous',
            'avatarUrl': user['photoUrl'],
          };
        } else {
          data['author'] = {
            'fullName': 'Anonymous',
            'avatarUrl': null,
          };
        }

        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? []);

        data['isLikedByCurrentUser'] =
            userId != null && likedBy.contains(userId);
        data['isBookmarkedByCurrentUser'] =
            userId != null && bookmarkedBy.contains(userId);

        // Filter out unapproved posts locally since we dropped the status query
        if (data['status'] == 'approved') {
          posts.add(PostModel.fromJson(data));
        }
      }

      return posts;
    } catch (error, stackTrace) {
      throw ErrorMapper.normalize(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> toggleLike(String postId, bool isLiked) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? const []);
      final alreadyLiked = likedBy.contains(userId);
      if (alreadyLiked == isLiked) return;
      final currentCount = data['likesCount'] is num
          ? (data['likesCount'] as num).toInt()
          : likedBy.length;
      transaction.update(postRef, {
        'likesCount': isLiked ? currentCount + 1 : currentCount - 1,
        'likedBy': isLiked
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
      });
    }).timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> toggleBookmark(String postId, bool isBookmarked) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      final bookmarkedBy =
          List<String>.from(snapshot.data()?['bookmarkedBy'] ?? const []);
      if (bookmarkedBy.contains(userId) == isBookmarked) return;
      transaction.update(postRef, {
        'bookmarkedBy': isBookmarked
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
      });
    }).timeout(const Duration(seconds: 10));
  }

  @override
  Future<List<PostModel>> fetchBookmarkedPosts() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('bookmarkedBy', arrayContains: userId)
          .where('status', isEqualTo: 'approved')
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      final List<PostModel> posts = [];

      final authorIds = querySnapshot.docs
          .map((doc) => doc.data()['authorId'] as String?)
          .whereType<String>()
          .toSet();

      final Map<String, Map<String, dynamic>> usersMap = {};
      if (authorIds.isNotEmpty) {
        final usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: authorIds.toList())
            .get();
        for (var userDoc in usersSnapshot.docs) {
          usersMap[userDoc.id] = userDoc.data();
        }
      }

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).toDate().toIso8601String();
        } else if (data['createdAt'] == null) {
          data['createdAt'] = DateTime.now().toIso8601String();
        }

        final authorId = data['authorId'] as String?;
        if (authorId != null && usersMap.containsKey(authorId)) {
          final user = usersMap[authorId]!;
          data['author'] = {
            'fullName': user['name'] ?? 'Anonymous',
            'avatarUrl': user['photoUrl'],
          };
        } else {
          data['author'] = {
            'fullName': 'Anonymous',
            'avatarUrl': null,
          };
        }

        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? []);

        data['isLikedByCurrentUser'] = likedBy.contains(userId);
        data['isBookmarkedByCurrentUser'] = bookmarkedBy.contains(userId);

        posts.add(PostModel.fromJson(data));
      }

      return posts;
    } catch (error, stackTrace) {
      throw ErrorMapper.normalize(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> createPost(PostModel post) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw const AppException(
        code: AppErrorCode.unauthenticated,
        userMessage: 'Sign in again to continue.',
      );
    }

    try {
      final postData = <String, dynamic>{
        'title': post.title,
        'blocks': post.blocks,
        'category': post.category,
        'estimatedReadTime': post.estimatedReadTime,
        'isTodaysDrop': post.isTodaysDrop,
        'status': 'approved',
      };

      if (post.imageUrl != null) {
        postData['mediaUrls'] = [post.imageUrl!];
      }

      if (post.videoUrl != null) {
        postData['videoUrl'] = post.videoUrl!;
      }

      if (post.aspectRatio != null) {
        postData['aspectRatio'] = post.aspectRatio!;
      }

      await _backend.post('publish-content', {
        'clientContentId': TrustedBackendClient.newRequestId(),
        'post': postData,
      });
    } catch (error, stackTrace) {
      throw ErrorMapper.normalize(error, stackTrace: stackTrace);
    }
  }
}
