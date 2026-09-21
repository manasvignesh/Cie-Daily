import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/sharing/breakpoint_links.dart';
import '../../../core/widgets/breakpoint_share_sheet.dart';
import '../../feed/data/firebase_feed_repository.dart';
import '../../feed/models/post_model.dart';
import '../../feed/widgets/comments_bottom_sheet.dart';
import '../../user/data/firebase_user_repository.dart';
import '../models/structured_article_model.dart';
import '../providers/discover_provider.dart';
import '../widgets/article_components.dart';
import '../widgets/language_picker_sheet.dart';
import '../../lists/widgets/add_to_list_sheet.dart';
import '../../medha/models/medha_models.dart';
import '../../medha/providers/medha_behavior_controller.dart';
import '../../medha/providers/medha_context_provider.dart';
import '../../medha/providers/medha_preferences_provider.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final String? articleId;
  final PostModel? initialArticle;

  const ArticleDetailScreen({
    super.key,
    this.articleId,
    this.initialArticle,
  });

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  double _readingProgress = 0.0;
  bool? _isSaved;
  bool _saving = false;
  DateTime _lastMedhaScrollReaction = DateTime.fromMillisecondsSinceEpoch(0);
  MedhaContext? _previousMedhaContext;
  final Object _medhaContextOwner = Object();
  ProviderContainer? _providerContainer;
  String? _scheduledMedhaContextSignature;
  String? _publishedMedhaContextSignature;

  @override
  void initState() {
    super.initState();
    _previousMedhaContext = ref.read(medhaActiveContextProvider);
    if (widget.initialArticle != null) {
      _isSaved = widget.initialArticle!.isBookmarkedByCurrentUser;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerContainer ??= ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    final container = _providerContainer;
    final previous = _previousMedhaContext;
    if (container != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        container.read(medhaActiveContextProvider.notifier).release(
              owner: _medhaContextOwner,
              restore: previous,
            );
      });
    }
    super.dispose();
  }

  void _scheduleMedhaContextPublication(MedhaContext medhaContext) {
    final signature = MedhaActiveContextController.signatureOf(medhaContext);
    if (_publishedMedhaContextSignature == signature) {
      _scheduledMedhaContextSignature = null;
      return;
    }
    if (_scheduledMedhaContextSignature == signature) {
      return;
    }
    _scheduledMedhaContextSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledMedhaContextSignature != signature) return;
      ref.read(medhaActiveContextProvider.notifier).publish(
            owner: _medhaContextOwner,
            context: medhaContext,
          );
      _publishedMedhaContextSignature = signature;
      _scheduledMedhaContextSignature = null;
    });
  }

  Future<void> _toggleSaved(PostModel article) async {
    if (_saving) return;
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save this article.')),
      );
      return;
    }
    final current = _isSaved ?? article.isBookmarkedByCurrentUser;
    final next = !current;
    setState(() {
      _isSaved = next;
      _saving = true;
    });
    try {
      await ref.read(feedRepositoryProvider).toggleBookmark(article.id, next);
      if (mounted && next) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved'),
            action: SnackBarAction(
              label: 'Add to List',
              onPressed: () => showAddToListSheet(context, article.id),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isSaved = current);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _trackReadingProgress(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final max = notification.metrics.maxScrollExtent;
    final next =
        max <= 0 ? 0.0 : (notification.metrics.pixels / max).clamp(0.0, 1.0);
    final progressDelta = next - _readingProgress;
    if (progressDelta.abs() > 0.01) {
      setState(() => _readingProgress = next);
    }
    if (notification is ScrollUpdateNotification) {
      final now = DateTime.now();
      if (now.difference(_lastMedhaScrollReaction) >
          const Duration(milliseconds: 650)) {
        _lastMedhaScrollReaction = now;
        ref.read(medhaBehaviorControllerProvider.notifier).onScroll(
              delta: progressDelta,
              velocity: (notification.scrollDelta?.abs() ?? 0) * 60,
            );
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.articleId ?? widget.initialArticle?.id;
    if (id == null || id.isEmpty) return _buildUnavailableState(context);
    final articleAsync = ref.watch(discoverArticleByIdProvider(id));

    return articleAsync.when(
      data: (found) {
        if (found == null) {
          return _buildUnavailableState(context);
        }
        return _buildArticleContent(context, found);
      },
      loading: () => Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        body: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
      ),
      error: (_, __) => _buildUnavailableState(context),
    );
  }

  Widget _buildArticleContent(BuildContext context, PostModel articlePost) {
    final selectedLanguage = ref.watch(contentLanguageProvider);
    final structuredData = StructuredArticleData.fromPostModel(articlePost,
        language: selectedLanguage);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isSelf = currentUserId != null &&
        structuredData.authorId != null &&
        currentUserId == structuredData.authorId;
    final isFollowing = structuredData.authorId != null && !isSelf
        ? ref.watch(isFollowingProvider(structuredData.authorId!))
        : false;

    final primaryText = AppTheme.primaryTextColor(context);
    final isSaved = _isSaved ?? articlePost.isBookmarkedByCurrentUser;
    final medhaContext = ref.watch(
      medhaArticleContextProvider(
        MedhaArticleContextInput(
          article: structuredData,
          scrollProgress: _readingProgress,
        ),
      ),
    );
    _scheduleMedhaContextPublication(medhaContext);

    final availableLanguages = ['en'];
    articlePost.publishedArticle.languages.forEach((k, v) {
      if (k != 'en' && v.translationStatus == 'ready') {
        availableLanguages.add(k);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        foregroundColor: primaryText,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: () => _toggleSaved(articlePost),
            tooltip: isSaved ? 'Remove bookmark' : 'Bookmark',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                key: ValueKey(isSaved),
                color: isSaved ? AppTheme.primaryOrange : primaryText,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _shareArticle(context, articlePost),
            tooltip: 'Share',
            icon: Icon(Icons.ios_share_rounded, color: primaryText),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz_rounded, color: primaryText),
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'share') {
                _shareArticle(context, articlePost);
              } else if (value == 'discuss') {
                CommentsBottomSheet.show(context, articlePost.id);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'discuss',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Discuss this article'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.send_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Share story'),
                  ],
                ),
              ),
            ],
          ),
        ],
        // Reading Progress Line
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _readingProgress,
              child: Container(height: 2, color: AppTheme.primaryOrange),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _trackReadingProgress,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (availableLanguages.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: LanguagePickerButton(
                                availableLanguageIds: availableLanguages,
                              ),
                            ),
                          ),
                        // 1. HERO SECTION
                        ArticleHeroSection(
                          article: structuredData,
                          isSelf: isSelf,
                          isFollowing: isFollowing,
                          onFollow: () {
                            if (currentUserId != null &&
                                structuredData.authorId != null) {
                              ref.read(userRepositoryProvider).toggleFollowUser(
                                    currentUserId: currentUserId,
                                    targetUserId: structuredData.authorId!,
                                    follow: !isFollowing,
                                  );
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // 2. KEY NUMBERS
                        KeyNumbersRow(numbers: structuredData.keyNumbers),
                        const SizedBox(height: 20),

                        // 3. WHY THIS MATTERS
                        if (structuredData.whyItMatters.isNotEmpty) ...[
                          WhyThisMattersSection(
                              text: structuredData.whyItMatters),
                          const SizedBox(height: 20),
                        ],

                        // 4. EXPLORE THE STORY
                        ExploreTheStorySection(
                            items: structuredData.exploreSections),
                        const SizedBox(height: 20),

                        // 5. QUOTE
                        if (structuredData.quoteText != null) ...[
                          EditorialQuoteWidget(
                            quote: structuredData.quoteText!,
                            speaker: structuredData.quoteSpeaker ?? '',
                            role: structuredData.quoteRole ?? '',
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 6. YOU NOW KNOW
                        if (structuredData.takeaways.isNotEmpty)
                          YouNowKnowWidget(takeaways: structuredData.takeaways),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),

              // 7. STICKY BOTTOM ACTION BAR
              ArticleBottomActionBar(
                isSaved: isSaved,
                isFollowing: isFollowing,
                onSave: () => _toggleSaved(articlePost),
                onDiscuss: () =>
                    CommentsBottomSheet.show(context, articlePost.id),
                onShare: () => _shareArticle(context, articlePost),
                onFollow: () {
                  if (currentUserId != null &&
                      structuredData.authorId != null) {
                    ref.read(userRepositoryProvider).toggleFollowUser(
                          currentUserId: currentUserId,
                          targetUserId: structuredData.authorId!,
                          follow: !isFollowing,
                        );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _shareArticle(BuildContext context, PostModel article) {
    BreakpointShareSheet.show(
      context,
      title: 'Share story',
      url: BreakpointLinks.article(article.id),
      shareText: 'Worth stopping for: ${article.title}',
      qrInstruction: 'Scan to open this story in Breakpoint',
    );
  }

  Widget _buildUnavailableState(BuildContext context) {
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        foregroundColor: primaryText,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.article_outlined,
                    size: 40, color: AppTheme.primaryOrange),
              ),
              const SizedBox(height: 20),
              Text(
                'Article unavailable',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This story may have been removed or is no longer available.',
                style: TextStyle(
                    fontSize: 14, color: secondaryText, fontFamily: 'Inter'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Back to Discover',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Outfit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
