import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/event.dart';

void main() {
  group('Event.fromMap', () {
    test('reads current organizer fields', () {
      final date = DateTime.utc(2030, 5, 1, 18);
      final event = Event.fromMap({
        'creatorUid': 'u1',
        'creatorDisplayName': 'Alex',
        'eventKind': 'public',
        'organizerType': 'publicPage',
        'organizerId': 'page1',
        'organizerDisplayName': 'Club',
        'organizerVerified': true,
        'title': 'Party',
        'description': 'Fun',
        'address': 'Street 1',
        'date': Timestamp.fromDate(date),
        'visibility': 'public',
        'tags': ['techno'],
        'attendeeCount': 4,
      }, 'e1');

      expect(event.id, 'e1');
      expect(event.isPublicEvent, isTrue);
      expect(event.isOrganizedByPage, isTrue);
      expect(event.organizerId, 'page1');
      expect(event.organizerVerified, isTrue);
      expect(event.date.toUtc(), date);
      expect(event.attendeeCount, 4);
      expect(event.tags, ['techno']);
    });

    test('falls back to legacy host and location fields', () {
      final event = Event.fromMap({
        'creatorUid': 'u1',
        'creatorDisplayName': 'Alex',
        'hostType': 'page',
        'hostId': 'page9',
        'hostName': 'Legacy Host',
        'hostVerified': true,
        'location': 'Old Town',
        'visibility': 'private',
        'date': Timestamp.fromDate(DateTime.utc(2030)),
      }, 'e2');

      expect(event.organizerType, 'publicPage');
      expect(event.organizerId, 'page9');
      expect(event.organizerDisplayName, 'Legacy Host');
      expect(event.organizerVerified, isTrue);
      expect(event.address, 'Old Town');
      expect(event.eventKind, 'private');
    });

    test('defaults to profile organizer and creator identity', () {
      final event = Event.fromMap({
        'creatorUid': 'u1',
        'creatorDisplayName': 'Alex',
        'date': Timestamp.fromDate(DateTime.utc(2030)),
      }, 'e3');

      expect(event.organizerType, 'profile');
      expect(event.organizerId, 'u1');
      expect(event.organizerDisplayName, 'Alex');
      expect(event.eventKind, 'public');
      expect(event.chatEnabled, isFalse);
      expect(event.guestsCanInvite, isTrue);
    });

    test('chat is off by default for public events only', () {
      final publicEvent = Event.fromMap({
        'eventKind': 'public',
        'date': Timestamp.fromDate(DateTime.utc(2030)),
      }, 'p');
      final linked = Event.fromMap({
        'eventKind': 'linkedGroup',
        'date': Timestamp.fromDate(DateTime.utc(2030)),
      }, 'l');

      expect(publicEvent.chatEnabled, isFalse);
      expect(linked.chatEnabled, isTrue);
    });
  });

  group('Event.hasUnreadMessages', () {
    Event build({
      bool chatEnabled = true,
      DateTime? lastMessageAt,
      DateTime? lastReadMessageAt,
    }) {
      return Event.fromMap({
        'eventKind': 'private',
        'chatEnabled': chatEnabled,
        'date': Timestamp.fromDate(DateTime.utc(2030)),
        if (lastMessageAt != null)
          'lastMessageAt': Timestamp.fromDate(lastMessageAt),
        if (lastReadMessageAt != null)
          'lastReadMessageAt': Timestamp.fromDate(lastReadMessageAt),
      }, 'x');
    }

    test('false when chat is disabled or no messages exist', () {
      expect(build(chatEnabled: false).hasUnreadMessages, isFalse);
      expect(build().hasUnreadMessages, isFalse);
    });

    test('true when never read, or read before last message', () {
      final sent = DateTime.utc(2030, 1, 2);
      expect(build(lastMessageAt: sent).hasUnreadMessages, isTrue);
      expect(
        build(
          lastMessageAt: sent,
          lastReadMessageAt: DateTime.utc(2030, 1, 1),
        ).hasUnreadMessages,
        isTrue,
      );
    });

    test('false when read after last message', () {
      expect(
        build(
          lastMessageAt: DateTime.utc(2030, 1, 1),
          lastReadMessageAt: DateTime.utc(2030, 1, 2),
        ).hasUnreadMessages,
        isFalse,
      );
    });
  });

  test('toMap and fromMap round trip preserves core fields', () {
    final original = Event.fromMap({
      'creatorUid': 'u1',
      'creatorDisplayName': 'Alex',
      'eventKind': 'linkedGroup',
      'linkedPublicEventId': 'pub1',
      'title': 'Group',
      'description': 'd',
      'address': 'a',
      'visibility': 'private',
      'tags': ['food'],
      'date': Timestamp.fromDate(DateTime.utc(2030, 3, 3)),
    }, 'e1');

    final copy = Event.fromMap(original.toMap(), 'e1');

    expect(copy.title, original.title);
    expect(copy.eventKind, original.eventKind);
    expect(copy.linkedPublicEventId, 'pub1');
    expect(copy.tags, original.tags);
    expect(copy.date, original.date);
  });
}
