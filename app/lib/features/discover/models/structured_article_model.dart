import 'package:flutter/material.dart';
import '../../feed/models/post_model.dart';
import 'article_category.dart';

class KeyNumberItem {
  final String value;
  final String label;

  const KeyNumberItem({required this.value, required this.label});
}

class ExploreStoryItem {
  final String title;
  final String previewText;
  final IconData icon;
  final Widget expandedContent;

  const ExploreStoryItem({
    required this.title,
    required this.previewText,
    required this.icon,
    required this.expandedContent,
  });
}

class StructuredArticleData {
  final String id;
  final String category;
  final String headline;
  final String hook;
  final String? heroImage;
  final String authorName;
  final String? authorAvatar;
  final String? authorId;
  final bool isAuthorVerified;
  final int readTime;
  final String in20SecondsSummary;
  final List<KeyNumberItem> keyNumbers;
  final String whyItMatters;
  final List<ExploreStoryItem> exploreSections;
  final String? quoteText;
  final String? quoteSpeaker;
  final String? quoteRole;
  final List<String> takeaways;
  final String? audioUrl;
  final String audioStatus;
  final String contentLanguage;

  const StructuredArticleData({
    required this.id,
    required this.category,
    required this.headline,
    required this.hook,
    this.heroImage,
    required this.authorName,
    this.authorAvatar,
    this.authorId,
    this.isAuthorVerified = true,
    required this.readTime,
    required this.in20SecondsSummary,
    required this.keyNumbers,
    required this.whyItMatters,
    required this.exploreSections,
    this.quoteText,
    this.quoteSpeaker,
    this.quoteRole,
    required this.takeaways,
    this.audioUrl,
    this.audioStatus = 'unavailable',
    this.contentLanguage = 'en',
  });

  String get narrationFallbackText {
    final sections = exploreSections
        .map((section) => '${section.title}. ${section.previewText}')
        .where((part) => part.trim().isNotEmpty);
    return [
      headline,
      hook,
      in20SecondsSummary,
      whyItMatters,
      ...sections,
      ...takeaways,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).join('\n\n');
  }

  /// Reference Implementation: Matel Motion EV Powertrains story
  static StructuredArticleData get matelMotionSample {
    return const StructuredArticleData(
      id: 'matel_motion_reference',
      category: 'STARTUPS',
      headline:
          'Pune’s Matel Motion Raises ₹130 Cr for EV & Industrial Powertrains',
      hook:
          'Powering India’s shift to efficient, indigenous and sustainable mobility.',
      heroImage:
          'https://images.unsplash.com/photo-1558441719-67450807e90a?q=80&w=1200&auto=format&fit=crop',
      authorName: 'Manas Vignesh',
      authorAvatar:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop',
      authorId: 'manas_vignesh_uid',
      isAuthorVerified: true,
      readTime: 1,
      in20SecondsSummary:
          'Matel Motion, a Pune deep-tech startup founded in 2017, has secured ₹130 Cr Series B funding led by UC Impower with Catamaran to scale high-efficiency EV drive powertrains and industrial electric motors.',
      keyNumbers: [
        KeyNumberItem(value: '₹130 Cr', label: 'Funds Raised'),
        KeyNumberItem(value: '₹220 Cr', label: 'Total Funding'),
        KeyNumberItem(value: 'Pune', label: 'Headquarters'),
      ],
      whyItMatters:
          'As India accelerates EV adoption and industrial electrification, locally-made powertrains can reduce manufacturing costs, improve thermal resilience, and cut import dependence on foreign drive components.',
      quoteText:
          'Our goal is to build world-class, indigenous powertrain technology that elevates India from a net importer to a global exporter of electric drives.',
      quoteSpeaker: 'Nikhil Ramdas',
      quoteRole: 'Co-Founder & CEO, Matel Motion',
      exploreSections: [
        ExploreStoryItem(
          title: 'What Matel Builds',
          previewText:
              'High-torque synchronous motors & 98% efficient SiC drive controllers',
          icon: Icons.electric_bolt_rounded,
          expandedContent: Text(
            '• EV Synchronous Motors: Built specifically for Indian road and thermal conditions.\n'
            '• Silicon Carbide Controllers: Delivers 98% energy conversion efficiency.\n'
            '• Commercial Fleet Kits: Integrated drive powertrains for e-2/3 wheelers.\n'
            '• Industrial Machinery: Heavy-duty electric drives for manufacturing pumps.',
            style: TextStyle(height: 1.5, fontSize: 13),
          ),
        ),
        ExploreStoryItem(
          title: 'Who Invested',
          previewText: 'Led by UC Impower alongside Catamaran and Exfinity',
          icon: Icons.account_balance_rounded,
          expandedContent: Text(
            '• UC Impower (Lead Investor in Series B)\n'
            '• Catamaran (New Strategic Tech Fund Participant)\n'
            '• Exfinity Venture Partners (Existing Series A Investor)',
            style: TextStyle(height: 1.5, fontSize: 13),
          ),
        ),
        ExploreStoryItem(
          title: 'Where The Money Goes',
          previewText:
              'Capacity expansion, R&D labs, and OEM commercial partnerships',
          icon: Icons.alt_route_rounded,
          expandedContent: Text(
            '1. Capacity Expansion: Scaling up Pune assembly facility.\n'
            '2. Deep-Tech R&D Lab: Testing next-gen magnetless motor technology.\n'
            '3. OEM Partnerships: Securing supply contracts with Indian EV makers.',
            style: TextStyle(height: 1.5, fontSize: 13),
          ),
        ),
        ExploreStoryItem(
          title: 'Milestones & Timeline',
          previewText: 'Founded 2017 → Series A (\$4.5M) → Series B (₹130 Cr)',
          icon: Icons.timeline_rounded,
          expandedContent: Text(
            '• 2017: Company Founded in Pune\n'
            '• 2023: Series A Raised (\$4.5M)\n'
            '• 2025: New Megawatt Production Facility Commissioned\n'
            '• 2026: Series B ₹130 Cr Closed Successfully',
            style: TextStyle(height: 1.5, fontSize: 13),
          ),
        ),
      ],
      takeaways: [
        'Matel Motion raised ₹130 Cr Series B funding in Pune',
        'Cuts import reliance on foreign EV drive motors',
        '98% powertrain energy efficiency achieved',
        'Factory scaling up for major commercial OEM partnerships',
      ],
    );
  }

