import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/buttons/primary_button.dart';

class SpacesHomeScreen extends StatelessWidget {
  const SpacesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              // Create Space logic here
              // For now, redirect to a mock space
              context.push('/space/mock-space-123');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Live Now',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text('145 listening', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Flutter Architecture Deep Dive', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Join Space',
                    onPressed: () => context.push('/space/mock-space-123'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
