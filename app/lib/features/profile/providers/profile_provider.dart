import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/data/firebase_feed_repository.dart';
import '../../feed/models/post_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final bookmarkedPostsProvider = StreamProvider.autoDispose<List<PostModel>>((ref) async* {
  final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
  
  yield* FirebaseFirestore.instance
      .collection('posts')
      .where('bookmarkedBy', arrayContains: user!.uid)
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          final likedBy = List<String>.from(data['likedBy'] ?? []);
          final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? []);
          data['isLikedByCurrentUser'] = likedBy.contains(user.uid);
          data['isBookmarkedByCurrentUser'] = bookmarkedBy.contains(user.uid);
          return PostModel.fromMap(data, doc.id);
        }).toList();
      });
});
