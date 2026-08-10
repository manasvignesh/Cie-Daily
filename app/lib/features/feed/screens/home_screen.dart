import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../providers/feed_provider.dart';
import '../data/firebase_feed_repository.dart';
import '../services/engagement_service.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../../../core/widgets/indicators/loading_skeleton.dart';
import '../../../core/widgets/indicators/error_state.dart';
import '../../../core/widgets/indicators/empty_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;

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
    final isMlritUser = user?.email?.endsWith('@mlrit.ac.in') ?? false;

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
                  // Report previous post
                  await ref.read(engagementServiceProvider).stopTrackingAndReport();
                  // Start tracking new post
                  ref.read(engagementServiceProvider).startTracking(posts[index].id);
                },
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return PostCard(
                    post: post,
                    onLike: (isLiked) {
                      ref.read(feedRepositoryProvider).toggleLike(post.id, isLiked);
                    },
                    onBookmark: (isBookmarked) {
                      ref.read(feedRepositoryProvider).toggleBookmark(post.id, isBookmarked);
                    },
                    onComment: () {
                      CommentsBottomSheet.show(context, post.id);
                    },
                    onShare: () {
                      // Share functionality
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: PostSkeleton()),
            error: (err, stack) => ErrorState(
              message: err.toString(),
              onRetry: () => ref.refresh(feedProvider),
            ),
          ),
          
          if (isMlritUser)
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
                        backgroundColor: Colors.grey[900],
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (ctx) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 8, bottom: 16),
                                child: Text(
                                  'Create Post',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.video_collection, color: Colors.white),
                                ),
                                title: const Text(
                                  'Video / Reel Post',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text(
                                  'With Aspect Ratio choices (9:16, 1:1, 4:5, 16:9)',
                                  style: TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  context.push('/create_video_post');
                                },
                              ),
                              const Divider(color: Colors.white12),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.article_rounded, color: Colors.white),
                                ),
                                title: const Text(
                                  'Article Post',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text(
                                  'Long-form articles and campus drops',
                                  style: TextStyle(color: Colors.white60, fontSize: 12),
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
