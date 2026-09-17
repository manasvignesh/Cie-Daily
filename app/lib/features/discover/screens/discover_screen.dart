import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/breakpoint_logo.dart';
import '../../../core/theme/responsive.dart';
import '../../feed/models/post_model.dart';
import '../models/article_image_resolver.dart';
import '../models/structured_article_model.dart';
import '../models/article_category.dart';
import '../providers/discover_provider.dart';
import '../widgets/featured_brief_deck.dart';
import '../../../core/widgets/indicators/error_state.dart';
import '../widgets/quick_brief_sheet.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = discoverCategories;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openQuickBriefSheet(List<PostModel> featuredPosts, int initialIndex) {
    QuickBriefSheet.show(
      context,
      featuredPosts: featuredPosts,
      initialIndex: initialIndex,
      onOpenFullArticle: (post) {
        context.pushNamed(
          'articleDetail',
          pathParameters: {'id': post.id},
          extra: post,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(discoverArticlesProvider);
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final borderColor = AppTheme.cardBorderColor(context);
    final inputFill = AppTheme.inputFillColor(context);
    final accent = AppTheme.accentColor(context);
    final metalHighlight = AppTheme.metalHighlightColor(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.atmosphereGradient(context),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── APP HEADER & SEARCH BAR ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Discover',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: primaryText,
                                  fontFamily: 'Sora',
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const BreakpointDotMarker(size: 8),
                            ],
                          ),
                          const BreakpointLogo(
                            fontSize: 14,
                            showLockup: false,
                            showTagline: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fresh ideas for curious minds',
                        style: TextStyle(
                          fontSize: 15,
                          color: secondaryText,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Clean Search Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                              color: primaryText,
                              fontSize: 15,
                              fontFamily: 'Inter'),
                          decoration: InputDecoration(
                            hintText: 'Find a story worth your time',
                            hintStyle: TextStyle(
                                color: secondaryText.withValues(alpha: 0.7),
                                fontSize: 14),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: secondaryText, size: 20),
                            filled: true,
                            fillColor: inputFill,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: borderColor, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: borderColor, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: accent, width: 1.5),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Pill Filters
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSel = _selectedCategory == cat;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 190),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: isSel
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.24),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : const [],
                              ),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSel,
                                selectedColor:
                                    AppTheme.selectedSurfaceColor(context),
                                backgroundColor: inputFill,
                                side: BorderSide(
                                  color:
                                      isSel ? metalHighlight : borderColor,
                                  width: 1,
                                ),
                                labelStyle: TextStyle(
                                  color: isSel ? primaryText : secondaryText,
                                  fontWeight:
                                      isSel ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() => _selectedCategory = cat);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── CONTENT FEED (FEATURED BRIEF DECK + EDITORIAL BRIEF CARDS) ─────
              articlesAsync.when(
                data: (allArticles) {
                  final query = _searchController.text.trim().toLowerCase();
                  var filtered = allArticles;

                  if (_selectedCategory != 'All') {
                    filtered = filtered
                        .where((a) => categoryForPost(a) == _selectedCategory)
                        .toList();
                  }

                  if (query.isNotEmpty) {
                    filtered = filtered
                        .where((a) => a.title.toLowerCase().contains(query))
                        .toList();
                  }

                  if (filtered.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 60, horizontal: 20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.auto_stories_outlined,
                                  size: 48,
                                  color: secondaryText.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'No Stories Found',
                                style: TextStyle(
                                    color: primaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try adjusting your search or category filters.',
                                style: TextStyle(
                                    color: secondaryText, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Keep the full filtered result in the deck so readers can
                  // swipe continuously through every available story.
                  final featuredDeckItems = filtered;
                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20,
                        AppResponsive.overlayBottomOffset(context) + 20.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── FEATURED BRIEFS DECK SECTION ───────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Featured Briefs',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: primaryText,
                                fontFamily: 'Sora',
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Swipe through stories worth your time',
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryText,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 16),
                            FeaturedBriefDeck(
                              posts: featuredDeckItems,
                              onCardTap: (post, index) {
                                _openQuickBriefSheet(featuredDeckItems, index);
                              },
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),

                        // ── LATEST EDITORIAL BRIEFS SECTION ─────────────────
                        Text(
                          'Latest Editorial Briefs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                            fontFamily: 'Sora',
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Feed Article List (showing all stories or remaining)
                        ...filtered.map((article) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildEditorialCard(context, article),
                            )),
                      ]),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryOrange)),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: ErrorState(
                    message:
                        "We couldn't load stories. Check your connection and try again.",
                    onRetry: () => ref.invalidate(discoverArticlesProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── EDITORIAL CARD COMPONENT FOR LATEST EDITORIAL BRIEFS FEED ─────────────
  Widget _buildEditorialCard(BuildContext context, PostModel article) {
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final borderColor = AppTheme.materialEdgeColor(context);
    final metalHighlight = AppTheme.metalHighlightColor(context);
    final structuredData = StructuredArticleData.fromPostModel(article);

    return InkWell(
      onTap: () => context.pushNamed(
        'articleDetail',
        pathParameters: {'id': article.id},
        extra: article,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.premiumSurfaceGradient(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color.lerp(borderColor, metalHighlight, 0.12)!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              metalHighlight.withValues(alpha: 0.055),
              Colors.transparent,
              Colors.transparent,
            ],
            stops: const [0, 0.18, 1],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      categoryForPost(article).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    structuredData.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                      fontFamily: 'Sora',
                      height: 1.25,
                    ),
                  ),
                  if (structuredData.hook.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      structuredData.hook.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryText,
                        fontFamily: 'Inter',
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        structuredData.authorName,
                        style: TextStyle(
                            fontSize: 12,
                            color: secondaryText,
                            fontFamily: 'Inter'),
                      ),
                      Text(' · ', style: TextStyle(color: secondaryText)),
                      Text(
                        '${structuredData.readTime} min read',
                        style: TextStyle(
                            fontSize: 12,
                            color: secondaryText,
                            fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (structuredData.heroImage != null &&
                structuredData.heroImage!.isNotEmpty) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  structuredData.heroImage!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.network(
                    fallbackArticleImage(
                      title: structuredData.headline,
                      category: structuredData.category,
                    ),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: AppTheme.inputFillColor(context),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
