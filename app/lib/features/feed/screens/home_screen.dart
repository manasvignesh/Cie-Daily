import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
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

    return Scaffold(
      body: feedState.when(
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

              if (index >= posts.length - 2) {
                // Fetch more when near the end
                ref.read(feedProvider.notifier).fetchNextPage();
              }
            },
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                onLike: () {
                  // Toggle like optimistically
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
          onRetry: () => ref.read(feedProvider.notifier).fetchInitial(),
        ),
      ),
    );
  }
}
