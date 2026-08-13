import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';

final pendingRequestsProvider = StreamProvider.autoDispose<List<ConnectionRequestModel>>((ref) async* {
  final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
  if (user == null) {
    yield [];
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('connection_requests')
      .where('receiverId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => ConnectionRequestModel.fromMap(doc.data(), doc.id)).toList();
      });
});

final conversationsProvider = StreamProvider.autoDispose<List<ConversationModel>>((ref) async* {
  final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
  if (user == null) {
    yield [];
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('conversations')
      .where('participants', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs.map((doc) => ConversationModel.fromMap(doc.data(), doc.id)).toList();
        list.sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));
        return list;
      });
});

final chatMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessageModel>, String>((ref, conversationId) async* {
  yield* FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id)).toList();
      });
});
