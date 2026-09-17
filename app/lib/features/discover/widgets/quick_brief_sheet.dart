import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../feed/data/firebase_feed_repository.dart';
import '../../feed/models/post_model.dart';
import '../../lists/widgets/add_to_list_sheet.dart';
import '../models/structured_article_model.dart';
import 'language_picker_sheet.dart';
import 'premium_audio_player.dart';

class QuickBriefSheet extends ConsumerStatefulWidget {
  final List<PostModel> featuredPosts;
  final int initialIndex;
  final Function(PostModel post) onOpenFullArticle;

  const QuickBriefSheet({
    super.key,
    required this.featuredPosts,
    required this.initialIndex,
    required this.onOpenFullArticle,
  });

  static void show(
    BuildContext context, {
    required List<PostModel> featuredPosts,
    required int initialIndex,
    required Function(PostModel post) onOpenFullArticle,
  }) {
    if (featuredPosts.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickBriefSheet(
        featuredPosts: featuredPosts,
        initialIndex: initialIndex,
        onOpenFullArticle: onOpenFullArticle,
      ),
    );
  }

  @override
  ConsumerState<QuickBriefSheet> createState() => _QuickBriefSheetState();
}

class _QuickBriefSheetState extends ConsumerState<QuickBriefSheet> {
  late PageController _pageController;
  late int _currentIndex;
  late List<_QuickBriefPageData> _pages;
  final Map<String, bool> _savedStates = {};

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialIndex.clamp(0, widget.featuredPosts.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _pages = widget.featuredPosts
        .map((p) => _buildPageData(p, ref.read(contentLanguageProvider)))
        .toList(growable: false);
    for (final post in widget.featuredPosts) {
      _savedStates[post.id] = post.isBookmarkedByCurrentUser;
    }
  }

