class ConversationModel {
  final String id;
  final String? name;
  final bool isGroup;
  final String? lastMessageText;
  final DateTime? lastMessageAt;

  ConversationModel({
    required this.id,
    this.name,
    this.isGroup = false,
    this.lastMessageText,
    this.lastMessageAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      isGroup: json['is_group'] as bool? ?? false,
      lastMessageText: json['last_message'] as String?,
      lastMessageAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
