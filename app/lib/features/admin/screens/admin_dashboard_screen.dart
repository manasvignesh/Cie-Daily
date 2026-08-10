import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: FutureBuilder(
        future: Future.wait([
          FirebaseFirestore.instance.collection('users').count().get(),
          FirebaseFirestore.instance.collection('spaces').count().get(),
          FirebaseFirestore.instance.collection('posts').count().get(),
        ]),
        builder: (context, AsyncSnapshot<List<AggregateQuerySnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final userCount = snapshot.data?[0].count ?? 0;
          final spacesCount = snapshot.data?[1].count ?? 0;
          final postsCount = snapshot.data?[2].count ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(context, 'Total Users', userCount.toString(), Icons.people),
                _buildStatCard(context, 'Total Spaces', spacesCount.toString(), Icons.space_dashboard),
                _buildStatCard(context, 'Total Posts', postsCount.toString(), Icons.article),
                _buildStatCard(context, 'Pending Reports', '0', Icons.report_problem, color: Colors.red),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, {Color? color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color ?? Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
