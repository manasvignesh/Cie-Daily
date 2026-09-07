import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_provider.dart';
import '../../../core/widgets/indicators/loading_skeleton.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxState = ref.watch(inboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
      ),
      body: inboxState.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(child: Text('No messages yet.'));
          }
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  child: Icon(
                    conv.isGroup ? Icons.group_rounded : Icons.person_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(conv.name ?? 'Unknown'),
                subtitle: Text(
                  conv.lastMessageText ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.push('/chat/${conv.id}'),
              );
            },
          );
        },
        loading: () => ListView.builder(
          itemCount: 5,
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
                      LoadingSkeleton(width: 120, height: 16),
                      SizedBox(height: 8),
                      LoadingSkeleton(width: double.infinity, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => const Center(
            child: Text("We couldn't load your messages. Please try again.")),
      ),
    );
  }
}
