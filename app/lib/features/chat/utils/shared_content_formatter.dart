String sharedContentPreview(String content) {
  final value = content.trim();

  if (value.startsWith('[SHARED_POST|')) {
    final parts = value.split('|');
    final category = parts.length > 2 ? parts[2].trim() : '';
    final title = parts.length > 3 ? parts[3].trim() : '';
    return _preview(category, title);
  }

  if (value.startsWith('[SHARED_POST]')) {
    final payload = value.substring('[SHARED_POST]'.length).trim();
    final category =
        payload.toLowerCase().contains('reel') ? 'reel' : 'article';
    return _preview(category, '');
  }

  final legacyMatch = RegExp(
    r'Shared\s+(Reel|Article):\s*"([^"]*)"',
    caseSensitive: false,
  ).firstMatch(value);
  if (legacyMatch != null) {
    return _preview(legacyMatch.group(1) ?? '', legacyMatch.group(2) ?? '');
  }

  return value;
}

bool isSharedContentMessage(String content) {
  final value = content.trim();
  return value.startsWith('[SHARED_POST|') ||
      value.startsWith('[SHARED_POST]') ||
      value.contains('[Post ID:');
}

String _preview(String category, String title) {
  final normalizedCategory =
      category.toLowerCase().contains('reel') ? 'reel' : 'article';
  final normalizedTitle = title.replaceAll(RegExp(r'\s+'), ' ').trim();
  final sharedLabel =
      normalizedCategory == 'article' ? 'Shared an article' : 'Shared a reel';
  return normalizedTitle.isEmpty
      ? sharedLabel
      : '$sharedLabel · $normalizedTitle';
}
