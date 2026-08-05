import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository(Supabase.instance.client));

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  Stream<List<ConversationModel>> streamConversations() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    // In a real scenario, this involves a join or a view, but for Milestone 5 structure:
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('updated_at')
        .map((data) => data.map((e) => ConversationModel.fromJson(e)).toList());
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) => data.map((e) => MessageModel.fromJson(e)).toList());
  }

  Future<void> sendMessage(String conversationId, String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'content': content,
    });
    
    // Update conversation last updated
    await _supabase.from('conversations').update({
      'last_message': content,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }
}
