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
  });

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
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'] as String?,
      visibility: map['visibility'] as String? ?? 'public',
      chatEnabled: map['chatEnabled'] as bool? ?? true,
      guestsCanInvite: map['guestsCanInvite'] as bool? ?? true,
      tags: List<String>.from(map['tags'] as List? ?? const []),
      attendeeCount: (map['attendeeCount'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}