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
        builder:
            (context, AsyncSnapshot<List<AggregateQuerySnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child:
                    Text("We couldn't load the dashboard. Please try again."));
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
                _buildStatCard(
                    context, 'Total Users', userCount.toString(), Icons.people),
                _buildStatCard(context, 'Total Spaces', spacesCount.toString(),
                    Icons.space_dashboard),
                _buildStatCard(context, 'Total Posts', postsCount.toString(),
                    Icons.article),
                _buildStatCard(
                    context, 'Pending Reports', '0', Icons.report_problem,
                    color: Colors.red),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String title, String value, IconData icon,
      {Color? color}) {
    final effectiveColor = color ?? const Color(0xFFFF5A1F);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: effectiveColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: effectiveColor),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
