import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository(Supabase.instance.client));

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository(this._supabase);

  Stream<List<NotificationModel>> streamNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => NotificationModel.fromJson(e)).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
}
