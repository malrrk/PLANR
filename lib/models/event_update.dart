import 'firestore_dates.dart';

class EventUpdate {
  const EventUpdate({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
    required this.isPinned,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;
  final bool isPinned;

  factory EventUpdate.fromMap(Map<String, dynamic> map, String documentId) {
    return EventUpdate(
      id: documentId,
      authorUid: map['authorUid'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Organizer',
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
      text: map['text'] as String? ?? '',
      createdAt: dateFromFirestore(map['createdAt']) ?? DateTime.now(),
      isPinned: map['isPinned'] as bool? ?? false,
    );
  }
}
