import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/models/post_model.dart';
import '../models/article_list.dart';

final articleListRepositoryProvider =
    Provider((ref) => ArticleListRepository());

class ArticleListRepository {
  ArticleListRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser?.uid ?? '';

  Stream<List<ArticleList>> watchMine() {
    if (_uid.isEmpty) return Stream.value(const []);
    return _firestore
        .collection('articleLists')
        .where('ownerUid', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      final lists = snapshot.docs.map(ArticleList.fromDoc).toList();
      lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return lists;
    });
  }

  Stream<ArticleList?> watchOne(String id) => _firestore
      .collection('articleLists')
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? ArticleList.fromDoc(doc) : null);

  Future<String> create(
      {required String title,
      String description = '',
      String? articleId}) async {
    if (_uid.isEmpty) throw StateError('Sign in to create a List.');
    final profile = await _firestore.collection('users').doc(_uid).get();
    final ownerName = profile.data()?['name']?.toString() ??
        _auth.currentUser?.displayName ??
        'Breakpoint reader';
    final doc = _firestore.collection('articleLists').doc();
    await doc.set({
      'ownerUid': _uid,
      'ownerName': ownerName,
      'title': title.trim(),
      'description': description.trim(),
      'articleIds': articleId == null ? <String>[] : [articleId],
      'isPublic': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> update(String id,
          {required String title, required String description}) =>
      _firestore.collection('articleLists').doc(id).update({
        'title': title.trim(),
        'description': description.trim(),
        'updatedAt': FieldValue.serverTimestamp()
      });
  Future<void> delete(String id) =>
      _firestore.collection('articleLists').doc(id).delete();
  Future<void> addArticle(String id, String articleId) =>
      _firestore.collection('articleLists').doc(id).update({
        'articleIds': FieldValue.arrayUnion([articleId]),
        'updatedAt': FieldValue.serverTimestamp()
      });
  Future<void> removeArticle(String id, String articleId) =>
      _firestore.collection('articleLists').doc(id).update({
        'articleIds': FieldValue.arrayRemove([articleId]),
        'updatedAt': FieldValue.serverTimestamp()
      });

  Future<List<PostModel>> fetchArticles(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final posts = <PostModel>[];
    for (var start = 0; start < ids.length; start += 10) {
      final chunk = ids.skip(start).take(10).toList();
      final snapshot = await _firestore
          .collection('posts')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        try {
          posts.add(PostModel.fromJson({...doc.data(), 'id': doc.id}));
        } catch (_) {}
      }
    }
    posts.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return posts;
  }
}
