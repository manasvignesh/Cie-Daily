enum MedhaCompanionType { kiro, lumi, momo, zuzu, nishi }

enum MedhaBehaviorState {
  idle,
  looking,
  reading,
  scrollFollowing,
  curious,
  attention,
  thinking,
  playing,
  listening,
  speaking,
  celebrating,
  resting,
}

enum MedhaGroundingKind { currentStory, relatedBreakpoint, general, outOfScope }

enum MedhaScopeClassification { inScope, relatedExtension, outOfScope }

const medhaOutOfScopeMessages = <MedhaCompanionType, String>{
  MedhaCompanionType.kiro:
      "That's a little outside what we're exploring 😭 Ask me something about this story.",
  MedhaCompanionType.lumi:
      "That's outside this story. I'm here to help you understand what you're reading.",
  MedhaCompanionType.momo:
      "Wrong adventure 😭 Ask me something about this story.",
  MedhaCompanionType.zuzu:
      "Different topic 😭 Hit me with something about this story.",
  MedhaCompanionType.nishi:
      "That falls outside this story. Let's stay with what you're exploring here.",
};

enum MedhaContentMode { fullStory, quickBrief, swipeDeck }

enum MedhaVoiceStyle { neutralYouthful, soft, warmYouthful, bright, grounded }

class MedhaVoiceProfile {
  const MedhaVoiceProfile({
    required this.preferredStyle,
    required this.pitch,
    required this.speechRate,
    required this.locale,
  });

  final MedhaVoiceStyle preferredStyle;
  final double pitch;

  /// A platform-neutral multiplier where 1.0 is the device's normal rate.
  final double speechRate;
  final String locale;
}

class MedhaCompanionProfile {
  const MedhaCompanionProfile({
    required this.type,
    required this.name,
    required this.title,
    required this.traits,
    required this.personalityLine,
    required this.toneLead,
    required this.assetPath,
    required this.openEyeAssetPath,
    required this.closedEyeAssetPath,
  });

  final MedhaCompanionType type;
  final String name;
  final String title;
  final List<String> traits;
  final String personalityLine;
  final String toneLead;
  final String assetPath;
  final String openEyeAssetPath;
  final String closedEyeAssetPath;
}

const medhaCompanionProfiles = <MedhaCompanionType, MedhaCompanionProfile>{
  MedhaCompanionType.kiro: MedhaCompanionProfile(
    type: MedhaCompanionType.kiro,
    name: 'Kiro',
    title: 'The Curious Spark',
    traits: ['Curious', 'Observant'],
    personalityLine: 'Notices the little things with you.',
    toneLead: "Here's the interesting part —",
    assetPath: 'assets/medha/kiro.png',
    openEyeAssetPath: 'assets/medha/kiro-open.png',
    closedEyeAssetPath: 'assets/medha/kiro.png',
  ),
  MedhaCompanionType.lumi: MedhaCompanionProfile(
    type: MedhaCompanionType.lumi,
    name: 'Lumi',
    title: 'The Gentle Light',
    traits: ['Calm', 'Thoughtful'],
    personalityLine: 'Brings clarity to complex ideas.',
    toneLead: "Let's break this down simply.",
    assetPath: 'assets/medha/lumi.png',
    openEyeAssetPath: 'assets/medha/lumi.png',
    closedEyeAssetPath: 'assets/medha/lumi-blink.png',
  ),
  MedhaCompanionType.momo: MedhaCompanionProfile(
    type: MedhaCompanionType.momo,
    name: 'Momo',
    title: 'The Moon Drop',
    traits: ['Playful', 'Warm'],
    personalityLine: 'Turns big ideas into brighter days.',
    toneLead: "Okay, this one's actually pretty cool —",
    assetPath: 'assets/medha/momo.png',
    openEyeAssetPath: 'assets/medha/momo.png',
    closedEyeAssetPath: 'assets/medha/momo-blink.png',
  ),
  MedhaCompanionType.zuzu: MedhaCompanionProfile(
    type: MedhaCompanionType.zuzu,
    name: 'Zuzu',
    title: 'The Swift Breeze',
    traits: ['Quick', 'Clever'],
    personalityLine: 'Keeps you moving with fresh perspectives.',
    toneLead: 'Short version first —',
    assetPath: 'assets/medha/zuzu.png',
    openEyeAssetPath: 'assets/medha/zuzu-open.png',
    closedEyeAssetPath: 'assets/medha/zuzu.png',
  ),
  MedhaCompanionType.nishi: MedhaCompanionProfile(
    type: MedhaCompanionType.nishi,
    name: 'Nishi',
    title: 'The Quiet Guide',
    traits: ['Wise', 'Focused'],
    personalityLine: 'Helps you see a little deeper.',
    toneLead: 'The key idea is this —',
    assetPath: 'assets/medha/nishi.png',
    openEyeAssetPath: 'assets/medha/nishi-open.png',
    closedEyeAssetPath: 'assets/medha/nishi.png',
  ),
};

extension MedhaCompanionTypeX on MedhaCompanionType {
  MedhaCompanionProfile get profile => medhaCompanionProfiles[this]!;

