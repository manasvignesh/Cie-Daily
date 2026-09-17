import 'package:cloud_firestore/cloud_firestore.dart';

class ArticleList {
  const ArticleList({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.articleIds,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String ownerName;
  final String title;
  final String description;
  final List<String> articleIds;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ArticleList.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    DateTime date(Object? value) =>
        value is Timestamp ? value.toDate() : DateTime.now();
    return ArticleList(
      id: doc.id,
      ownerUid: data['ownerUid']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? 'Breakpoint reader',
      title: data['title']?.toString() ?? 'Untitled List',
      description: data['description']?.toString() ?? '',
      articleIds: List<String>.from(data['articleIds'] ?? const []),
      isPublic: data['isPublic'] != false,
      createdAt: date(data['createdAt']),
      updatedAt: date(data['updatedAt']),
    );
  }
}
