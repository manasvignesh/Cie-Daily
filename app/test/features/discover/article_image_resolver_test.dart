import 'package:flutter_test/flutter_test.dart';
import 'package:cie_connect/features/discover/models/article_image_resolver.dart';

void main() {
  group('resolveArticleImage', () {
    test('keeps the first valid supplied image URL', () {
      const supplied = 'https://news.example.com/images/story.jpg';

      expect(
        resolveArticleImage(
          candidates: const ['', 'not-a-url', supplied],
          title: 'A new technology story',
          category: 'Tech',
        ),
        supplied,
      );
    });

    test('uses an AI-related fallback when the image is missing', () {
      final resolved = resolveArticleImage(
        candidates: const [null, ''],
        title: 'New AI model helps students learn',
        category: 'AI & ML',
      );

      expect(resolved, startsWith('https://images.unsplash.com/'));
      expect(resolved, contains('photo-1677442136019-21780ecad995'));
    });

    test('uses different topic fallbacks for unrelated categories', () {
      final sports = fallbackArticleImage(
        title: 'Tournament final',
        category: 'Sports',
      );
      final campus = fallbackArticleImage(
        title: 'University research programme',
        category: 'Campus',
      );

      expect(sports, isNot(campus));
    });
  });
}
