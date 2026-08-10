import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final bookmarkedPostsAsync = ref.watch(bookmarkedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    child: user.photoURL == null
                        ? Text(
                            user.displayName?.isNotEmpty == true
                                ? user.displayName![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName ?? 'Student',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Saved Bookmarks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  bookmarkedPostsAsync.when(
                    data: (posts) {
                      if (posts.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'You haven\'t saved any posts yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: post.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        post.imageUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.article, color: Colors.white),
                                    ),
                              title: Text(
                                post.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('By ${post.authorName}', style: const TextStyle(fontSize: 12)),
                              ),
                              onTap: () {
                                // Navigate to post details if implemented
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ],
              ),
            ),
    );
  }
}
