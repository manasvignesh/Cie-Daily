import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/feed_repository.dart';
import '../data/firebase_feed_repository.dart';
import '../models/post_model.dart';
import '../../auth/providers/auth_provider.dart';

final feedProvider = StreamProvider.autoDispose<List<PostModel>>((ref) async* {
  final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
  
  yield* FirebaseFirestore.instance
      .collection('posts')
      .where('category', isEqualTo: 'Reel')
      .where('status', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .limit(50) // Cap to recent 50 for now for real-time stream
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
        
        return posts;
      });
});
