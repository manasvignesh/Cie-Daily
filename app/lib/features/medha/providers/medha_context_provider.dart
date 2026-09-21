import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supported_languages.dart';
import '../../discover/models/structured_article_model.dart';
import '../models/medha_models.dart';

class MedhaArticleContextInput {
  const MedhaArticleContextInput({
    required this.article,
    required this.scrollProgress,
  });

  final StructuredArticleData article;
  final double scrollProgress;

  int get _sectionBucket => switch (scrollProgress.clamp(0.0, 1.0)) {
        < 0.16 => 0,
        < 0.38 => 1,
        < 0.58 => 2,
        < 0.82 => 3,
        _ => 4,
      };

  @override
  bool operator ==(Object other) =>
      other is MedhaArticleContextInput &&
      other.article.id == article.id &&
      other._sectionBucket == _sectionBucket;

  @override
  int get hashCode => Object.hash(article.id, _sectionBucket);
}

final medhaArticleContextProvider =
    Provider.family<MedhaContext, MedhaArticleContextInput>((ref, input) {
  final article = input.article;
  final progress = input.scrollProgress.clamp(0.0, 1.0);
  final section = switch (progress) {
    < 0.16 => 'Headline and quick brief',
    < 0.38 => 'Key numbers',
    < 0.58 => 'Why this matters',
    < 0.82 => 'Explore the story',
    _ => 'Takeaways',
  };
  return MedhaContext(
    route: '/article/${article.id}',
    screenType: 'article',
    articleId: article.id,
    articleTitle: article.headline,
    articleSummary: article.in20SecondsSummary,
    articleBody: article.narrationFallbackText,
    visibleSection: section,
    category: article.category,
    author: article.authorName,
    currentScrollSection: section,
    contentMode: MedhaContentMode.fullStory,
    contentLocale:
        SupportedLanguages.get(article.contentLanguage)?.code ?? 'en-IN',
    quickSummary: article.in20SecondsSummary,
    keyNumbers: article.keyNumbers
        .map((number) => '${number.value}: ${number.label}')
        .toList(growable: false),
    whyItMatters: article.whyItMatters,
  );
});
