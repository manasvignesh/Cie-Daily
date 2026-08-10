import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_space_form_screen.dart';

class AdminSpacesScreen extends StatelessWidget {
  const AdminSpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Spaces')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('spaces').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final spaces = snapshot.data?.docs ?? [];
          if (spaces.isEmpty) {
            return const Center(child: Text('No Spaces Found'));
          }

          return ListView.builder(
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              final doc = spaces[index];
              final spaceData = doc.data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(spaceData['iconUrl'] ?? ''),
                  onBackgroundImageError: (_, __) {},
                  child: const Icon(Icons.space_dashboard),
                ),
                title: Text(spaceData['name'] ?? 'Unknown Space'),
                subtitle: Text(spaceData['description'] ?? 'No description', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AdminSpaceFormScreen(
                      spaceId: doc.id,
                      initialData: spaceData,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AdminSpaceFormScreen(),
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
