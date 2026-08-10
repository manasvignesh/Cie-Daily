import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_management_provider.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) return const Center(child: Text('No users found.'));
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isBanned = user['isBanned'] == true;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                  child: user['avatarUrl'] == null ? Text(user['name']?[0] ?? '?') : null,
                ),
                title: Text(user['name'] ?? 'Unknown User'),
                subtitle: Text('${user['email']} • Role: ${user['role']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: ['student', 'moderator', 'platform_admin'].contains(user['role']) 
                          ? user['role'] 
                          : 'student',
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Student')),
                        DropdownMenuItem(value: 'moderator', child: Text('Moderator')),
                        DropdownMenuItem(value: 'platform_admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(userManagementProvider).updateRole(user['id'], value);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(isBanned ? Icons.restore : Icons.block, color: isBanned ? Colors.green : Colors.red),
                      onPressed: () {
                        ref.read(userManagementProvider).banUser(user['id'], !isBanned);
                      },
                      tooltip: isBanned ? 'Unban User' : 'Ban User',
                    ),
                  ],
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
}
