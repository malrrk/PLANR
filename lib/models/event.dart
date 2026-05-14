import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String creatorUid;
  final String creatorDisplayName;
  final String? creatorPhotoUrl;

  final String title;
  final String description;
  final String address;
  final DateTime date;
  final String? imageUrl;

  final String visibility; // public / private
  final bool chatEnabled;
  final bool guestsCanInvite;

  final List<String> tags;

  final int attendeeCount;
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
    required this.createdAt,
    this.lastMessageAt,
    this.lastReadMessageAt,
    this.lastMessageText,
    this.lastMessageSenderUid,
    this.lastMessageSenderName,
  });

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
    return Event(
      id: documentId,
      creatorUid: map['creatorUid'] as String? ?? '',
      creatorDisplayName: map['creatorDisplayName'] as String? ?? 'User',
      creatorPhotoUrl: map['creatorPhotoUrl'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? map['location'] as String? ?? '',
      date: _dateFromTimestamp(map['date']) ?? DateTime.now(),
      imageUrl: map['imageUrl'] as String?,
      visibility: map['visibility'] as String? ?? 'public',
      chatEnabled: map['chatEnabled'] as bool? ?? true,
      guestsCanInvite: map['guestsCanInvite'] as bool? ?? true,
      tags: List<String>.from(map['tags'] as List? ?? const []),
      attendeeCount: (map['attendeeCount'] as num?)?.toInt() ?? 0,
      createdAt: _dateFromTimestamp(map['createdAt']) ?? DateTime.now(),
      lastMessageAt: _dateFromTimestamp(map['lastMessageAt']),
      lastReadMessageAt: _dateFromTimestamp(map['lastReadMessageAt']),
      lastMessageText: map['lastMessageText'] as String?,
      lastMessageSenderUid: map['lastMessageSenderUid'] as String?,
      lastMessageSenderName: map['lastMessageSenderName'] as String?,
    );
  }

  static DateTime? _dateFromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}