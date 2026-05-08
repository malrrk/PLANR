import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String ownerUid;
  final String ownerDisplayName;
  final String? ownerPhotoUrl;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String dayKey;

  Story({
    required this.id,
    required this.ownerUid,
    required this.ownerDisplayName,
    required this.ownerPhotoUrl,
    required this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    required this.dayKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'ownerDisplayName': ownerDisplayName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'dayKey': dayKey,
    };
  }

  factory Story.fromMap(Map<String, dynamic> map) {
    final createdAt = (map['createdAt'] as Timestamp).toDate();

    return Story(
      id: map['id'] as String,
      ownerUid: map['ownerUid'] as String,
      ownerDisplayName: map['ownerDisplayName'] as String? ?? 'User',
      ownerPhotoUrl: map['ownerPhotoUrl'] as String?,
      imageUrl: map['imageUrl'] as String,
      createdAt: createdAt,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : createdAt.add(const Duration(days: 7)),
      dayKey: map['dayKey'] as String? ?? dayKeyFromDate(createdAt),
    );
  }

  static String dayKeyFromDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}