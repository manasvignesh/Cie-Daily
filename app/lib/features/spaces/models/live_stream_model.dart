import 'package:cloud_firestore/cloud_firestore.dart';

class LiveStreamModel {
  final String id;
  final String title;
  final String hostId;
  final String hostName;
  final String? hostAvatar;
  final String status;
  final DateTime createdAt;
  final String? roomName;
  final String? category;
  final String? description;
  final int? participantCount;

  LiveStreamModel({
    required this.id,
    required this.title,
    required this.hostId,
    required this.hostName,
    this.hostAvatar,
    required this.status,
    required this.createdAt,
    this.roomName,
    this.category,
    this.description,
    this.participantCount,
  });

  factory LiveStreamModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
    final dateField = data['createdAt'] ?? data['startedAt'];
    if (dateField != null) {
      try {
        if (dateField is String) {
          parsedDate = DateTime.parse(dateField);
        } else if (dateField is int) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(dateField);
        } else {
          parsedDate = (dateField as Timestamp).toDate();
        }
      } catch (e) {
        // Fallback to epoch
      }
    }

    final resolvedRoom = (data['roomName'] as String?)?.trim() ??
        (data['roomId'] as String?)?.trim() ??
        (data['room_id'] as String?)?.trim() ??
        (data['room'] as String?)?.trim();

    return LiveStreamModel(
      id: id,
      title: data['title'] as String? ?? 'Live Stream',
      hostId: data['hostId'] as String? ?? '',
      hostName: data['hostName'] as String? ?? 'Host',
      hostAvatar: data['hostAvatar'] as String?,
      status: data['status'] as String? ?? 'live',
      createdAt: parsedDate,
      roomName: (resolvedRoom != null && resolvedRoom.isNotEmpty)
          ? resolvedRoom
          : null,
      category: (data['category'] as String?)?.trim(),
      description: (data['description'] as String?)?.trim(),
      participantCount: (data['participantCount'] as num?)?.toInt() ??
          (data['participants'] is List
              ? (data['participants'] as List).length
              : null),
    );
  }
}
