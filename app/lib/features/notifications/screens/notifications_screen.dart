import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notifications_provider.dart';
import '../data/firebase_notification_repository.dart';
import '../../../core/widgets/indicators/loading_skeleton.dart';
import '../../../core/widgets/indicators/error_state.dart';
import '../../../core/theme/app_theme.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notificationsState.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('You are all caught up!'));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Container(
                decoration: BoxDecoration(
                  color: notif.isRead
                      ? Colors.transparent
                      : AppTheme.primaryOrange.withValues(alpha: 0.05),
                  border: Border(
                      left: BorderSide(
                          color: notif.isRead
                              ? Colors.transparent
                              : AppTheme.primaryOrange,
                          width: 4)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading:
                      notif.actorAvatar != null && notif.actorAvatar!.isNotEmpty
                          ? CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(notif.actorAvatar!),
                            )
                          : Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: notif.isRead
                                    ? AppTheme.surfaceMutedColor(context)
                                    : AppTheme.primaryOrange
                                        .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIcon(notif.type),
                                color: notif.isRead
                                    ? Colors.grey[500]
                                    : AppTheme.primaryOrange,
                                size: 20,
                              ),
                            ),
                  title: Text(
                    notif.title,
                    style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontWeight:
                          notif.isRead ? FontWeight.w500 : FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      notif.body,
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor(context),
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  onTap: () async {
                    if (!notif.isRead) {
                      try {
                        await ref
                            .read(notificationRepositoryProvider)
                            .markAsRead(notif.id);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "We couldn't mark this update as read."),
                            ),
                          );
                        }
                      }
                    }
                    if (!context.mounted) return;
                    final destination = NotificationDestination.fromData({
                      'type': notif.contentType ?? notif.type,
                      'contentId': notif.contentId,
                    });
                    if (destination != null) {
                      context.push(destination.route);
                    } else if (notif.actorId?.isNotEmpty == true) {
                      context.push('/profile/${notif.actorId}');
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          itemCount: 8,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                LoadingSkeleton(width: 40, height: 40, borderRadius: 20),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(width: 200, height: 16),
                      SizedBox(height: 8),
                      LoadingSkeleton(width: 120, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => ErrorState(
          message: "We couldn't load notifications. Please try again.",
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'drop':
        return Icons.local_fire_department_rounded;
      case 'space':
        return Icons.mic_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
