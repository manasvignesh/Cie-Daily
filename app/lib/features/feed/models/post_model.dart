import '../../../core/utils/role_utils.dart';
import '../../discover/models/article_image_resolver.dart';
import '../../discover/models/published_article_model.dart';

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
  final DateTime? publishedAt;
  final String authorName;
  final String? authorAvatar;
  final String? authorEmail;
  final String? imageUrl;
  final String? videoUrl;
  final String? aspectRatio;
  final String? authorId;
  final List<String> likedBy;
  final List<String> bookmarkedBy;
  final bool isLikedByCurrentUser;
  final bool isBookmarkedByCurrentUser;
  final PublishedArticle publishedArticle;

  int get schemaVersion => publishedArticle.schemaVersion;
  QuickBriefContent? get quickBrief => publishedArticle.quickBrief;
  FullArticleContent? get fullArticle => publishedArticle.fullArticle;

  int get upvotes => likesCount;
  int get commentCount => commentsCount;
  bool get isAuthorVerified => isVerifiedUser(authorEmail);

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
    this.publishedAt,
    required this.authorName,
    this.authorAvatar,
    this.authorEmail,
    this.imageUrl,
    this.videoUrl,
    this.aspectRatio,
    this.authorId,
    this.likedBy = const [],
    this.bookmarkedBy = const [],
    this.isLikedByCurrentUser = false,
    this.isBookmarkedByCurrentUser = false,
    PublishedArticle? publishedArticle,
  }) : publishedArticle = publishedArticle ??
            PublishedArticle(
              id: id,
              schemaVersion: 1,
              quickBrief: null,
              fullArticle: null,
              metadata: const {},
            );

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final published = PublishedArticle.fromFirestore(
      json['id']?.toString() ?? '',
      json,
    );
    final metadata = published.metadata;
    final author = json['author'] is Map
        ? Map<String, dynamic>.from(json['author'] as Map)
        : const <String, dynamic>{};
    final email =
        author['email']?.toString() ?? json['authorEmail']?.toString();
    final rawTitle = json['title']?.toString() ?? '';
    final rawCategory = json['category']?.toString() ?? 'Discover';
    final createdAt = _dateValue(json['createdAt']);
    final publishedAt = _nullableDateValue(json['publishedAt']);
    final mediaUrls = json['mediaUrls'] is List
        ? (json['mediaUrls'] as List)
            .map((value) => value?.toString() ?? '')
            .where((value) => value.isNotEmpty)
            .toList()
        : const <String>[];
    final resolvedImage = resolveArticleImage(
      candidates: [
        ...mediaUrls,
        json['imageUrl'],
        json['image_url'],
        json['heroImage'],
        json['hero_image'],
        json['coverImage'],
        json['cover_image'],
        json['thumbnailUrl'],
        metadata['hero_image'],
        metadata['heroImage'],
        metadata['imageUrl'],
        metadata['source_image'],
        metadata['og_image'],
      ],
      title: published.quickBrief?.headline.isNotEmpty == true
          ? published.quickBrief!.headline
          : rawTitle,
      category: published.quickBrief?.category.isNotEmpty == true
          ? published.quickBrief!.category
          : rawCategory,
    );
    return PostModel(
      id: json['id']?.toString() ?? '',
      title: published.schemaVersion >= 2
          ? (published.quickBrief?.headline.isNotEmpty == true
              ? published.quickBrief!.headline
              : (published.fullArticle?.headline.isNotEmpty == true
                  ? published.fullArticle!.headline
                  : (rawTitle.isNotEmpty ? rawTitle : 'Untitled')))
          : rawTitle.isNotEmpty
              ? rawTitle
              : 'Untitled',
      blocks:
          json['blocks'] is List ? json['blocks'] as List<dynamic> : const [],
      estimatedReadTime: _intValue(json['estimatedReadTime'] ??
          json['estimated_read_time'] ??
          json['read_time'] ??
          metadata['read_time']),
      category: published.schemaVersion >= 2
          ? (published.quickBrief?.category.isNotEmpty == true
              ? published.quickBrief!.category
              : rawCategory)
          : rawCategory,
      likesCount: _intValue(json['likesCount']),
      commentsCount: _intValue(json['commentsCount']),
      isTodaysDrop:
          json['isTodaysDrop'] is bool ? json['isTodaysDrop'] as bool : false,
      createdAt: createdAt,
      publishedAt: publishedAt,
      authorName: (author['name']?.toString().trim().isNotEmpty == true)
          ? author['name'].toString()
          : ((author['fullName']?.toString().trim().isNotEmpty == true)
              ? author['fullName'].toString()
              : ((json['authorName']?.toString().trim().isNotEmpty == true &&
                      json['authorName'] != 'Anonymous')
                  ? json['authorName'].toString()
                  : 'Student')),
      authorAvatar: author['photoUrl']?.toString() ??
          author['avatarUrl']?.toString() ??
          json['authorAvatar']?.toString(),
      authorEmail: email,
      imageUrl: resolvedImage,
      videoUrl: json['videoUrl']?.toString(),
      aspectRatio: json['aspectRatio']?.toString(),
      authorId: json['authorId']?.toString(),
      likedBy: _strings(json['likedBy']),
      bookmarkedBy: _strings(json['bookmarkedBy']),
      isLikedByCurrentUser: json['isLikedByCurrentUser'] is bool
          ? json['isLikedByCurrentUser'] as bool
          : false,
      isBookmarkedByCurrentUser: json['isBookmarkedByCurrentUser'] is bool
          ? json['isBookmarkedByCurrentUser'] as bool
          : false,
      publishedArticle: published,
    );
  }

  factory PostModel.fromMap(Map<String, dynamic> data, String id) {
    data['id'] = id;

    for (final field in ['createdAt', 'publishedAt']) {
      if (data[field] != null && data[field] is! String) {
        final timestamp = data[field];
        if (timestamp is DateTime) {
          data[field] = timestamp.toIso8601String();
        } else {
          try {
            data[field] = timestamp.toDate().toIso8601String();
          } catch (_) {
            // Keep malformed historical timestamps from dropping the story.
          }
        }
      }
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
    DateTime? publishedAt,
    String? authorName,
    String? authorAvatar,
    String? imageUrl,
    String? videoUrl,
    String? aspectRatio,
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
      publishedAt: publishedAt ?? this.publishedAt,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      authorId: authorId ?? this.authorId,
      likedBy: likedBy ?? this.likedBy,
      bookmarkedBy: bookmarkedBy ?? this.bookmarkedBy,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isBookmarkedByCurrentUser:
          isBookmarkedByCurrentUser ?? this.isBookmarkedByCurrentUser,
      publishedArticle: publishedArticle,
    );
  }
}

extension PostChronology on PostModel {
  DateTime get chronologicalDate => publishedAt ?? createdAt;
}

int _intValue(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 1;
}

DateTime _dateValue(dynamic value) {
  return _nullableDateValue(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDateValue(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value != null) {
    try {
      final converted = value.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Keep malformed historical timestamps from dropping an entire story.
    }
  }
  return null;
}

List<String> _strings(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}
