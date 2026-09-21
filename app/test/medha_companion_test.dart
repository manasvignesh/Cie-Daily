import 'package:cie_connect/core/providers/language_provider.dart';
import 'package:cie_connect/features/medha/models/medha_models.dart';
import 'package:cie_connect/features/medha/providers/medha_preferences_provider.dart';
import 'package:cie_connect/features/medha/services/medha_retriever.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('existing users receive Kiro defaults and companion choice persists',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(medhaPreferencesProvider).companion,
      MedhaCompanionType.kiro,
    );
    expect(container.read(medhaPreferencesProvider).enabled, isTrue);
    expect(container.read(medhaPreferencesProvider).voiceEnabled, isFalse);

    await container
        .read(medhaPreferencesProvider.notifier)
        .selectCompanion(MedhaCompanionType.nishi);
    expect(preferences.getString('medha_selected_companion'), 'nishi');
  });

  test('retrieval prioritizes the relevant current-story chunk', () {
    const context = MedhaContext(
      route: '/article/engine',
      screenType: 'article',
      articleId: 'engine',
      articleTitle: 'A new semi-cryogenic engine',
      articleSummary: 'The engine completed a major hot-fire test.',
      articleBody:
          'The turbopump pushes propellants into the combustion chamber at very high pressure.\n\nThe programme began several years ago.\n\nThe test lasted 120 seconds.',
      visibleSection: 'Why this matters',
      category: 'Science',
      author: 'Breakpoint',
      currentScrollSection: 'Why this matters',
    );

    final chunks = const MedhaRetriever().retrieve(
      context,
      'Why does the engine need a turbopump?',
    );

    expect(chunks, isNotEmpty);
    expect(chunks.first.text, contains('turbopump'));
    expect(chunks.first.source, MedhaGroundingKind.currentStory);
  });

  test('swipe deck retrieval gives the visible card strongest priority', () {
    const context = MedhaContext(
      route: '/quick-brief/engine',
      screenType: 'swipeDeck',
      contentMode: MedhaContentMode.swipeDeck,
      articleId: 'engine',
      articleTitle: 'A new semi-cryogenic engine',
      articleSummary: 'The engine completed a hot-fire test.',
      articleBody: 'The programme began several years ago.',
      visibleSection: 'Swipe Deck card 3',
      category: 'Science',
      author: 'Breakpoint',
      currentScrollSection: 'Current Swipe Deck card',
      currentDeckCardIndex: 2,
      currentDeckCardTitle: 'The key number',
      currentDeckCardText:
          'The 120-second firing proves the engine can sustain full thrust.',
      allDeckCards: [
        'The programme began several years ago.',
        'The turbopump feeds propellant at high pressure.',
        'The 120-second firing proves the engine can sustain full thrust.',
      ],
    );

    final chunks = const MedhaRetriever().retrieve(
      context,
      'What does this number mean?',
    );

    expect(chunks.first.text, contains('120-second'));
    expect(context.toJson()['contentMode'], 'swipeDeck');
    expect(context.toJson()['currentDeckCardIndex'], 2);
  });

  test('every companion has a distinct portable voice profile', () {
    final profiles = MedhaCompanionType.values
        .map((companion) => companion.voiceProfile)
        .toList(growable: false);

    expect(profiles.map((profile) => profile.speechRate).toSet().length, 5);
    expect(MedhaCompanionType.lumi.voiceProfile.speechRate, lessThan(1));
    expect(MedhaCompanionType.zuzu.voiceProfile.speechRate, greaterThan(1.1));
    expect(MedhaCompanionType.nishi.voiceProfile.pitch, lessThan(1));
  });

  test('the five approved companion profiles remain the complete catalog', () {
    expect(medhaCompanionProfiles.length, 5);
    expect(
      medhaCompanionProfiles.values.map((profile) => profile.name),
      containsAll(['Kiro', 'Lumi', 'Momo', 'Zuzu', 'Nishi']),
    );
  });

  test('all five companions have tailored out-of-scope responses', () {
    expect(medhaOutOfScopeMessages.length, 5);
    expect(
      medhaOutOfScopeMessages[MedhaCompanionType.kiro],
      "That's a little outside what we're exploring 😭 Ask me something about this story.",
    );
    expect(
      medhaOutOfScopeMessages[MedhaCompanionType.lumi],
      "That's outside this story. I'm here to help you understand what you're reading.",
    );
    expect(
      medhaOutOfScopeMessages[MedhaCompanionType.momo],
      "Wrong adventure 😭 Ask me something about this story.",
    );
    expect(
      medhaOutOfScopeMessages[MedhaCompanionType.zuzu],
      "Different topic 😭 Hit me with something about this story.",
    );
    expect(
      medhaOutOfScopeMessages[MedhaCompanionType.nishi],
      "That falls outside this story. Let's stay with what you're exploring here.",
    );
  });

  test('MedhaAnswer properly identifies outOfScope answers', () {
    const inScopeAnswer = MedhaAnswer(
      sections: [
        MedhaGroundedSection(
          kind: MedhaGroundingKind.currentStory,
          text: 'The engine uses liquid oxygen and kerosene.',
        ),
      ],
      usedFallback: false,
      scope: MedhaScopeClassification.inScope,
    );
    expect(inScopeAnswer.isOutOfScope, isFalse);
    expect(inScopeAnswer.scope, MedhaScopeClassification.inScope);

    const relatedAnswer = MedhaAnswer(
      sections: [
        MedhaGroundedSection(
          kind: MedhaGroundingKind.general,
          text: 'In data science, engine telemetry produces time-series streams.',
        ),
      ],
      usedFallback: false,
      scope: MedhaScopeClassification.relatedExtension,
    );
    expect(relatedAnswer.isOutOfScope, isFalse);
    expect(relatedAnswer.scope, MedhaScopeClassification.relatedExtension);

    const outOfScopeAnswer = MedhaAnswer(
      sections: [
        MedhaGroundedSection(
          kind: MedhaGroundingKind.outOfScope,
          text: "That's a little outside what we're exploring 😭 Ask me something about this story.",
        ),
      ],
      usedFallback: false,
      scope: MedhaScopeClassification.outOfScope,
    );
    expect(outOfScopeAnswer.isOutOfScope, isTrue);
    expect(outOfScopeAnswer.scope, MedhaScopeClassification.outOfScope);
    expect(outOfScopeAnswer.usedFallback, isFalse);
  });
}
