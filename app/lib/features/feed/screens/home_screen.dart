import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../providers/feed_provider.dart';
import '../data/firebase_feed_repository.dart';
import '../services/engagement_service.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/in_app_share_bottom_sheet.dart';
import '../../../core/widgets/indicators/loading_skeleton.dart';
import '../../../core/widgets/indicators/error_state.dart';
import '../../../core/widgets/indicators/empty_state.dart';
import '../../../core/utils/role_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Start tracking first post after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final posts = ref.read(feedProvider).value;
      if (posts != null && posts.isNotEmpty) {
        ref.read(engagementServiceProvider).startTracking(posts[0].id);
      }
    });
  }

  @override
  void dispose() {
    ref.read(engagementServiceProvider).stopTrackingAndReport();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final user = FirebaseAuth.instance.currentUser;
    final canCreate = canCreateContent(user?.email);

    return Scaffold(
      body: Stack(
        children: [
          feedState.when(
            data: (posts) {
              if (posts.isEmpty) {
                return const EmptyState(
                  title: 'No Posts Yet',
                  message: 'Check back later for new drops!',
                  icon: Icons.inbox_outlined,
                );
              }
              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                itemCount: posts.length,
                onPageChanged: (index) async {
                  setState(() => _currentPageIndex = index);
                  // Report previous post
                  await ref
                      .read(engagementServiceProvider)
                      .stopTrackingAndReport();
                  // Start tracking new post
                  ref
                      .read(engagementServiceProvider)
                      .startTracking(posts[index].id);
                },
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return PostCard(
                    post: post,
                    isVisible: index == _currentPageIndex,
                    onLike: (isLiked) {
                      ref
                          .read(feedRepositoryProvider)
                          .toggleLike(post.id, isLiked);
                    },
                    onBookmark: (isBookmarked) {
                      ref
                          .read(feedRepositoryProvider)
                          .toggleBookmark(post.id, isBookmarked);
                    },
                    onComment: () {
                      CommentsBottomSheet.show(context, post.id);
                    },
                    onShare: () {
                      InAppShareBottomSheet.show(context, post);
                    },
                  );
                },
              );
            },
            loading: () => Container(
                color: Colors.black,
                child: const Center(child: PostSkeleton())),
            error: (err, stack) => Container(
              color: Colors.black,
              child: ErrorState(
                message:
                    "We couldn't load the feed. Check your connection and try again.",
                onRetry: () => ref.refresh(feedProvider),
              ),
            ),
          ),

          // Top gradient for status bar visibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (canCreate)
            Positioned(
              top: 0,
              right: 16,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        useSafeArea: true,
                        isScrollControlled: true,
                        builder: (ctx) => Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF13131C),
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                            border: Border(
                                top: BorderSide(
                                    color: Colors.white12, width: 1)),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Handle bar
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(2)),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 20),
                                child: Text(
                                  'Create Post',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ListTile(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                tileColor: const Color(0xFF1C1C28),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF5A1F),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.video_collection_rounded,
                                      color: Colors.white,
                                      size: 24),
                                ),
                                title: const Text(
                                  'Video / Reel Post',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                                subtitle: Text(
                                  'Supports 9:16 (Reels) and 4:5 formats',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      fontFamily: 'Inter',
                                      fontSize: 13),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  context.push('/create_video_post');
                                },
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                tileColor: const Color(0xFF1C1C28),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF405DE6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.article_rounded,
                                      color: Colors.white, size: 24),
                                ),
                                title: const Text(
                                  'Article Post',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                                subtitle: Text(
                                  'Long-form articles and campus drops',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      fontFamily: 'Inter',
                                      fontSize: 13),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  context.push('/create_article_post');
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    backgroundColor: const Color(0xFFFF5A1F),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1),
                    ),
                    child: const Icon(Icons.add_rounded, size: 28),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
