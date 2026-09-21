import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/trusted_backend_client.dart';
import '../models/medha_models.dart';
import 'medha_retriever.dart';

final trustedBackendClientProvider = Provider<TrustedBackendClient>((ref) {
  final client = TrustedBackendClient();
  ref.onDispose(client.close);
  return client;
});

final medhaAssistantServiceProvider = Provider<MedhaAssistantService>((ref) {
  return MedhaAssistantService(ref.watch(trustedBackendClientProvider));
});

class MedhaAssistantService {
  MedhaAssistantService(this._backend, {MedhaRetriever? retriever})
      : _retriever = retriever ?? const MedhaRetriever();

  final TrustedBackendClient _backend;
  final MedhaRetriever _retriever;

  Future<MedhaAnswer> ask({
    required MedhaContext context,
    required MedhaCompanionType companion,
    required String question,
    required List<MedhaConversationTurn> history,
  }) async {
    final chunks = _retriever.retrieve(context, question);
    try {
      final response = await _backend.post('medha-chat', {
        'requestId': TrustedBackendClient.newRequestId(),
        'question': question,
        'companion': companion.name,
        'context': context.toJson(),
        'chunks': chunks.map((chunk) => chunk.toJson()).toList(),
        'history': history.takeLast(6).map((turn) => turn.toJson()).toList(),
      });
      final scopeStr = response['scope']?.toString();
      final scope = switch (scopeStr) {
        'outOfScope' => MedhaScopeClassification.outOfScope,
        'relatedExtension' => MedhaScopeClassification.relatedExtension,
        _ => MedhaScopeClassification.inScope,
      };
      final sections = _parseSections(response['sections']);
      if (sections.isNotEmpty) {
        return MedhaAnswer(
          sections: sections,
          usedFallback: false,
          scope: scope,
        );
      }
      // Server returned 200 but with no usable sections – deterministic fallback.
      if (kDebugMode) {
        debugPrint('MEDHA_CHAT remote returned empty sections, using fallback');
      }
    } catch (error, stackTrace) {
      // Log the real failure so "always offline" can be diagnosed on device.
      if (kDebugMode) {
        debugPrint('MEDHA_CHAT remote error: $error');
        debugPrint('$stackTrace');
      }
    }
    return _fallback(context, companion, question, chunks);
  }

  static final _blatantOutOfScopePattern = RegExp(
    r'\b(boyfriend|girlfriend|dating|date|bf|gf|tinder|bumble|pasta|recipe|cook|cooking|pizza|burger|chicken|joke|jokes|puns|funny|football player|cricket player|fifa|calculator in python|sorting algorithm|sort array)\b',
    caseSensitive: false,
  );

  List<MedhaGroundedSection> _parseSections(dynamic value) {
    if (value is! List) return const [];
    final sections = <MedhaGroundedSection>[];
    for (final raw in value) {
      if (raw is! Map) continue;
      final text = raw['text']?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      final kind = switch (raw['kind']?.toString()) {
        'relatedBreakpoint' => MedhaGroundingKind.relatedBreakpoint,
        'general' => MedhaGroundingKind.general,
        'outOfScope' => MedhaGroundingKind.outOfScope,
        _ => MedhaGroundingKind.currentStory,
      };
      sections.add(MedhaGroundedSection(kind: kind, text: text));
    }
    return sections;
  }

  MedhaAnswer _fallback(
    MedhaContext context,
    MedhaCompanionType companion,
    String question,
    List<MedhaRetrievedChunk> chunks,
  ) {
    if (_blatantOutOfScopePattern.hasMatch(question)) {
      final msg = medhaOutOfScopeMessages[companion] ??
          medhaOutOfScopeMessages[MedhaCompanionType.kiro]!;
      return MedhaAnswer(
        sections: [
          MedhaGroundedSection(
            kind: MedhaGroundingKind.outOfScope,
            text: msg,
          ),
        ],
        usedFallback: false,
        scope: MedhaScopeClassification.outOfScope,
      );
    }
    final normalized = question.toLowerCase();
    final visibleContext = context.currentDeckCardText.isNotEmpty
        ? context.currentDeckCardText
        : (context.quickSummary.isNotEmpty
            ? context.quickSummary
            : context.articleSummary);
    String answer;
    if (normalized.contains('why') || normalized.contains('matter')) {
      answer = context.whyItMatters.isNotEmpty
          ? context.whyItMatters
          : (chunks.isNotEmpty ? chunks.first.text : visibleContext);
    } else if (normalized.contains('key') || normalized.contains('learn')) {
      answer = chunks.take(3).map((chunk) => '• ${chunk.text}').join('\n');
    } else if (normalized.contains('explain') ||
        normalized.contains('simple')) {
      final source = chunks.isNotEmpty ? chunks.first.text : visibleContext;
      answer = '${companion.profile.toneLead} In simple terms: $source';
    } else {
      answer = '${companion.profile.toneLead} $visibleContext';
    }
    return MedhaAnswer(
      sections: [
        MedhaGroundedSection(
          kind: MedhaGroundingKind.currentStory,
          text: answer,
        ),
      ],
      usedFallback: true,
      scope: MedhaScopeClassification.inScope,
    );
  }
}

extension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    final values = toList(growable: false);
    return values.skip(values.length > count ? values.length - count : 0);
  }
}
