import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;

  /// "user" or "publicPage"
  final String ownerType;

  /// For user stories: the user who owns the story.
  /// For page stories: the admin/user who posted it.
  final String ownerUid;

  /// For user stories: user display name.
  /// For page stories: page name.
  final String ownerDisplayName;

  /// For user stories: user photo.
  /// For page stories: page logo.
  final String? ownerPhotoUrl;

  /// Only used for public page stories.
  final String? pageId;

  final String imageUrl;
  final String? caption;

  final DateTime createdAt;
  final DateTime expiresAt;
  final String dayKey;

  /// If true, this page story can appear as a public preview on the page.
  final bool isPublicPreview;

  Story({
    required this.id,
    required this.ownerType,
    required this.ownerUid,
    required this.ownerDisplayName,
    required this.ownerPhotoUrl,
    required this.pageId,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.dayKey,
    required this.isPublicPreview,
  });

  bool get isUserStory => ownerType == 'user';

  bool get isPageStory => ownerType == 'publicPage';

  String get storyOwnerKey {
    if (isPageStory && pageId != null && pageId!.trim().isNotEmpty) {
      return 'page_$pageId';
    }

    return 'user_$ownerUid';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerType': ownerType,
      'ownerUid': ownerUid,
      'ownerDisplayName': ownerDisplayName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'pageId': pageId,
      'imageUrl': imageUrl,
      'caption': caption,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'dayKey': dayKey,
      'isPublicPreview': isPublicPreview,
    };
  }

  factory Story.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.now();

    final expiresAtRaw = map['expiresAt'];
    final expiresAt = expiresAtRaw is Timestamp
        ? expiresAtRaw.toDate()
        : createdAt.add(const Duration(days: 7));

    final ownerType = (map['ownerType'] as String?)?.trim().isNotEmpty == true
        ? (map['ownerType'] as String).trim()
        : 'user';

    return Story(
      id: map['id'] as String? ?? '',
      ownerType: ownerType,
      ownerUid: map['ownerUid'] as String,
      ownerDisplayName: map['ownerDisplayName'] as String? ??
          (ownerType == 'publicPage' ? 'Page' : 'User'),
      ownerPhotoUrl: map['ownerPhotoUrl'] as String?,
      pageId: map['pageId'] as String?,
      imageUrl: map['imageUrl'] as String,
      caption: map['caption'] as String?,
      createdAt: createdAt,
      expiresAt: expiresAt,
      dayKey: map['dayKey'] as String? ?? dayKeyFromDate(createdAt),
      isPublicPreview: map['isPublicPreview'] as bool? ?? false,
    );
  }

  static String dayKeyFromDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}