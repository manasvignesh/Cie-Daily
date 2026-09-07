import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

final _userCache = <String, Map<String, dynamic>>{};

final feedProvider = StreamProvider.autoDispose<List<PostModel>>((ref) async* {
  final user = await FirebaseAuth.instance
      .authStateChanges()
      .firstWhere((u) => u != null);

  yield* FirebaseFirestore.instance
      .collection('posts')
      .where('category', isEqualTo: 'Reel')
      .where('status', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .limit(50) // Cap to recent 50 for now for real-time stream
      .snapshots()
      .asyncMap((snapshot) async {
    final authorIds = snapshot.docs
        .map((doc) => doc.data()['authorId'] as String?)
        .whereType<String>()
        .where((id) => !_userCache.containsKey(id))
        .toSet();

    if (authorIds.isNotEmpty) {
      try {
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: authorIds.toList())
            .get();
        for (var uDoc in usersSnap.docs) {
          _userCache[uDoc.id] = uDoc.data();
        }
        while (_userCache.length > 200) {
          _userCache.remove(_userCache.keys.first);
        }
      } catch (_) {}
    }

    final posts = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      final authorId = data['authorId'] as String?;

      if (authorId != null && _userCache.containsKey(authorId)) {
        final uData = _userCache[authorId]!;
        final name = uData['name'] ?? uData['fullName'] ?? 'Student';
        final photo = uData['photoUrl'] ?? uData['avatarUrl'];
        data['authorName'] = name;
        data['author'] = {
          'name': name,
          'fullName': name,
          'avatarUrl': photo,
          'email': uData['email'],
        };
        if (photo != null) data['authorAvatar'] = photo;
      } else if (data['authorName'] == null ||
          data['authorName'] == 'Anonymous') {
        if (authorId == user?.uid) {
          data['authorName'] =
              user?.displayName ?? user?.email?.split('@').first ?? 'Student';
        }
      }

      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? []);
      data['isLikedByCurrentUser'] =
          user?.uid != null && likedBy.contains(user!.uid);
      data['isBookmarkedByCurrentUser'] =
          user?.uid != null && bookmarkedBy.contains(user!.uid);
      return PostModel.fromMap(data, doc.id);
    }).toList();

    return posts;
  });
});
