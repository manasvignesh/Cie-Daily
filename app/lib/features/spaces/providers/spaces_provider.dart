import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/live_stream_model.dart';

final liveStreamsProvider = StreamProvider.autoDispose<List<LiveStreamModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('liveStreams')
      // .where('status', isEqualTo: 'live') // TEMPORARILY DISABLED FOR TESTING
      .snapshots()
      .map((snapshot) {
    final streams = snapshot.docs.map((doc) {
      return LiveStreamModel.fromMap(doc.data(), doc.id);
    }).toList();
    
    // Sort locally to avoid needing a Firestore composite index
    streams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return streams;
  });
});
