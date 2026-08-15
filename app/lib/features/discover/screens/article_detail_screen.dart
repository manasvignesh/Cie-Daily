import 'package:flutter/material.dart';
import '../../feed/models/post_model.dart';
import '../../feed/widgets/in_app_share_bottom_sheet.dart';
import '../../../core/widgets/verified_badge.dart';

class ArticleDetailScreen extends StatelessWidget {
  final PostModel article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'share') {
                InAppShareBottomSheet.show(context, article);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.send_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Share In-App'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null)
              Image.network(
                article.imageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: article.authorAvatar != null
                            ? NetworkImage(article.authorAvatar!)
                            : null,
                        child: article.authorAvatar == null
                            ? Text(article.authorName.isNotEmpty
                                ? article.authorName[0].toUpperCase()
                                : 'A')
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                article.authorName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (article.isAuthorVerified)
                                const VerifiedBadge(size: 15),
                            ],
                          ),
                          Text(
                            '${article.estimatedReadTime} min read',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Render the article content blocks
                  ...article.blocks.map((block) {
                    if (block is Map<String, dynamic>) {
                      final type = block['type'];
                      final content = block['content'];
                      if (type == 'text' && content != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            content.toString(),
                            style: const TextStyle(fontSize: 16, height: 1.6),
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  }),

                  const SizedBox(height: 32),

                  // Bottom Share Action Button
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () {
                        InAppShareBottomSheet.show(context, article);
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Share Article with Connections'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
