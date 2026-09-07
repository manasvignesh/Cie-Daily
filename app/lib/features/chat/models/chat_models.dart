import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String? senderPhotoUrl;
  final String senderDepartment;
  final String senderYear;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;

  const ConnectionRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.senderDepartment,
    required this.senderYear,
    required this.status,
    required this.createdAt,
  });

  factory ConnectionRequestModel.fromMap(
      Map<String, dynamic> map, String docId) {
    final ts = map['createdAt'];
    DateTime dt = DateTime.now();
    if (ts is Timestamp) {
      dt = ts.toDate();
    }
    return ConnectionRequestModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      senderName: map['senderName'] ?? 'Student',
      senderPhotoUrl: map['senderPhotoUrl'],
      senderDepartment: map['senderDepartment'] ?? 'CS',
      senderYear: map['senderYear']?.toString() ?? '1',
      status: map['status'] ?? 'pending',
      createdAt: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'senderDepartment': senderDepartment,
      'senderYear': senderYear,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, dynamic> participantDetails;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTimestamp;
  final Map<String, dynamic> unreadCounts;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.participantDetails,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTimestamp,
    required this.unreadCounts,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, String docId) {
    final ts = map['lastMessageTimestamp'] ?? map['updatedAt'] ?? map['createdAt'];
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(0);
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is DateTime) {
      dt = ts;
    } else if (ts is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
    }
    final rawParticipants = map['participants'];
    if (rawParticipants is! Iterable) {
      throw const FormatException('Conversation participants are missing');
    }
    final participants = rawParticipants.whereType<String>().where((id) => id.isNotEmpty).toList();
    if (participants.isEmpty) {
      throw const FormatException('Conversation has no valid participants');
    }
    final rawDetails = map['participantDetails'];
    final rawUnread = map['unreadCounts'];
    return ConversationModel(
      id: docId,
      participants: participants,
      participantDetails: rawDetails is Map
          ? rawDetails.map((key, value) => MapEntry(key.toString(), value))
          : const {},
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageSenderId: map['lastMessageSenderId']?.toString() ?? '',
      lastMessageTimestamp: dt,
      unreadCounts: rawUnread is Map
          ? rawUnread.map((key, value) => MapEntry(key.toString(), value))
          : const {},
    );
  }
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String docId) {
    final ts = map['timestamp'];
    DateTime dt = DateTime.now();
    if (ts is Timestamp) {
      dt = ts.toDate();
    }
    return ChatMessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: dt,
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
