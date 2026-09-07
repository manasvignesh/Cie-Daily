import 'package:cie_connect/features/discover/services/article_narration_service.dart';
import 'package:cie_connect/features/discover/models/structured_article_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('speech normalization expands common editorial symbols', () {
    expect(
      normalizeForSpeech('AI raised ₹2 million at 80% for a 10 MW project.'),
      'A I raised rupees 2 million at 80 percent for a 10 megawatts project.',
    );
  });

  test('speech normalization removes formatting tokens', () {
    expect(normalizeForSpeech('**Useful**  •  idea'), 'Useful idea');
  });

  test('narration estimate never returns zero', () {
    expect(
        estimatedNarrationMinutes(
          const StructuredArticleData(
            id: 'test',
            category: 'TECH',
            headline: 'A short story',
            hook: 'A useful introduction.',
            authorName: 'CIE Daily',
            readTime: 1,
            in20SecondsSummary: 'The summary.',
            keyNumbers: [],
            whyItMatters: 'It matters.',
            exploreSections: [],
            takeaways: [],
          ),
        ),
        1);
  });
}
