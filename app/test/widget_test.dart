import 'package:flutter_test/flutter_test.dart';
import 'package:cie_connect/features/chat/utils/shared_content_formatter.dart';

void main() {
  group('sharedContentPreview', () {
    test('formats a structured article share', () {
      expect(
        sharedContentPreview(
          '[SHARED_POST|post_1|Article|Pune Motion Lab|image|video|Author]',
        ),
        'Shared an article · Pune Motion Lab',
      );
    });

    test('formats a structured reel share', () {
      expect(
        sharedContentPreview(
          '[SHARED_POST|post_2|Reel|Live Atlas 🌍|image|video|Author]',
        ),
        'Shared a reel · Live Atlas 🌍',
      );
    });

    test('hides a legacy internal identifier', () {
      expect(
        sharedContentPreview('[SHARED_POST]stock_article_3_internal'),
        'Shared an article',
      );
    });

    test('preserves a normal chat message', () {
      expect(sharedContentPreview('See you at 4!'), 'See you at 4!');
    });
  });
}
