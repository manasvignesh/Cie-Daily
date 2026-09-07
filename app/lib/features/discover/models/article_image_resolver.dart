/// Returns a usable supplied image URL or a stable editorial fallback that
/// matches the story topic. The fallbacks keep older Firestore articles from
/// rendering as empty grey media blocks without changing the stored schema.
String resolveArticleImage({
  required Iterable<dynamic> candidates,
  required String title,
  required String category,
}) {
  for (final candidate in candidates) {
    final value = candidate?.toString().trim() ?? '';
    final uri = Uri.tryParse(value);
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return value;
    }
  }

  final topic = '$category $title'.toLowerCase();
  if (_containsAny(topic, ['sport', 'cricket', 'football', 'athlete'])) {
    return _sportsImage;
  }
  if (_containsAny(topic, ['event', 'conference', 'summit', 'workshop'])) {
    return _eventsImage;
  }
  if (RegExp(r'\bai\b').hasMatch(topic) ||
      _containsAny(topic, [
        'artificial intelligence',
        'machine learning',
        'chatgpt',
        'llm',
      ])) {
    return _aiImage;
  }
  if (_containsAny(topic, ['startup', 'funding', 'founder', 'venture'])) {
    return _startupImage;
  }
  if (_containsAny(
      topic, ['campus', 'college', 'university', 'student', 'iit'])) {
    return _learningImage;
  }
  return _technologyImage;
}

String fallbackArticleImage({
  required String title,
  required String category,
}) =>
    resolveArticleImage(
      candidates: const [],
      title: title,
      category: category,
    );

bool _containsAny(String value, List<String> terms) =>
    terms.any(value.contains);

const _aiImage =
    'https://images.unsplash.com/photo-1677442136019-21780ecad995?auto=format&fit=crop&w=1200&q=82';
const _startupImage =
    'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&w=1200&q=82';
const _sportsImage =
    'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=1200&q=82';
const _eventsImage =
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=82';
const _learningImage =
    'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=1200&q=82';
const _technologyImage =
    'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=82';
