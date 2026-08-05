import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final engagementServiceProvider = Provider((ref) => EngagementService(Supabase.instance.client));

class EngagementService {
  final SupabaseClient _supabase;
  DateTime? _postStartTime;
  String? _currentPostId;

  EngagementService(this._supabase);

  void startTracking(String postId) {
    _postStartTime = DateTime.now();
    _currentPostId = postId;
  }

  Future<void> stopTrackingAndReport() async {
    if (_postStartTime == null || _currentPostId == null) return;

    final duration = DateTime.now().difference(_postStartTime!);
    final viewDurationSeconds = duration.inSeconds;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (viewDurationSeconds >= 2) {
      try {
        await _supabase.from('post_engagements').upsert({
          'post_id': _currentPostId,
          'user_id': userId,
          'view_duration_seconds': viewDurationSeconds,
          'last_viewed_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Silently fail for analytics
      }
    }

    _postStartTime = null;
    _currentPostId = null;
  }
}
