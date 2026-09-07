import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../feed/data/firebase_feed_repository.dart';
import '../../feed/models/post_model.dart';
import '../models/article_image_resolver.dart';
import '../models/structured_article_model.dart';
import '../models/article_category.dart';

class FeaturedBriefDeck extends ConsumerStatefulWidget {
  final List<PostModel> posts;
  final Function(PostModel post, int index) onCardTap;

  const FeaturedBriefDeck({
    super.key,
    required this.posts,
    required this.onCardTap,
  });

  @override
  ConsumerState<FeaturedBriefDeck> createState() => _FeaturedBriefDeckState();
}

class _FeaturedBriefDeckState extends ConsumerState<FeaturedBriefDeck> {
  static const _viewportFraction = 0.92;

  late final PageController _pageController;
  late final ValueNotifier<int> _currentIndex;
  late List<_BriefDeckPresentation> _items;
  final Map<String, bool> _savedStates = {};

  @override
  void initState() {
    super.initState();
    _items = _present(widget.posts);
    _currentIndex = ValueNotifier<int>(0);
    _pageController = PageController(viewportFraction: _viewportFraction);
    _syncSavedStates(widget.posts);
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheAround(0));
  }

  @override
  void didUpdateWidget(covariant FeaturedBriefDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.posts, widget.posts)) return;

    final sameOrder = oldWidget.posts.length == widget.posts.length &&
        List.generate(
          widget.posts.length,
          (index) => oldWidget.posts[index].id == widget.posts[index].id,
          growable: false,
        ).every((matches) => matches);
    if (sameOrder) {
      _items = _present(widget.posts);
      _syncSavedStates(widget.posts);
      return;
    }

    final oldIndex =
        _items.isEmpty ? 0 : _currentIndex.value.clamp(0, _items.length - 1);
    final activeId = _items.isEmpty ? null : _items[oldIndex].post.id;
    _items = _present(widget.posts);
    _syncSavedStates(widget.posts);

    final retainedIndex = activeId == null
        ? 0
        : _items.indexWhere((item) => item.post.id == activeId);
    final maximumIndex = (_items.length - 1).clamp(0, 1 << 20);
    final nextIndex =
        (retainedIndex >= 0 ? retainedIndex : oldIndex).clamp(0, maximumIndex);
    _currentIndex.value = nextIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(nextIndex);
      _precacheAround(nextIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  List<_BriefDeckPresentation> _present(List<PostModel> posts) {
    return posts.map(_BriefDeckPresentation.fromPost).toList(growable: false);
  }

  void _syncSavedStates(List<PostModel> posts) {
    for (final post in posts) {
      _savedStates.putIfAbsent(post.id, () => post.isBookmarkedByCurrentUser);
    }
  }

  void _onPageChanged(int index) {
    _currentIndex.value = index;
    HapticFeedback.selectionClick();
    _precacheAround(index);
  }

  void _precacheAround(int index) {
    if (!mounted || _items.isEmpty) return;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final decodeWidth =
        (MediaQuery.sizeOf(context).width * devicePixelRatio).round();

    for (final candidate in <int>[index - 1, index + 1]) {
      if (candidate < 0 || candidate >= _items.length) continue;
      final imageUrl = _items[candidate].post.imageUrl;
      if (imageUrl == null || imageUrl.isEmpty) continue;
      precacheImage(
        CachedNetworkImageProvider(imageUrl, maxWidth: decodeWidth),
        context,
        onError: (_, __) {},
      );
    }
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
    setState(() => _savedStates[post.id] = next);

    try {
      await ref.read(feedRepositoryProvider).toggleBookmark(post.id, next);
    } catch (_) {
      if (mounted) setState(() => _savedStates[post.id] = current);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final accessibilityGrowth =
        ((textScale - 1).clamp(0.0, 1.0) * 96).roundToDouble();

    return Column(
      children: [
        SizedBox(
          height: 372 + accessibilityGrowth,
          child: PageView.builder(
            key: const PageStorageKey<String>('featured-brief-deck'),
            controller: _pageController,
            padEnds: false,
            clipBehavior: Clip.none,
            allowImplicitScrolling: true,
            physics: const PageScrollPhysics(),
            itemCount: _items.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final item = _items[index];
              return _DeckPageMotion(
                controller: _pageController,
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 8),
                  child: RepaintBoundary(
                    key:
                        ValueKey<String>('featured-brief-page-${item.post.id}'),
                    child: _BriefDeckCard(
                      presentation: item,
                      isSaved: _savedStates[item.post.id] ??
                          item.post.isBookmarkedByCurrentUser,
                      onTap: () => widget.onCardTap(item.post, index),
                      onSave: () => _toggleSave(item.post),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<int>(
          valueListenable: _currentIndex,
          builder: (context, current, _) => _DeckProgressIndicator(
            total: _items.length,
            current: current,
            onPageRequested: (index) {
              if (!_pageController.hasClients ||
                  _pageController.position.isScrollingNotifier.value) {
                return;
              }
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeckPageMotion extends StatelessWidget {
  final PageController controller;
  final int index;
  final Widget child;

  const _DeckPageMotion({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final page =
            controller.hasClients && controller.position.hasContentDimensions
                ? (controller.page ?? controller.initialPage.toDouble())
                : controller.initialPage.toDouble();
        final distance = (page - index).abs().clamp(0.0, 1.0);
        final scale = 1.0 - (distance * 0.025);

        return Transform.translate(
          offset: Offset(0, distance * 7),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.centerLeft,
            child: child,
          ),
        );
      },
    );
  }
}

class _BriefDeckPresentation {
  final PostModel post;
  final String category;
  final String headline;
  final String hook;

  const _BriefDeckPresentation({
    required this.post,
    required this.category,
    required this.headline,
    required this.hook,
  });

  factory _BriefDeckPresentation.fromPost(PostModel post) {
    if (post.schemaVersion >= 2) {
      final quick = post.quickBrief;
      return _BriefDeckPresentation(
        post: post,
        category: categoryForPost(post),
        headline: quick?.headline.trim().isNotEmpty == true
            ? quick!.headline.trim()
            : post.title,
        hook: quick?.quickSummary.trim() ?? '',
      );
    }

    final legacy = StructuredArticleData.fromPostModel(post);
    return _BriefDeckPresentation(
      post: post,
      category: categoryForPost(post),
      headline: legacy.headline,
      hook: legacy.hook,
    );
  }
}

class _BriefDeckCard extends StatelessWidget {
  final _BriefDeckPresentation presentation;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _BriefDeckCard({
    required this.presentation,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final post = presentation.post;
    final isDark = AppTheme.isDark(context);
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final cardColor = AppTheme.cardColor(context);
    final decodeWidth = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .round();

    return Semantics(
      button: true,
      label: '${presentation.headline}. Open quick brief.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.09),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DeckHero(
                    imageUrl: post.imageUrl,
                    category: presentation.category,
                    title: presentation.headline,
                    decodeWidth: decodeWidth,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            presentation.headline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Outfit',
                              height: 1.12,
                              letterSpacing: -0.45,
                            ),
                          ),
                          if (presentation.hook.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              presentation.hook,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                                height: 1.35,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule_rounded,
                                        size: 15, color: secondaryText),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        '${post.estimatedReadTime} min brief',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: secondaryText,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                    if (MediaQuery.textScalerOf(context)
                                            .scale(1) <=
                                        1.3) ...[
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.swipe_rounded,
                                        size: 15,
                                        color: secondaryText.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Swipe',
                                        style: TextStyle(
                                          color: secondaryText.withValues(
                                            alpha: 0.85,
                                          ),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: isSaved
                                    ? 'Remove saved story'
                                    : 'Save story',
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    color: isSaved
                                        ? AppTheme.primaryOrange
                                        : secondaryText,
                                    size: 22,
                                  ),
                                  onPressed: onSave,
                                  tooltip: isSaved ? 'Saved' : 'Save story',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckHero extends StatelessWidget {
  final String? imageUrl;
  final String category;
  final String title;
  final int decodeWidth;

  const _DeckHero({
    required this.imageUrl,
    required this.category,
    required this.title,
    required this.decodeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final fallback = AppTheme.isDark(context)
        ? const Color(0xFF25232A)
        : const Color(0xFFECE8E3);

    return SizedBox(
      height: 164,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              memCacheWidth: decodeWidth,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 120),
              fadeOutDuration: const Duration(milliseconds: 80),
              placeholder: (_, __) => ColoredBox(color: fallback),
              errorWidget: (_, __, ___) => Image.network(
                fallbackArticleImage(title: title, category: category),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(color: fallback),
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: fallback,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryOrange.withValues(alpha: 0.18),
                    fallback,
                  ],
                ),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 42,
                color: AppTheme.primaryOrange.withValues(alpha: 0.65),
              ),
            ),
          if (hasImage)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99000000)],
                  stops: [0.48, 1],
                ),
              ),
            ),
          Positioned(
            left: 16,
            bottom: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: hasImage
                    ? Colors.black.withValues(alpha: 0.58)
                    : AppTheme.primaryOrange.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  category.isEmpty ? 'CIE DAILY' : category.toUpperCase(),
                  style: TextStyle(
                    color: hasImage ? Colors.white : AppTheme.primaryOrange,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 0.75,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckProgressIndicator extends StatelessWidget {
  final int total;
  final int current;
  final ValueChanged<int> onPageRequested;

  const _DeckProgressIndicator({
    required this.total,
    required this.current,
    required this.onPageRequested,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox(height: 20);

    final secondaryText = AppTheme.secondaryTextColor(context);
    return Semantics(
      label: 'Story ${current + 1} of $total',
      child: Row(
        key: const ValueKey<String>('featured-brief-indicator'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const ValueKey<String>('featured-brief-previous'),
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            color: secondaryText,
            onPressed: current > 0 ? () => onPageRequested(current - 1) : null,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Previous story',
          ),
          SizedBox(
            width: 88,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: (current + 1) / total,
                backgroundColor: secondaryText.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${current + 1} / $total',
            key: const ValueKey<String>('featured-brief-position'),
            style: TextStyle(
              color: secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          IconButton(
            key: const ValueKey<String>('featured-brief-next'),
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            color: secondaryText,
            onPressed:
                current < total - 1 ? () => onPageRequested(current + 1) : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            tooltip: 'Next story',
          ),
        ],
      ),
    );
  }
}
