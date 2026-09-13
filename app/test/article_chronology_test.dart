import 'package:cie_connect/features/discover/models/article_chronology.dart';
import 'package:cie_connect/features/feed/models/post_model.dart';
import 'package:flutter_test/flutter_test.dart';

PostModel article(
  String id, {
  String? publishedAt,
  String? createdAt,
  String? updatedAt,
}) {
  return PostModel.fromJson({
    'id': id,
    'title': id,
    'category': 'Article',
    'status': 'approved',
    if (publishedAt != null) 'publishedAt': publishedAt,
    if (createdAt != null) 'createdAt': createdAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
  });
}

void main() {
  test('orders by publishedAt then createdAt and keeps missing dates oldest', () {
    final sorted = sortArticlesNewestFirst([
      article('missing', updatedAt: '2030-01-01T00:00:00Z'),
      article('created', createdAt: '2026-09-11T00:00:00Z'),
      article('published',
          publishedAt: '2026-09-12T00:00:00Z',
          createdAt: '2020-01-01T00:00:00Z'),
    ]);

    expect(sorted.map((post) => post.id), ['published', 'created', 'missing']);
  });

  test('updatedAt never changes chronological ordering', () {
    final sorted = sortArticlesNewestFirst([
      article('old',
          publishedAt: '2025-01-01T00:00:00Z',
          updatedAt: '2030-01-01T00:00:00Z'),
      article('new',
          publishedAt: '2026-01-01T00:00:00Z',
          updatedAt: '2020-01-01T00:00:00Z'),
    ]);

    expect(sorted.map((post) => post.id), ['new', 'old']);
  });
}
