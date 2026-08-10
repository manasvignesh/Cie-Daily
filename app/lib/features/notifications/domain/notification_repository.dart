import '../models/notification_model.dart';

abstract interface class NotificationRepository {
  Stream<List<NotificationModel>> streamNotifications();
  Future<void> markAsRead(String notificationId);
}
