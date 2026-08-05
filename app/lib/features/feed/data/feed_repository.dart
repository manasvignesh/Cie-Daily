import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';

final feedRepositoryProvider = Provider((ref) => FeedRepository(Supabase.instance.client));

class FeedRepository {
  final SupabaseClient _supabase;

  FeedRepository(this._supabase);

  Future<List<PostModel>> fetchPosts({int offset = 0, int limit = 10}) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            author:author_id (full_name, avatar_url)
          ''')
          .eq('is_published', true)
          // Algorithmic Sorting: Orders by engagement_score (calculated via RPC/View in DB)
          .order('engagement_score', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
          
      return (response as List).map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load feed: $e');
    }
  }

  Future<void> toggleLike(String postId, bool isLiked) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (isLiked) {
      await _supabase.from('post_reactions').insert({
        'post_id': postId,
        'user_id': userId,
        'reaction_type': 'like'
      });
    } else {
      await _supabase.from('post_reactions')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    }
  }
}
