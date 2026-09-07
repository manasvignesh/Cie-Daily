import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/live_stream_model.dart';

final liveStreamsProvider =
    StreamProvider.autoDispose<List<LiveStreamModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('liveStreams')
      .where('status', isEqualTo: 'live')
      .limit(50)
      .snapshots()
      .map((snapshot) {
    final streams = snapshot.docs
        .map((doc) {
          try {
            return LiveStreamModel.fromMap(doc.data(), doc.id);
          } catch (_) {
            return null;
          }
        })
        .whereType<LiveStreamModel>()
        .toList();

    // Sort locally to avoid needing a Firestore composite index
    streams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return streams;
  });
});
