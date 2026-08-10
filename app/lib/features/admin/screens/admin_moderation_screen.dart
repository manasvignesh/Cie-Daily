import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/moderation_provider.dart';

class AdminModerationScreen extends ConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingPostsAsync = ref.watch(pendingPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderation Queue'),
      ),
      body: pendingPostsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('No pending posts.'));
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('By: ${post.authorName}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _showRejectDialog(context, ref, post.id);
                            },
                            child: const Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(moderationActionProvider).approvePost(post.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Post approved')),
                              );
                            },
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, String postId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Post'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(moderationActionProvider).rejectPost(postId, controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post rejected')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
