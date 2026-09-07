class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // e.g. 'drop', 'space', 'chat', 'creator_content'
  final String? contentType;
  final String? contentId;
  final String? actorId;
  final String? actorName;
  final String? actorAvatar;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.contentType,
    this.contentId,
    this.actorId,
    this.actorName,
    this.actorAvatar,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final body = json['body'];
    if (id is! String || id.isEmpty || title is! String || body is! String) {
      throw const FormatException('Malformed notification');
    }
    final rawCreatedAt = json['createdAt'];
    final createdAt =
        rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null;
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: json['type'] as String? ?? 'system',
      contentType: json['contentType'] as String?,
      contentId: json['contentId'] as String?,
      actorId: json['actorId'] as String?,
      actorName: json['actorName'] as String?,
      actorAvatar: json['actorAvatar'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
