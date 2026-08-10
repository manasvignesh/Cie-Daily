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

  LiveStreamModel({
    required this.id,
    required this.title,
    required this.hostId,
    required this.hostName,
    this.hostAvatar,
    required this.status,
    required this.createdAt,
    this.roomName,
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

    return LiveStreamModel(
      id: id,
      title: data['title'] as String? ?? 'Live Stream',
      hostId: data['hostId'] as String? ?? '',
      hostName: data['hostName'] as String? ?? 'Host',
      hostAvatar: data['hostAvatar'] as String?,
      status: data['status'] as String? ?? 'live',
      createdAt: parsedDate,
      roomName: data['roomName'] as String?,
    );
  }
}
