import 'package:flutter/material.dart';
import '../../feed/models/post_model.dart';

class ArticleDetailScreen extends StatelessWidget {
  final PostModel article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
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
                  const SizedBox(height: 8),
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
                          Text(
                            article.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
