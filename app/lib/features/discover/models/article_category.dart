import '../../feed/models/post_model.dart';

const discoverCategories = <String>[
  'All',
  'Startups',
  'Tech',
  'AI & ML',
  'Events',
  'Campus',
  'Sports',
];

/// Maps producer labels and older article formats onto the six Discover tags.
/// The original Firestore values are left untouched; this is a presentation
/// compatibility layer for mixed historical and newly generated articles.
String normalizeArticleCategory({String? rawCategory, String text = ''}) {
  final raw = (rawCategory ?? '').trim().toLowerCase();
  final corpus = '$raw ${text.toLowerCase()}';
  bool hasAny(List<String> words) => words.any((word) {
        if (word.contains(' ')) return corpus.contains(word);
        return RegExp(r'\b' + RegExp.escape(word) + r'\b').hasMatch(corpus);
      });

  if (hasAny(['sport', 'cricket', 'football', 'athlete', 'tournament', 'ipl'])) {
    return 'Sports';
  }
  if (hasAny([
    'event',
    'conference',
    'summit',
    'hackathon',
    'workshop',
    'festival',
    'meetup',
    'webinar',
  ])) {
    return 'Events';
  }
  if (hasAny([
    'campus',
    'college',
    'university',
    'student',
    'iit ',
    'nit ',
    'hostel',
    'semester',
    'scholarship',
  ])) {
    return 'Campus';
  }
  if (hasAny([
    'ai',
    'artificial intelligence',
    'machine learning',
    'deep learning',
    'neural',
    'llm',
    'generative model',
  ])) {
    return 'AI & ML';
  }
  if (hasAny([
    'startup',
    'start-up',
    'venture',
    'funding',
    'fundraise',
    'seed round',
    'series a',
    'series b',
    'founder',
    'raises ₹',
    'raises rs',
  ])) {
    return 'Startups';
  }
  // Technology, Science, Engineering, Business, Article, and old free-form
  // labels all get a stable home instead of disappearing from every filter.
  return 'Tech';
}

String categoryForPost(PostModel post) {
  final quick = post.quickBrief;
  final text = [
    post.title,
    quick?.headline,
    quick?.quickSummary,
    post.fullArticle?.whatHappened,
    post.fullArticle?.biggerPicture,
    post.publishedArticle.metadata['category'],
    post.publishedArticle.metadata['section'],
    post.publishedArticle.metadata['topic'],
    post.publishedArticle.metadata['domain'],
  ].whereType<String>().join(' ');
  return normalizeArticleCategory(
    rawCategory: quick?.category.isNotEmpty == true
        ? quick!.category
        : (post.category.isNotEmpty
            ? post.category
            : (post.publishedArticle.metadata['section']?.toString() ?? '')),
    text: text,
  );
}
