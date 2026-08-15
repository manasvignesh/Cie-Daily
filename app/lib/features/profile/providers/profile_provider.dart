import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userProfileProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) async* {
  final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
  
  yield* FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .snapshots()
      .map((snap) => snap.data());
});

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
          return PostModel.fromJson({...data, 'id': doc.id});
        }).toList();
      });
});

final likedPostsProvider = StreamProvider.autoDispose<List<PostModel>>((ref) async* {
  final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
  
  yield* FirebaseFirestore.instance
      .collection('posts')
      .where('likedBy', arrayContains: user!.uid)
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          final likedBy = List<String>.from(data['likedBy'] ?? []);
          final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? []);
          data['isLikedByCurrentUser'] = likedBy.contains(user.uid);
          data['isBookmarkedByCurrentUser'] = bookmarkedBy.contains(user.uid);
          return PostModel.fromJson({...data, 'id': doc.id});
        }).toList();
      });
});

final userPostsProvider = StreamProvider.autoDispose<List<PostModel>>((ref) async* {
  final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
  
  yield* FirebaseFirestore.instance
      .collection('posts')
      .where('authorId', isEqualTo: user!.uid)
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map((snapshot) {
        final posts = snapshot.docs.map((doc) {
          final data = doc.data();
          final likedBy = List<String>.from(data['likedBy'] ?? []);
          final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? []);
          data['isLikedByCurrentUser'] = likedBy.contains(user.uid);
          data['isBookmarkedByCurrentUser'] = bookmarkedBy.contains(user.uid);
          return PostModel.fromJson({...data, 'id': doc.id});
        }).toList();
        
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return posts;
      });
});
