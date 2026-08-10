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
  final String? imageUrl;
  final String? videoUrl;
  final String? authorId;
  final List<String> likedBy;
  final List<String> bookmarkedBy;
  final bool isLikedByCurrentUser;
  final bool isBookmarkedByCurrentUser;

  int get upvotes => likesCount;
  int get commentCount => commentsCount;

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
    this.imageUrl,
    this.videoUrl,
    this.authorId,
    this.likedBy = const [],
    this.bookmarkedBy = const [],
    this.isLikedByCurrentUser = false,
    this.isBookmarkedByCurrentUser = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      blocks: json['blocks'] as List<dynamic>? ?? [],
      estimatedReadTime: json['estimatedReadTime'] as int? ?? 1,
      category: json['category'] as String? ?? 'Discover',
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      isTodaysDrop: json['isTodaysDrop'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is String ? DateTime.parse(json['createdAt']) : DateTime.now()) 
          : DateTime.now(),
      authorName: json['author']?['fullName'] as String? ?? 'Anonymous',
      authorAvatar: json['author']?['avatarUrl'] as String?,
      imageUrl: (json['mediaUrls'] as List<dynamic>?)?.isNotEmpty == true ? json['mediaUrls'][0] : json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      authorId: json['authorId'] as String?,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      bookmarkedBy: List<String>.from(json['bookmarkedBy'] ?? []),
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
      isBookmarkedByCurrentUser: json['isBookmarkedByCurrentUser'] as bool? ?? false,
    );
  }

  factory PostModel.fromMap(Map<String, dynamic> data, String id) {
    data['id'] = id;
    
    // Convert Firestore Timestamp if present
    if (data['createdAt'] != null && data['createdAt'] is! String) {
      data['createdAt'] = data['createdAt'].toDate().toIso8601String();
    }
    
    return PostModel.fromJson(data);
  }

  PostModel copyWith({
    String? id,
    String? title,
    List<dynamic>? blocks,
    int? estimatedReadTime,
    String? category,
    int? likesCount,
    int? commentsCount,
    bool? isTodaysDrop,
    DateTime? createdAt,
    String? authorName,
    String? authorAvatar,
    String? imageUrl,
    String? videoUrl,
    String? authorId,
    List<String>? likedBy,
    List<String>? bookmarkedBy,
    bool? isLikedByCurrentUser,
    bool? isBookmarkedByCurrentUser,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      blocks: blocks ?? this.blocks,
      estimatedReadTime: estimatedReadTime ?? this.estimatedReadTime,
      category: category ?? this.category,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isTodaysDrop: isTodaysDrop ?? this.isTodaysDrop,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      authorId: authorId ?? this.authorId,
      likedBy: likedBy ?? this.likedBy,
      bookmarkedBy: bookmarkedBy ?? this.bookmarkedBy,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isBookmarkedByCurrentUser: isBookmarkedByCurrentUser ?? this.isBookmarkedByCurrentUser,
    );
  }
}
