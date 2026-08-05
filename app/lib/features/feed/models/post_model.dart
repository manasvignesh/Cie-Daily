class PostModel {
  final String id;
  final String title;
  final List<dynamic> blocks;
  final int estimatedReadTime;
  final String category;
  final int likesCount;
  final int commentsCount;
  final bool isTodaysDrop;
  final DateTime createdAt;
  final String authorName;
  final String? authorAvatar;

  PostModel({
    required this.id,
    required this.title,
    required this.blocks,
    required this.estimatedReadTime,
    required this.category,
    required this.likesCount,
    required this.commentsCount,
    required this.isTodaysDrop,
    required this.createdAt,
    required this.authorName,
    this.authorAvatar,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      title: json['title'] as String,
      blocks: json['blocks'] as List<dynamic>? ?? [],
      estimatedReadTime: json['estimated_read_time'] as int? ?? 1,
      category: json['category'] as String? ?? 'Discover',
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isTodaysDrop: json['is_todays_drop'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: json['author']?['full_name'] as String? ?? 'Anonymous',
      authorAvatar: json['author']?['avatar_url'] as String?,
    );
  }
}
