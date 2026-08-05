import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository.dart';
import '../models/notification_model.dart';

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.streamNotifications();
});