  /// Synthesizes a structured article from any generic PostModel
  factory StructuredArticleData.fromPostModel(PostModel post,
      {String language = 'en'}) {
    if (post.schemaVersion >= 2) {
      final loc = post.publishedArticle.languages[language];
      final isLoc = loc != null && loc.translationStatus == 'ready';
      final qb = isLoc ? loc.quickBrief : post.quickBrief;
      final full = isLoc ? loc.fullArticle : post.fullArticle;

      // A globally selected language may not be ready on this article yet.
      // In that case both the text and remote narration consistently fall
      // back to English; a ready selected language always uses its own URL.
      final effectiveLoc = isLoc ? loc : post.publishedArticle.languages['en'];
      final audioStatus = effectiveLoc?.audioStatus ?? 'unavailable';
      final audioUrl = audioStatus == 'ready' ? effectiveLoc?.audioUrl : null;
      final effectiveLanguage = isLoc ? language : 'en';

      if (full == null) {
        debugPrint(
          'ARTICLE_RENDER_ERROR [${post.id}]: full_article missing for schema v${post.schemaVersion}',
        );
        return StructuredArticleData(
          id: post.id,
          category: categoryForPost(post),
          headline: qb?.headline.isNotEmpty == true
              ? qb!.headline
              : (isLoc ? loc.title : post.title),
          hook: qb?.quickSummary ?? '',
          heroImage: post.imageUrl,
          authorName: post.authorName,
          authorAvatar: post.authorAvatar,
          authorId: post.authorId,
          isAuthorVerified: post.isAuthorVerified,
          readTime: post.estimatedReadTime,
          in20SecondsSummary: qb?.quickSummary ?? '',
          keyNumbers: const [],
          whyItMatters: qb?.quickSummary ?? '',
          exploreSections: const [],
          takeaways: const [],
          audioUrl: audioUrl,
          audioStatus: audioStatus,
          contentLanguage: effectiveLanguage,
        );
      }

      return StructuredArticleData(
        id: post.id,
        category: categoryForPost(post),
        headline: full.headline.isNotEmpty
            ? full.headline
            : (qb?.headline ?? (isLoc ? loc.title : post.title)),
        hook: full.hook.isNotEmpty ? full.hook : (qb?.quickSummary ?? ''),
        heroImage: post.imageUrl,
        authorName: post.authorName,
        authorAvatar: post.authorAvatar,
        authorId: post.authorId,
        isAuthorVerified: post.isAuthorVerified,
        readTime: post.estimatedReadTime,
        in20SecondsSummary: full.in20Seconds.isNotEmpty
            ? full.in20Seconds
            : (qb?.quickSummary ?? ''),
        keyNumbers: full.keyStats
            .map((stat) => KeyNumberItem(value: stat.value, label: stat.label))
            .toList(),
        whyItMatters: full.whyThisMatters.isNotEmpty
            ? full.whyThisMatters
            : (qb?.quickSummary ?? ''),
        audioUrl: audioUrl,
        audioStatus: audioStatus,
        contentLanguage: effectiveLanguage,
        exploreSections: [
          if (full.whatHappened.isNotEmpty)
            ExploreStoryItem(
              title: 'What Happened',
              previewText: full.whatHappened,
              icon: Icons.article_outlined,
              expandedContent: Text(
                full.whatHappened,
                style: const TextStyle(height: 1.5, fontSize: 13),
              ),
            ),
          ...full.exploreSections.map(
            (section) => ExploreStoryItem(
              title: section.title,
              previewText: section.summary,
              icon: Icons.notes_rounded,
              expandedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (section.content.isNotEmpty)
                    Text(
                      section.content,
                      style: const TextStyle(height: 1.5, fontSize: 13),
                    ),
                  ...section.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.title.isNotEmpty)
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          if (item.description.isNotEmpty)
                            Text(
                              item.description,
                              style: const TextStyle(height: 1.5, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (full.biggerPicture.isNotEmpty)
            ExploreStoryItem(
              title: 'The Bigger Picture',
              previewText: full.biggerPicture,
              icon: Icons.public_rounded,
              expandedContent: Text(
                full.biggerPicture,
                style: const TextStyle(height: 1.5, fontSize: 13),
              ),
            ),
        ],
        quoteText: full.quote?.text,
        quoteSpeaker: full.quote?.speaker,
        quoteRole: full.quote?.role,
        takeaways: full.takeaways,
      );
    }

    if (post.title.toLowerCase().contains('matel') ||
        post.id == 'matel_motion_reference') {
      final sample = matelMotionSample;
      return StructuredArticleData(
        id: post.id,
        category: sample.category,
        headline: post.title.isNotEmpty ? post.title : sample.headline,
        hook: sample.hook,
        heroImage: post.imageUrl ?? sample.heroImage,
        authorName:
            post.authorName.isNotEmpty ? post.authorName : sample.authorName,
        authorAvatar: post.authorAvatar ?? sample.authorAvatar,
        authorId: post.authorId ?? sample.authorId,
        isAuthorVerified: post.isAuthorVerified,
        readTime: post.estimatedReadTime > 0
            ? post.estimatedReadTime
            : sample.readTime,
        in20SecondsSummary: sample.in20SecondsSummary,
        keyNumbers: sample.keyNumbers,
        whyItMatters: sample.whyItMatters,
        exploreSections: sample.exploreSections,
        quoteText: sample.quoteText,
        quoteSpeaker: sample.quoteSpeaker,
        quoteRole: sample.quoteRole,
        takeaways: sample.takeaways,
      );
    }

    final textBlocks = post.blocks
        .whereType<Map<String, dynamic>>()
        .where((b) => b['type'] == 'text' && b['content'] != null)
        .map((b) => b['content'].toString().trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final firstText = textBlocks.isNotEmpty
        ? textBlocks.first
        : 'A quick visual overview of this campus report.';
    final fullText = textBlocks.join('\n\n');

    return StructuredArticleData(
      id: post.id,
      category: categoryForPost(post),
      headline: post.title,
      hook: firstText.length > 90
          ? '${firstText.substring(0, 90)}...'
          : firstText,
      heroImage: post.imageUrl,
      authorName:
          post.authorName.isNotEmpty ? post.authorName : 'Breakpoint Member',
      authorAvatar: post.authorAvatar,
      authorId: post.authorId,
      isAuthorVerified: post.isAuthorVerified,
      readTime: post.estimatedReadTime > 0 ? post.estimatedReadTime : 1,
      in20SecondsSummary: firstText,
      keyNumbers: const [
        KeyNumberItem(value: '1 Min', label: 'Read Time'),
        KeyNumberItem(value: '100%', label: 'Verified'),
        KeyNumberItem(value: 'Breakpoint', label: 'Publication'),
      ],
      whyItMatters: fullText.length > 120
          ? '${fullText.substring(0, 120)}...'
          : firstText,
      exploreSections: [
        ExploreStoryItem(
          title: 'Key Story Breakdown',
          previewText: 'Read main points and verified campus information',
          icon: Icons.notes_rounded,
          expandedContent: Text(
            fullText.isNotEmpty
                ? fullText
                : 'Verified content published on Breakpoint network.',
            style: const TextStyle(height: 1.5, fontSize: 13),
          ),
        ),
      ],
      takeaways: const [
        'Verified story content reviewed on Breakpoint',
        'Published by authentic author',
      ],
    );
  }
}
