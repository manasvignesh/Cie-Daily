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
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isBanned = user['isBanned'] == true;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131C),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF1C1C28),
                    backgroundImage: user['avatarUrl'] != null
                        ? NetworkImage(user['avatarUrl'])
                        : null,
                    child: user['avatarUrl'] == null
                        ? Text(user['name']?[0] ?? '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                          child: Text(user['name'] ?? 'Unknown User',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                  fontSize: 16))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: user['role'] == 'platform_admin'
                              ? Colors.red.withValues(alpha: 0.2)
                              : user['role'] == 'moderator'
                                  ? Colors.blue.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (user['role'] ?? 'student').toString().toUpperCase(),
                          style: TextStyle(
                            color: user['role'] == 'platform_admin'
                                ? Colors.redAccent
                                : user['role'] == 'moderator'
                                    ? Colors.blueAccent
                                    : Colors.grey[400],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('${user['email']}',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontFamily: 'Inter',
                            fontSize: 13)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF1C1C28),
                          icon: const Icon(Icons.arrow_drop_down_rounded,
                              color: Colors.white54),
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 13),
                          value: ['student', 'moderator', 'platform_admin']
                                  .contains(user['role'])
                              ? user['role']
                              : 'student',
                          items: const [
                            DropdownMenuItem(
                                value: 'student', child: Text('Student')),
                            DropdownMenuItem(
                                value: 'moderator', child: Text('Moderator')),
                            DropdownMenuItem(
                                value: 'platform_admin', child: Text('Admin')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(userManagementProvider)
                                  .updateRole(user['id'], value);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                            isBanned
                                ? Icons.restore_rounded
                                : Icons.block_rounded,
                            color: isBanned ? Colors.green : Colors.redAccent),
                        onPressed: () {
                          ref
                              .read(userManagementProvider)
                              .banUser(user['id'], !isBanned);
                        },
                        tooltip: isBanned ? 'Unban User' : 'Ban User',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(
            child: Text("We couldn't load users. Please try again.")),
      ),
    );
  }
}
