import '../models/post_model.dart';

abstract interface class FeedRepository {
  Future<List<PostModel>> fetchPosts({int offset = 0, int limit = 10});
  Future<void> toggleLike(String postId, bool isLiked);
  Future<void> toggleBookmark(String postId, bool isBookmarked);
  Future<List<PostModel>> fetchBookmarkedPosts();
  Future<void> createPost(PostModel post);
}
