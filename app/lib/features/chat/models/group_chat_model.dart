import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? photoUrl;
  final String createdById;
  final List<String> members;
  final Map<String, dynamic> memberDetails;
  final bool isPublic;
  final String lastMessage;
  final String lastMessageSenderName;
  final DateTime lastMessageTimestamp;
  final DateTime createdAt;

  const GroupChatModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.photoUrl,
    required this.createdById,
    required this.members,
    required this.memberDetails,
    required this.isPublic,
    required this.lastMessage,
    required this.lastMessageSenderName,
    required this.lastMessageTimestamp,
    required this.createdAt,
  });

  factory GroupChatModel.fromMap(Map<String, dynamic> map, String docId) {
    final lastTs = map['lastMessageTimestamp'];
    DateTime lastDt = DateTime.now();
    if (lastTs is Timestamp) {
      lastDt = lastTs.toDate();
    }

    final createdTs = map['createdAt'];
    DateTime createdDt = DateTime.now();
    if (createdTs is Timestamp) {
      createdDt = createdTs.toDate();
    }

    return GroupChatModel(
      id: docId,
      name: map['name'] ?? 'Unnamed Community',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      photoUrl: map['photoUrl'],
      createdById: map['createdById'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      memberDetails: Map<String, dynamic>.from(map['memberDetails'] ?? {}),
      isPublic: map['isPublic'] ?? true,
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderName: map['lastMessageSenderName'] ?? '',
      lastMessageTimestamp: lastDt,
      createdAt: createdDt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'photoUrl': photoUrl,
      'createdById': createdById,
      'members': members,
      'memberDetails': memberDetails,
      'isPublic': isPublic,
      'lastMessage': lastMessage,
      'lastMessageSenderName': lastMessageSenderName,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  GroupChatModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? photoUrl,
    String? createdById,
    List<String>? members,
    Map<String, dynamic>? memberDetails,
    bool? isPublic,
    String? lastMessage,
    String? lastMessageSenderName,
    DateTime? lastMessageTimestamp,
    DateTime? createdAt,
  }) {
    return GroupChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      photoUrl: photoUrl ?? this.photoUrl,
      createdById: createdById ?? this.createdById,
      members: members ?? this.members,
      memberDetails: memberDetails ?? this.memberDetails,
      isPublic: isPublic ?? this.isPublic,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderName:
          lastMessageSenderName ?? this.lastMessageSenderName,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GroupMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final DateTime timestamp;
  final bool isSystemMessage;

  const GroupMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    required this.timestamp,
    required this.isSystemMessage,
  });

  factory GroupMessageModel.fromMap(Map<String, dynamic> map, String docId) {
    final ts = map['timestamp'];
    DateTime dt = DateTime.now();
    if (ts is Timestamp) {
      dt = ts.toDate();
    }
    return GroupMessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Student',
      senderPhotoUrl: map['senderPhotoUrl'],
      content: map['content'] ?? '',
      timestamp: dt,
      isSystemMessage: map['isSystemMessage'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isSystemMessage': isSystemMessage,
    };
  }
}
