import 'package:flutter/material.dart';
import '../../../core/widgets/overlays/app_bottom_sheet.dart';

class CommentsBottomSheet extends StatelessWidget {
  final String postId;

  const CommentsBottomSheet({super.key, required this.postId});

  static void show(BuildContext context, String postId) {
    AppBottomSheet.show(
      context: context,
      child: CommentsBottomSheet(postId: postId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Text(
            'Comments',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Placeholder count
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('Student ${index + 1}'),
                  subtitle: const Text('This is a highly insightful comment!'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: () {}, // Submit comment
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
