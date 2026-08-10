import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/models/post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final discoverArticlesProvider = StreamProvider.autoDispose<List<PostModel>>((ref) async* {
  // Wait for auth to be ready to avoid permission denied on startup
  final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
  
  yield* FirebaseFirestore.instance
      .collection('posts')
      .where('category', isEqualTo: 'Article')
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map((snapshot) {
        final posts = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final likedBy = List<String>.from(data['likedBy'] ?? []);
            final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? []);
            data['isLikedByCurrentUser'] = user?.uid != null && likedBy.contains(user!.uid);
            data['isBookmarkedByCurrentUser'] = user?.uid != null && bookmarkedBy.contains(user!.uid);
            return PostModel.fromMap(data, doc.id);
          })
          .toList();
        
        // Sort client-side to avoid composite index requirement
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return posts;
      });
});
