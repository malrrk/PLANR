import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_dates.dart';

class PublicPage {
  const PublicPage({
    required this.id,
    required this.name,
    required this.handle,
    required this.description,
    required this.photoUrl,
    required this.backgroundImageUrl,
    required this.category,
    required this.tags,
    required this.followerCount,
    required this.eventCount,
    required this.isVerified,
    required this.isActive,
    required this.ownerUid,
    required this.adminUids,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String handle;
  final String description;
  final String? photoUrl;
  final String? backgroundImageUrl;
  final String category;
  final List<String> tags;

  final int followerCount;
  final int eventCount;

  final bool isVerified;
  final bool isActive;

  /// Admin-only for launch.
  /// Normal users do not create pages.
  final String? ownerUid;
  final List<String> adminUids;

  final DateTime createdAt;
  final DateTime? updatedAt;

  String get displayHandle {
    if (handle.trim().isEmpty) return '';
    return '@${handle.trim()}';
  }

  bool canBeManagedBy(String uid) {
    return ownerUid == uid || adminUids.contains(uid);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      'description': description,
      'photoUrl': photoUrl,
      'backgroundImageUrl': backgroundImageUrl,
      'category': category,
      'tags': tags,
      'followerCount': followerCount,
      'eventCount': eventCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'ownerUid': ownerUid,
      'adminUids': adminUids,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory PublicPage.fromMap(Map<String, dynamic> map, String documentId) {
    final createdAt = dateFromFirestore(map['createdAt']) ?? DateTime.now();

    return PublicPage(
      id: map['id'] as String? ?? documentId,
      name: map['name'] as String? ?? 'Untitled Page',
      handle: map['handle'] as String? ?? '',
      description: map['description'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      backgroundImageUrl: map['backgroundImageUrl'] as String?,
      category: map['category'] as String? ?? 'page',
      tags: List<String>.from(map['tags'] as List? ?? const []),
      followerCount: (map['followerCount'] as num?)?.toInt() ?? 0,
      eventCount: (map['eventCount'] as num?)?.toInt() ?? 0,
      isVerified: map['isVerified'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      ownerUid: map['ownerUid'] as String?,
      adminUids: List<String>.from(map['adminUids'] as List? ?? const []),
      createdAt: createdAt,
      updatedAt: dateFromFirestore(map['updatedAt']),
    );
  }
}