  MedhaVoiceProfile get voiceProfile => switch (this) {
        // Kiro: neutral baseline — moderate pitch, slightly brisk pace.
        MedhaCompanionType.kiro => const MedhaVoiceProfile(
            preferredStyle: MedhaVoiceStyle.neutralYouthful,
            pitch: 1.05,
            speechRate: 1.05,
            locale: 'en-IN',
          ),
        // Lumi: calm and soft — higher pitch, noticeably slower.
        MedhaCompanionType.lumi => const MedhaVoiceProfile(
            preferredStyle: MedhaVoiceStyle.soft,
            pitch: 1.20,
            speechRate: 0.85,
            locale: 'en-IN',
          ),
        // Momo: warm and playful — highest pitch, moderate pace.
        MedhaCompanionType.momo => const MedhaVoiceProfile(
            preferredStyle: MedhaVoiceStyle.warmYouthful,
            pitch: 1.32,
            speechRate: 1.00,
            locale: 'en-IN',
          ),
        // Zuzu: quick and energetic — mid-high pitch, fastest pace.
        MedhaCompanionType.zuzu => const MedhaVoiceProfile(
            preferredStyle: MedhaVoiceStyle.bright,
            pitch: 1.12,
            speechRate: 1.25,
            locale: 'en-IN',
          ),
        // Nishi: wise and grounded — lowest pitch, slowest pace.
        MedhaCompanionType.nishi => const MedhaVoiceProfile(
            preferredStyle: MedhaVoiceStyle.grounded,
            pitch: 0.78,
            speechRate: 0.82,
            locale: 'en-IN',
          ),
      };

  static MedhaCompanionType parse(String? value) {
    return MedhaCompanionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MedhaCompanionType.kiro,
    );
  }
}

class MedhaPreferences {
  const MedhaPreferences({
    this.companion = MedhaCompanionType.kiro,
    this.enabled = true,
    this.voiceEnabled = false,
    this.soundsEnabled = false,
  });

  final MedhaCompanionType companion;
  final bool enabled;
  final bool voiceEnabled;
  final bool soundsEnabled;

  MedhaPreferences copyWith({
    MedhaCompanionType? companion,
    bool? enabled,
    bool? voiceEnabled,
    bool? soundsEnabled,
  }) {
    return MedhaPreferences(
      companion: companion ?? this.companion,
      enabled: enabled ?? this.enabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
    );
  }
}

class MedhaContext {
  const MedhaContext({
    required this.route,
    required this.screenType,
    required this.articleId,
    required this.articleTitle,
    required this.articleSummary,
    required this.articleBody,
    required this.visibleSection,
    required this.category,
    required this.author,
    required this.currentScrollSection,
    this.contentMode = MedhaContentMode.fullStory,
    this.contentLocale = 'en-IN',
    this.quickSummary = '',
    this.currentDeckCardIndex,
    this.currentDeckCardTitle = '',
    this.currentDeckCardText = '',
    this.allDeckCards = const [],
    this.keyNumbers = const [],
    this.whyItMatters = '',
    this.relatedArticleIds = const [],
  });

  final String route;
  final String screenType;
  final String articleId;
  final String articleTitle;
  final String articleSummary;
  final String articleBody;
  final String visibleSection;
  final String category;
  final String author;
  final String currentScrollSection;
  final MedhaContentMode contentMode;
  final String contentLocale;
  final String quickSummary;
  final int? currentDeckCardIndex;
  final String currentDeckCardTitle;
  final String currentDeckCardText;
  final List<String> allDeckCards;
  final List<String> keyNumbers;
  final String whyItMatters;
  final List<String> relatedArticleIds;

  Map<String, dynamic> toJson() => {
        'route': route,
        'screenType': screenType,
        'articleId': articleId,
        'articleTitle': articleTitle,
        'articleSummary': articleSummary,
        'contentMode': contentMode.name,
        'contentLocale': contentLocale,
        'quickSummary': quickSummary,
        'currentDeckCardIndex': currentDeckCardIndex,
        'currentDeckCardTitle': currentDeckCardTitle,
        'currentDeckCardText': currentDeckCardText,
        'allDeckCards': allDeckCards,
        'keyNumbers': keyNumbers,
        'whyItMatters': whyItMatters,
        'visibleSection': visibleSection,
        'category': category,
        'author': author,
        'currentScrollSection': currentScrollSection,
        'relatedArticleIds': relatedArticleIds,
      };
}

class MedhaConversationTurn {
  const MedhaConversationTurn({required this.role, required this.text});

  final String role;
  final String text;

  Map<String, String> toJson() => {'role': role, 'text': text};
}

class MedhaGroundedSection {
  const MedhaGroundedSection({required this.kind, required this.text});

  final MedhaGroundingKind kind;
  final String text;

  String get label => switch (kind) {
        MedhaGroundingKind.currentStory => 'FROM THIS STORY',
        MedhaGroundingKind.relatedBreakpoint => 'RELATED BREAKPOINT CONTEXT',
        MedhaGroundingKind.general => 'GENERAL EXPLANATION',
        MedhaGroundingKind.outOfScope => 'STORY SCOPE',
      };
}

class MedhaAnswer {
  const MedhaAnswer({
    required this.sections,
    required this.usedFallback,
    this.scope = MedhaScopeClassification.inScope,
  });

  final List<MedhaGroundedSection> sections;
  final bool usedFallback;
  final MedhaScopeClassification scope;

  bool get isOutOfScope =>
      scope == MedhaScopeClassification.outOfScope ||
      sections.any((section) => section.kind == MedhaGroundingKind.outOfScope);

  String get spokenText => sections.map((section) => section.text).join(' ');
}
