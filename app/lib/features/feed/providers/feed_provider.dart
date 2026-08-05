import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/feed_repository.dart';
import '../models/post_model.dart';

final feedProvider = StateNotifierProvider<FeedNotifier, AsyncValue<List<PostModel>>>((ref) {
  return FeedNotifier(ref.watch(feedRepositoryProvider));
});

class FeedNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final FeedRepository _repository;
  int _offset = 0;
  final int _limit = 10;
  bool _hasMore = true;

  FeedNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    state = const AsyncValue.loading();
    _offset = 0;
    _hasMore = true;
    try {
      final posts = await _repository.fetchPosts(offset: _offset, limit: _limit);
      _hasMore = posts.length == _limit;
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchNextPage() async {
    if (!_hasMore || state.isLoading || state.isRefreshing) return;

    final currentPosts = state.value ?? [];
    
    // Optimistic UI state while loading
    state = AsyncValue.data(currentPosts);
    _offset += _limit;

    try {
      final newPosts = await _repository.fetchPosts(offset: _offset, limit: _limit);
      _hasMore = newPosts.length == _limit;
      state = AsyncValue.data([...currentPosts, ...newPosts]);
    } catch (e, st) {
      // Revert offset on error
      _offset -= _limit;
      state = AsyncValue.error(e, st);
    }
  }
}