  @override
  void didUpdateWidget(covariant QuickBriefSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.featuredPosts, widget.featuredPosts)) return;

    final activeId = oldWidget.featuredPosts.isEmpty
        ? null
        : oldWidget
            .featuredPosts[
                _currentIndex.clamp(0, oldWidget.featuredPosts.length - 1)]
            .id;
    _pages = widget.featuredPosts
        .map((p) => _buildPageData(p, ref.read(contentLanguageProvider)))
        .toList(growable: false);
    for (final post in widget.featuredPosts) {
      _savedStates.putIfAbsent(post.id, () => post.isBookmarkedByCurrentUser);
    }
    if (_pages.isEmpty) return;

    final retainedIndex = _pages.indexWhere((page) => page.post.id == activeId);
    _currentIndex = (retainedIndex >= 0 ? retainedIndex : _currentIndex)
        .clamp(0, _pages.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleSave(PostModel post) async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save stories.')),
      );
      return;
    }

    final current = _savedStates[post.id] ?? post.isBookmarkedByCurrentUser;
    final next = !current;

    setState(() {
      _savedStates[post.id] = next;
    });

    try {
      await ref.read(feedRepositoryProvider).toggleBookmark(post.id, next);
      if (mounted && next) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved'),
            action: SnackBarAction(
              label: 'Add to List',
              onPressed: () => showAddToListSheet(context, post.id),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _savedStates[post.id] = current;
        });
      }
    }
  }

  // ── DATA NORMALIZATION HELPERS ─────────────────────────────────────────────

  /// Cleans raw AI headings (e.g. "What happened:", "Why it matters:", etc.)
  /// into ONE continuous, concise 40-70 word summary paragraph.
  String _normalizeSummary(String rawSummary) {
    if (rawSummary.trim().isEmpty) return '';

    String text = rawSummary
        .replaceAll(
            RegExp(
                r'(What happened|Why it matters|Open model|Focus|Ecosystem signal|Key takeaway):?',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'^\s*[\d\.\-\•\*]+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return text;
  }

  /// Extracts 3 clean bullet facts, removing prefixes like "•", "-", "✓".
  List<String> _normalizeTakeaways(List<String> rawTakeaways) {
    if (rawTakeaways.isEmpty) return [];

    return rawTakeaways
        .take(3)
        .map((item) {
          return item
              .replaceAll(RegExp(r'^[\s\•\-\✓\*]+'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// Filters Key Numbers so read-time metadata ("1 Min", "min read") is excluded.
  KeyNumberItem? _normalizeKeyNumber(List<KeyNumberItem> keyNumbers) {
    if (keyNumbers.isEmpty) return null;

    final first = keyNumbers.first;
    final val = first.value.toLowerCase().trim();
    final label = first.label.toLowerCase().trim();

    // Exclude read-time metadata
    if (val.contains('min') ||
        label.contains('min') ||
        label.contains('read')) {
      return null;
    }

    return first;
  }

  _QuickBriefPageData _buildPageData(PostModel post, String language) {
    final legacyData = post.schemaVersion < 2
        ? StructuredArticleData.fromPostModel(post, language: language)
        : null;

    final loc = post.publishedArticle.languages[language];
    final isLoc = loc != null && loc.translationStatus == 'ready';
    final effectiveLanguage = isLoc ? language : 'en';
    final effectiveLoc = isLoc ? loc : post.publishedArticle.languages['en'];
    final quick = isLoc ? loc.quickBrief : post.quickBrief;
    final audioStatus = effectiveLoc?.audioStatus ?? 'unavailable';
    final audioUrl = audioStatus == 'ready' ? effectiveLoc?.audioUrl : null;

    final keyNumber = post.schemaVersion >= 2
        ? (quick?.keyNumber == null
            ? null
            : KeyNumberItem(
                value: quick!.keyNumber!.value,
                label: quick.keyNumber!.label,
              ))
        : _normalizeKeyNumber(legacyData!.keyNumbers);

    return _QuickBriefPageData(
      post: post,
      category: post.schemaVersion >= 2
          ? (quick?.category ?? '')
          : legacyData!.category,
      headline: post.schemaVersion >= 2
          ? (quick?.headline ?? '')
          : legacyData!.headline,
      summary: _normalizeSummary(
        post.schemaVersion >= 2
            ? (quick?.quickSummary ?? '')
            : legacyData!.in20SecondsSummary,
      ),
      facts: _normalizeTakeaways(
        post.schemaVersion >= 2
            ? (quick?.threeThingsToKnow ?? const [])
            : legacyData!.takeaways,
      ),
      keyNumber: keyNumber,
      audioStatus: audioStatus,
      audioUrl: audioUrl,
      language: effectiveLanguage,
    );
  }

  @override
  Widget build(BuildContext context) {
    _pages = widget.featuredPosts
        .map((p) => _buildPageData(p, ref.watch(contentLanguageProvider)))
        .toList(growable: false);

    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final borderColor = AppTheme.cardBorderColor(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenHeight * 0.82,
      decoration: BoxDecoration(
        gradient: AppTheme.raisedSurfaceGradient(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 1. DRAG HANDLE & HEADER BAR (CLEAN SPACING, NO BULKY CONTAINER) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryText.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Position Indicator (e.g. 1 of 5)
                    Text(
                      '${_currentIndex + 1} of ${widget.featuredPosts.length}',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            (_savedStates[widget
                                        .featuredPosts[_currentIndex].id] ??
                                    false)
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: (_savedStates[widget
                                        .featuredPosts[_currentIndex].id] ??
                                    false)
                                ? AppTheme.primaryOrange
                                : primaryText,
                            size: 22,
                          ),
                          onPressed: () =>
                              _toggleSave(widget.featuredPosts[_currentIndex]),
                          tooltip: 'Save Brief',
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: primaryText, size: 22),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close Brief',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: borderColor, height: 1),

          // ── SWIPEABLE QUICK BRIEF PAGES ──────────────────────────────────
          Expanded(
            child: PageView.builder(
              key: const PageStorageKey<String>('quick-brief-pages'),
              controller: _pageController,
              allowImplicitScrolling: true,
              physics: const PageScrollPhysics(),
              itemCount: _pages.length,
              onPageChanged: (index) {
                HapticFeedback.lightImpact();
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final page = _pages[index];
                final post = page.post;
                final category = page.category;
                final headline = page.headline;
                final normalizedSummary = page.summary;
                final normalizedFacts = page.facts;
                final keyNum = page.keyNumber;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. CATEGORY TAG (SMALL UPPERCASE TEXT, NO GIANT PILL)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.8,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final availableLanguages = ['en'];
                              page.post.publishedArticle.languages
                                  .forEach((k, v) {
                                if (k != 'en' &&
                                    v.translationStatus == 'ready') {
                                  availableLanguages.add(k);
                                }
                              });
                              return LanguagePickerButton(
                                availableLanguageIds: availableLanguages,
                                compact: true,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 4. HEADLINE (DIRECTLY BELOW CATEGORY, NO CONTAINER)
                      Text(
                        headline,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Outfit',
                          height: 1.22,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 18),

                      // 5. IN 20 SECONDS (ONLY MAJOR HIGHLIGHTED SUMMARY BOX)
                      if (normalizedSummary.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryOrange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: AppTheme.primaryOrange
                                    .withValues(alpha: 0.25),
                                width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.bolt_rounded,
                                      color: AppTheme.primaryOrange, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'IN 20 SECONDS',
                                    style: TextStyle(
                                      color: AppTheme.primaryOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (page.audioUrl != null)
                                PremiumAudioPlayer(
                                  audioUrl: page.audioUrl!,
                                  title: headline,
                                  language: page.language,
                                  audioStatus: page.audioStatus,
                                  fallbackText: page.fallbackText,
                                  compact: true,
                                )
                              else
                                RemoteNarrationUnavailable(
                                  language: page.language,
                                  audioStatus: page.audioStatus,
                                  fallbackText: page.fallbackText,
                                  compact: true,
                                ),
                              const SizedBox(height: 10),
                              Text(
                                normalizedSummary,
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.48,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // 6. 3 THINGS TO KNOW (CLEAN VERTICAL BULLETS, NO INDIVIDUAL BOXES)
                      if (normalizedFacts.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                color: AppTheme.primaryOrange, size: 16),
                            SizedBox(width: 6),
                            Text(
                              '3 THINGS TO KNOW',
                              style: TextStyle(
                                color: AppTheme.primaryOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...normalizedFacts.map((fact) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_rounded,
                                    color: AppTheme.primaryOrange, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    fact,
                                    style: TextStyle(
                                      color: primaryText,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.38,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],

                      // 7. KEY NUMBER (RENDERED ONLY IF A GENUINELY VALID METRIC EXISTS)
                      if (keyNum != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 18),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                keyNum.value,
                                style: const TextStyle(
                                  color: AppTheme.primaryOrange,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Outfit',
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                keyNum.label,
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 8. READ FULL STORY CTA BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onOpenFullArticle(post);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Read Full Story',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickBriefPageData {
  final PostModel post;
  final String category;
  final String headline;
  final String summary;
  final List<String> facts;
  final KeyNumberItem? keyNumber;
  final String? audioUrl;
  final String audioStatus;
  final String language;
  String get fallbackText => [
        headline,
        summary,
        ...facts,
        if (keyNumber != null) '${keyNumber!.value} ${keyNumber!.label}',
      ]
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .join('\n\n');

  const _QuickBriefPageData({
    required this.post,
    required this.category,
    required this.headline,
    required this.summary,
    required this.facts,
    required this.keyNumber,
    required this.audioUrl,
    required this.audioStatus,
    required this.language,
  });
}
