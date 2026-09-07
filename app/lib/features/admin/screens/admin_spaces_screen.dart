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
        stream: FirebaseFirestore.instance
            .collection('spaces')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text("We couldn't load spaces. Please try again."));
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
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C28),
                      borderRadius: BorderRadius.circular(12),
                      image: spaceData['iconUrl'] != null &&
                              spaceData['iconUrl'].toString().isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(spaceData['iconUrl']),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: spaceData['iconUrl'] == null ||
                            spaceData['iconUrl'].toString().isEmpty
                        ? const Icon(Icons.space_dashboard_rounded,
                            color: Color(0xFFFF5A1F))
                        : null,
                  ),
                  title: Text(spaceData['name'] ?? 'Unknown Space',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                          fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(spaceData['description'] ?? 'No description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontFamily: 'Inter',
                            fontSize: 13)),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white54),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AdminSpaceFormScreen(
                        spaceId: doc.id,
                        initialData: spaceData,
                      ),
                    ));
                  },
                ),
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
