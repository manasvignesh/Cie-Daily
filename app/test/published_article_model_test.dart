import 'package:flutter_test/flutter_test.dart';
import 'package:cie_connect/features/feed/models/post_model.dart';
import 'package:cie_connect/features/discover/models/structured_article_model.dart';

void main() {
  final firestoreDocument = <String, dynamic>{
    'id': 'ather-new-article',
    'schema_version': 2,
    'title': 'LEGACY TITLE',
    'summary': 'LEGACY SUMMARY MUST NOT LEAK',
    'blocks': [
      {'type': 'text', 'content': 'LEGACY BLOCK MUST NOT LEAK'},
    ],
    'category': 'Article',
    'status': 'approved',
    'createdAt': '2026-08-30T00:00:00.000Z',
    'authorName': 'Editor',
    'quick_brief': {
      'category': 'EV TECH',
      'headline': 'Ather unveils its new platform',
      'quick_summary': 'A short, brief-only summary.',
      'three_things_to_know': ['One', 'Two', 'Three'],
      'key_number': {'value': '165 km', 'label': 'Range'},
    },
    'full_article': {
      'headline': 'Ather unveils its new platform',
      'hook': 'The deeper full-article hook.',
      'in_20_seconds': 'The full article summary.',
      'what_happened': 'A distinct account of what happened.',
      'why_this_matters': 'A distinct explanation of why it matters.',
      'bigger_picture': 'A distinct bigger picture.',
      'key_stats': [
        {'value': '165 km', 'label': 'Range'},
        {'value': '90 km/h', 'label': 'Top speed'},
      ],
      'explore_sections': [
        {
          'title': 'Platform & Powertrain',
          'summary': 'Architecture overview',
          'content': 'Full platform content',
          'items': [
            {'title': 'Motor', 'description': 'Motor details'},
          ],
        },
        {
          'title': 'Pricing & Variants',
          'summary': 'Variant overview',
          'content': 'Full pricing content',
          'items': [],
        },
      ],
      'takeaways': ['Takeaway one', 'Takeaway two'],
    },
  };

  test('schema v2 explicitly separates quick brief and full article', () {
    final post = PostModel.fromJson(Map.of(firestoreDocument));

    expect(post.schemaVersion, 2);
    expect(post.quickBrief!.quickSummary, 'A short, brief-only summary.');
    expect(post.quickBrief!.threeThingsToKnow, ['One', 'Two', 'Three']);
    expect(post.fullArticle!.whyThisMatters,
        'A distinct explanation of why it matters.');
    expect(post.fullArticle!.exploreSections, hasLength(2));
    expect(post.fullArticle!.exploreSections[1].title, 'Pricing & Variants');
  });

  test('schema v2 full renderer never consumes legacy or quick brief text', () {
    final post = PostModel.fromJson(Map.of(firestoreDocument));
    final rendered = StructuredArticleData.fromPostModel(post);

    expect(rendered.in20SecondsSummary, 'The full article summary.');
    expect(rendered.whyItMatters, 'A distinct explanation of why it matters.');
    expect(
        rendered.exploreSections.map((item) => item.title),
        containsAll([
          'What Happened',
          'Platform & Powertrain',
          'Pricing & Variants',
          'The Bigger Picture',
        ]));
    expect(rendered.takeaways, ['Takeaway one', 'Takeaway two']);
    expect(rendered.in20SecondsSummary, isNot(contains('LEGACY')));
    expect(rendered.in20SecondsSummary,
        isNot(equals(post.quickBrief!.quickSummary)));
  });
}
