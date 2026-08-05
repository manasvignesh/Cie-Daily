import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_repository.dart';
import '../models/chat_models.dart';

final inboxProvider = StreamProvider<List<ConversationModel>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamConversations();
});

final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamMessages(conversationId);
});
