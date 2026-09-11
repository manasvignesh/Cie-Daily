import 'package:flutter/foundation.dart';

class QuickBriefContent {
  final String category;
  final String headline;
  final String quickSummary;
  final List<String> threeThingsToKnow;
  final KeyStatContent? keyNumber;

  const QuickBriefContent({
    required this.category,
    required this.headline,
    required this.quickSummary,
    required this.threeThingsToKnow,
    this.keyNumber,
  });

  factory QuickBriefContent.fromMap(Map<String, dynamic> map) {
    return QuickBriefContent(
      category: _string(map['category'] ?? map['section'] ?? map['topic']),
      headline: _string(map['headline'] ?? map['title']),
      quickSummary: _string(
        map['quick_summary'] ?? map['quickSummary'] ?? map['summary'],
      ),
      threeThingsToKnow: _strings(
        map['three_things_to_know'] ?? map['threeThingsToKnow'] ?? map['keyFacts'],
      ),
      keyNumber: KeyStatContent.fromDynamic(
        map['key_number'] ?? map['keyNumber'] ?? map['key_stat'],
      ),
    );
  }

  @override
  String toString() =>
      'QuickBriefContent(category: $category, headline: $headline, quickSummary: $quickSummary, threeThingsToKnow: $threeThingsToKnow, keyNumber: $keyNumber)';
}

class FullArticleContent {
  final String headline;
  final String hook;
  final String in20Seconds;
  final String whatHappened;
  final String whyThisMatters;
  final String biggerPicture;
  final List<KeyStatContent> keyStats;
  final List<ExploreSectionContent> exploreSections;
  final List<String> takeaways;
  final QuoteContent? quote;

  const FullArticleContent({
    required this.headline,
    required this.hook,
    required this.in20Seconds,
    required this.whatHappened,
    required this.whyThisMatters,
    required this.biggerPicture,
    required this.keyStats,
    required this.exploreSections,
    required this.takeaways,
    this.quote,
  });

  factory FullArticleContent.fromMap(Map<String, dynamic> map) {
    final stats = map['key_stats'] ?? map['keyStats'] ?? map['key_numbers'];
    final takeaways = map['takeaways'] ?? map['you_now_know'] ?? map['youNowKnow'];
    final explore = map['explore_sections'] ?? map['exploreSections'];
    return FullArticleContent(
      headline: _string(map['headline'] ?? map['title']),
      hook: _string(map['hook'] ?? map['dek']),
      in20Seconds: _string(map['in_20_seconds'] ?? map['in20Seconds']),
      whatHappened: _string(map['what_happened'] ?? map['whatHappened']),
      whyThisMatters: _string(map['why_this_matters'] ?? map['whyThisMatters']),
      biggerPicture: _string(map['bigger_picture'] ?? map['biggerPicture']),
      keyStats: (stats is List ? stats : const <dynamic>[])
          .map(KeyStatContent.fromDynamic)
          .whereType<KeyStatContent>()
          .toList(),
      exploreSections: (explore is List ? explore : const <dynamic>[])
          .whereType<Map>()
          .map((item) => ExploreSectionContent.fromMap(_map(item)))
          .toList(),
      takeaways: _strings(takeaways),
      quote: QuoteContent.fromDynamic(map['quote']),
    );
  }

  @override
  String toString() =>
      'FullArticleContent(headline: $headline, hook: $hook, in20Seconds: $in20Seconds, whatHappened: $whatHappened, whyThisMatters: $whyThisMatters, biggerPicture: $biggerPicture, keyStats: $keyStats, exploreSections: $exploreSections, takeaways: $takeaways, quote: $quote)';
}

class KeyStatContent {
  final String value;
  final String label;

  const KeyStatContent({required this.value, required this.label});

  static KeyStatContent? fromDynamic(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return KeyStatContent(value: raw.trim(), label: '');
    }
    if (raw is Map) {
      final map = _map(raw);
      final value = _string(map['value'] ?? map['number'] ?? map['stat']);
      if (value.isEmpty) return null;
      return KeyStatContent(
        value: value,
        label: _string(map['label'] ?? map['description']),
      );
    }
    return null;
  }

  @override
  String toString() => 'KeyStatContent(value: $value, label: $label)';
}

class ExploreSectionContent {
  final String title;
  final String summary;
  final String content;
  final List<ExploreItemContent> items;

  const ExploreSectionContent({
    required this.title,
    required this.summary,
    required this.content,
    required this.items,
  });

