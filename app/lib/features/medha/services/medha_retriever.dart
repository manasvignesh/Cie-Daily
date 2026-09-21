import '../models/medha_models.dart';

class MedhaRetrievedChunk {
  const MedhaRetrievedChunk({
    required this.text,
    required this.score,
    required this.source,
  });

  final String text;
  final int score;
  final MedhaGroundingKind source;

  Map<String, dynamic> toJson() => {
        'text': text,
        'score': score,
        'source': source.name,
      };
}

class MedhaRetriever {
  const MedhaRetriever();

  List<MedhaRetrievedChunk> retrieve(
    MedhaContext context,
    String question, {
    int limit = 5,
  }) {
    final queryTokens = _tokens(question);
    final rawChunks = <String>[
      if (context.currentDeckCardText.isNotEmpty) context.currentDeckCardText,
      if (context.currentDeckCardTitle.isNotEmpty)
        '${context.currentDeckCardTitle}. ${context.currentDeckCardText}',
      context.quickSummary,
      ...context.keyNumbers,
      context.whyItMatters,
      ...context.allDeckCards,
      context.articleSummary,
      ...context.articleBody.split(RegExp(r'\n{2,}|(?<=[.!?])\s+(?=[A-Z0-9])')),
    ].map((text) => text.trim()).where((text) => text.length > 8);

    final seen = <String>{};
    final ranked = <MedhaRetrievedChunk>[];
    for (final chunk in rawChunks) {
      final normalized = chunk.toLowerCase();
      if (!seen.add(normalized)) continue;
      final chunkTokens = _tokens(chunk);
      final overlap = queryTokens.where(chunkTokens.contains).length;
      final distinctiveMatches = queryTokens
          .where((token) => token.length >= 8 && chunkTokens.contains(token))
          .length;
      final sectionBoost = normalized.contains(
              context.currentScrollSection.toLowerCase().split(' ').first)
          ? 2
          : 0;
      final currentCardBoost = context.currentDeckCardText.isNotEmpty &&
              (normalized == context.currentDeckCardText.toLowerCase() ||
                  normalized
                      .contains(context.currentDeckCardText.toLowerCase()))
          ? 20
          : 0;
      ranked.add(
        MedhaRetrievedChunk(
          text: chunk,
          score: overlap * 4 +
              distinctiveMatches * 2 +
              sectionBoost +
              currentCardBoost,
          source: MedhaGroundingKind.currentStory,
        ),
      );
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked.take(limit).toList(growable: false);
  }

  Set<String> _tokens(String input) => input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2 && !_stopWords.contains(word))
      .toSet();
}

const _stopWords = <String>{
  'the',
  'and',
  'that',
  'this',
  'with',
  'from',
  'what',
  'why',
  'how',
  'does',
  'about',
  'into',
  'for',
  'are',
  'was',
  'were',
};
