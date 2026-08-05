import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';
import '../data/notification_repository.dart';
import '../../../core/widgets/indicators/loading_skeleton.dart';

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
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: notif.isRead ? Colors.grey.withOpacity(0.2) : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: Icon(
                    _getIcon(notif.type),
                    color: notif.isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Text(notif.body),
                onTap: () {
                  if (!notif.isRead) {
                    ref.read(notificationRepositoryProvider).markAsRead(notif.id);
                  }
                },
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
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'drop': return Icons.local_fire_department_rounded;
      case 'space': return Icons.mic_rounded;
      case 'chat': return Icons.chat_bubble_rounded;
      default: return Icons.notifications_rounded;
    }
  }
}
