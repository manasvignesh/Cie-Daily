import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final engagementServiceProvider = Provider((ref) => EngagementService(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    ));

class EngagementService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  DateTime? _postStartTime;
  String? _currentPostId;

  EngagementService(this._firestore, this._auth);

  void startTracking(String postId) {
    _postStartTime = DateTime.now();
    _currentPostId = postId;
  }

  Future<void> stopTrackingAndReport() async {
    if (_postStartTime == null || _currentPostId == null) return;

    final duration = DateTime.now().difference(_postStartTime!);
    final viewDurationSeconds = duration.inSeconds;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (viewDurationSeconds >= 2) {
      try {
        final docId = '${userId}_$_currentPostId';
        await _firestore.collection('postEngagements').doc(docId).set({
          'postId': _currentPostId,
          'userId': userId,
          'viewDurationSeconds': viewDurationSeconds,
          'lastViewedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Silently fail for analytics
      }
    }

    _postStartTime = null;
    _currentPostId = null;
  }
}