  factory ExploreSectionContent.fromMap(Map<String, dynamic> map) {
    return ExploreSectionContent(
      title: _string(map['title']),
      summary: _string(map['summary']),
      content: _string(map['content']),
      items: (map['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => ExploreItemContent.fromMap(_map(item)))
          .toList(),
    );
  }
}

class ExploreItemContent {
  final String title;
  final String description;

  const ExploreItemContent({required this.title, required this.description});

  factory ExploreItemContent.fromMap(Map<String, dynamic> map) {
    return ExploreItemContent(
      title: _string(map['title']),
      description: _string(map['description'] ?? map['content']),
    );
  }
}

class QuoteContent {
  final String text;
  final String speaker;
  final String role;

  const QuoteContent({
    required this.text,
    required this.speaker,
    required this.role,
  });

  static QuoteContent? fromDynamic(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return QuoteContent(text: raw.trim(), speaker: '', role: '');
    }
    if (raw is Map) {
      final map = _map(raw);
      final text = _string(map['text'] ?? map['quote']);
      if (text.isEmpty) return null;
      return QuoteContent(
        text: text,
        speaker: _string(map['speaker'] ?? map['author']),
        role: _string(map['role'] ?? map['designation']),
      );
    }
    return null;
  }
}

class LocalizedArticleContent {
  final String title;
  final QuickBriefContent quickBrief;
  final FullArticleContent fullArticle;
  final String? audioUrl;
  final String translationStatus;
  final String audioStatus;

  const LocalizedArticleContent({
    required this.title,
    required this.quickBrief,
    required this.fullArticle,
    this.audioUrl,
    required this.translationStatus,
    required this.audioStatus,
  });

  factory LocalizedArticleContent.fromMap(Map<String, dynamic> map) {
    final audio = _string(map['audioUrl'] ?? map['audio_url']);
    return LocalizedArticleContent(
      title: _string(map['title']),
      quickBrief: QuickBriefContent.fromMap(_map(map['quick_brief'] ?? map['quickBrief'] ?? {})),
      fullArticle: FullArticleContent.fromMap(_map(map['full_article'] ?? map['fullArticle'] ?? {})),
      audioUrl: audio.isEmpty ? null : audio,
      translationStatus: _string(map['translationStatus'] ?? map['translation_status']),
      audioStatus: _string(map['audioStatus'] ?? map['audio_status']),
    );
  }
}

class PublishedArticle {
  final String id;
  final int schemaVersion;
  final QuickBriefContent? quickBrief;
  final FullArticleContent? fullArticle;
  final Map<String, dynamic> metadata;
  final Map<String, LocalizedArticleContent> languages;

  const PublishedArticle({
    required this.id,
    required this.schemaVersion,
    required this.quickBrief,
    required this.fullArticle,
    required this.metadata,
    this.languages = const {},
  });

  factory PublishedArticle.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final schemaVersion = _integer(data['schema_version'] ?? data['schemaVersion']);
    final quickMap = data['quick_brief'] ?? data['quickBrief'];
    final fullMap = data['full_article'] ?? data['fullArticle'];
    final article = PublishedArticle(
      id: id,
      schemaVersion: schemaVersion,
      quickBrief:
          quickMap is Map ? QuickBriefContent.fromMap(_map(quickMap)) : null,
      fullArticle:
          fullMap is Map ? FullArticleContent.fromMap(_map(fullMap)) : null,
      metadata: data['metadata'] is Map
          ? _map(data['metadata'] as Map)
          : const <String, dynamic>{},
      languages: data['languages'] is Map
          ? (_map(data['languages'] as Map).map((k, v) => MapEntry(k, LocalizedArticleContent.fromMap(_map(v)))))
          : const <String, LocalizedArticleContent>{},
    );
    if (schemaVersion >= 2) {
      if (article.quickBrief == null) {
        debugPrint('ARTICLE_SCHEMA_ERROR [$id]: quick_brief is missing');
      }
      if (article.fullArticle == null) {
        debugPrint('ARTICLE_SCHEMA_ERROR [$id]: full_article is missing');
      }
      if (article.fullArticle?.takeaways.isEmpty ?? true) {
        debugPrint(
            'ARTICLE_SCHEMA_ERROR [$id]: full_article.takeaways is empty');
      }
    }
    return article;
  }
}

Map<String, dynamic> _map(Map raw) =>
    raw.map((key, value) => MapEntry(key.toString(), value));

String _string(dynamic value) => value?.toString().trim() ?? '';

int _integer(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 1;
}

List<String> _strings(dynamic value) {
  if (value is! List) return const [];
  return value
      .map(_string)
      .where((item) => item.isNotEmpty)
      .toList();
}
