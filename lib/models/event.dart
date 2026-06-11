import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;

  /// Actual Firebase user who created the event document.
  final String creatorUid;
  final String creatorDisplayName;
  final String? creatorPhotoUrl;

  /// private / public / linkedGroup
  final String eventKind;

  /// profile / publicPage
  final String organizerType;
  final String organizerId;
  final String organizerDisplayName;
  final String? organizerPhotoUrl;
  final bool organizerVerified;

  final String title;
  final String description;
  final String address;
  final DateTime date;
  final String? imageUrl;

  /// public / private / friends / unlisted
  /// For now your app mainly uses public/private.
  final String visibility;
  final bool chatEnabled;
  final bool guestsCanInvite;

  final List<String> tags;

  /// For private events and linked groups this means attendees.
  /// For public events this means users who marked themselves as going.
  final int attendeeCount;

  final int interestedCount;

  /// Used when eventKind == linkedGroup.
  final String? linkedPublicEventId;
  final String? linkedPublicEventTitle;
  final String? linkedPublicEventImageUrl;
  final DateTime? linkedPublicEventDate;
  final String? linkedPublicEventAddress;

  final DateTime createdAt;

  final DateTime? lastMessageAt;
  final DateTime? lastReadMessageAt;
  final String? lastMessageText;
  final String? lastMessageSenderUid;
  final String? lastMessageSenderName;

  Event({
    required this.id,
    required this.creatorUid,
    required this.creatorDisplayName,
    required this.creatorPhotoUrl,
    required this.eventKind,
    required this.organizerType,
    required this.organizerId,
    required this.organizerDisplayName,
    required this.organizerPhotoUrl,
    required this.organizerVerified,
    required this.title,
    required this.description,
    required this.address,
    required this.date,
    required this.imageUrl,
    required this.visibility,
    required this.chatEnabled,
    required this.guestsCanInvite,
    required this.tags,
    required this.attendeeCount,
    required this.interestedCount,
    required this.linkedPublicEventId,
    required this.linkedPublicEventTitle,
    required this.linkedPublicEventImageUrl,
    required this.linkedPublicEventDate,
    required this.linkedPublicEventAddress,
    required this.createdAt,
    this.lastMessageAt,
    this.lastReadMessageAt,
    this.lastMessageText,
    this.lastMessageSenderUid,
    this.lastMessageSenderName,
  });

  bool get isPrivateEvent => eventKind == 'private';
  bool get isPublicEvent => eventKind == 'public';
  bool get isLinkedGroup => eventKind == 'linkedGroup';

  bool get isOrganizedByPage => organizerType == 'publicPage';
  bool get isOrganizedByProfile => organizerType == 'profile';

  String get publicOrganizerName {
    final trimmed = organizerDisplayName.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return creatorDisplayName;
  }

  String? get publicOrganizerPhotoUrl {
    final trimmed = organizerPhotoUrl?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return creatorPhotoUrl;
  }

  bool get hasUnreadMessages {
    if (!chatEnabled) return false;
    if (lastMessageAt == null) return false;
    if (lastReadMessageAt == null) return true;

    return lastMessageAt!.isAfter(lastReadMessageAt!);
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorUid': creatorUid,
      'creatorDisplayName': creatorDisplayName,
      'creatorPhotoUrl': creatorPhotoUrl,
      'eventKind': eventKind,
      'organizerType': organizerType,
      'organizerId': organizerId,
      'organizerDisplayName': organizerDisplayName,
      'organizerPhotoUrl': organizerPhotoUrl,
      'organizerVerified': organizerVerified,
      'title': title,
      'description': description,
      'address': address,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl,
      'visibility': visibility,
      'chatEnabled': chatEnabled,
      'guestsCanInvite': guestsCanInvite,
      'tags': tags,
      'attendeeCount': attendeeCount,
      'interestedCount': interestedCount,
      'linkedPublicEventId': linkedPublicEventId,
      'linkedPublicEventTitle': linkedPublicEventTitle,
      'linkedPublicEventImageUrl': linkedPublicEventImageUrl,
      'linkedPublicEventDate': linkedPublicEventDate == null
          ? null
          : Timestamp.fromDate(linkedPublicEventDate!),
      'linkedPublicEventAddress': linkedPublicEventAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastMessageAt != null)
        'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
      if (lastReadMessageAt != null)
        'lastReadMessageAt': Timestamp.fromDate(lastReadMessageAt!),
      if (lastMessageText != null) 'lastMessageText': lastMessageText,
      if (lastMessageSenderUid != null)
        'lastMessageSenderUid': lastMessageSenderUid,
      if (lastMessageSenderName != null)
        'lastMessageSenderName': lastMessageSenderName,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map, String documentId) {
    final creatorUid = map['creatorUid'] as String? ?? '';
    final creatorDisplayName =
        map['creatorDisplayName'] as String? ?? 'User';
    final creatorPhotoUrl = map['creatorPhotoUrl'] as String?;

    final visibility = map['visibility'] as String? ?? 'public';

    final eventKind = map['eventKind'] as String? ??
        _fallbackEventKindFromVisibility(visibility);

    final rawOrganizerType =
        map['organizerType'] as String? ?? map['hostType'] as String?;

    final organizerType = switch (rawOrganizerType) {
      'page' => 'publicPage',
      'publicPage' => 'publicPage',
      'profile' => 'profile',
      _ => 'profile',
    };

    final organizerId =
        map['organizerId'] as String? ?? map['hostId'] as String? ?? creatorUid;

    final organizerDisplayName =
        map['organizerDisplayName'] as String? ??
            map['hostName'] as String? ??
            creatorDisplayName;

    final organizerPhotoUrl =
        map['organizerPhotoUrl'] as String? ??
            map['hostPhotoUrl'] as String? ??
            creatorPhotoUrl;

    return Event(
      id: documentId,
      creatorUid: creatorUid,
      creatorDisplayName: creatorDisplayName,
      creatorPhotoUrl: creatorPhotoUrl,
      eventKind: eventKind,
      organizerType: organizerType,
      organizerId: organizerId,
      organizerDisplayName: organizerDisplayName,
      organizerPhotoUrl: organizerPhotoUrl,
      organizerVerified: map['organizerVerified'] as bool? ??
          map['hostVerified'] as bool? ??
          false,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? map['location'] as String? ?? '',
      date: _dateFromTimestamp(map['date']) ?? DateTime.now(),
      imageUrl: map['imageUrl'] as String?,
      visibility: visibility,
      chatEnabled: map['chatEnabled'] as bool? ?? eventKind != 'public',
      guestsCanInvite: map['guestsCanInvite'] as bool? ?? true,
      tags: List<String>.from(map['tags'] as List? ?? const []),
      attendeeCount: (map['attendeeCount'] as num?)?.toInt() ?? 0,
      interestedCount: (map['interestedCount'] as num?)?.toInt() ?? 0,
      linkedPublicEventId: map['linkedPublicEventId'] as String?,
      linkedPublicEventTitle: map['linkedPublicEventTitle'] as String?,
      linkedPublicEventImageUrl: map['linkedPublicEventImageUrl'] as String?,
      linkedPublicEventDate: _dateFromTimestamp(map['linkedPublicEventDate']),
      linkedPublicEventAddress: map['linkedPublicEventAddress'] as String?,
      createdAt: _dateFromTimestamp(map['createdAt']) ?? DateTime.now(),
      lastMessageAt: _dateFromTimestamp(map['lastMessageAt']),
      lastReadMessageAt: _dateFromTimestamp(map['lastReadMessageAt']),
      lastMessageText: map['lastMessageText'] as String?,
      lastMessageSenderUid: map['lastMessageSenderUid'] as String?,
      lastMessageSenderName: map['lastMessageSenderName'] as String?,
    );
  }

  static String _fallbackEventKindFromVisibility(String visibility) {
    if (visibility == 'public') return 'public';
    return 'private';
  }

  static DateTime? _dateFromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}