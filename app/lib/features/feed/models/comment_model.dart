class CommentModel {
  final String id;
  final String parentId;
  final String authorId;
  final String? replyToCommentId;
  final String content;
  final int likesCount;
  final DateTime createdAt;

  // Joined fields
  final String authorName;
  final String? authorAvatar;

  CommentModel({
    required this.id,
    required this.parentId,
    required this.authorId,
    this.replyToCommentId,
    required this.content,
    required this.likesCount,
    required this.createdAt,
    required this.authorName,
    this.authorAvatar,
  });

  factory CommentModel.fromMap(Map<String, dynamic> data, String id) {
    // Handle Timestamp conversion
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] != null) {
      try {
        if (data['createdAt'] is String) {
          parsedDate = DateTime.parse(data['createdAt']);
        } else if (data['createdAt'] is int) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
        } else {
          parsedDate = data['createdAt'].toDate();
        }
      } catch (e) {
        // Fallback to now if parsing fails
      }
    }

    return CommentModel(
      id: id,
      parentId: data['parentId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      replyToCommentId: data['replyToCommentId'] as String?,
      content: data['content'] as String? ?? '',
      likesCount: data['likesCount'] as int? ?? 0,
      createdAt: parsedDate,
      authorName: data['authorName'] as String? ?? 'Anonymous',
      authorAvatar: data['authorAvatar'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'authorId': authorId,
      'replyToCommentId': replyToCommentId,
      'content': content,
      'likesCount': likesCount,
      'createdAt': createdAt,
    };
  }
}
