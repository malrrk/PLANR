import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/core/story_views.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/models/story.dart';
import 'package:planner_app/models/story_audience.dart';
import 'package:planner_app/screens/chats_screen.dart';
import 'package:planner_app/widgets/home/home_greeting.dart';

Event _event({
  required String id,
  required DateTime date,
  bool chat = true,
  DateTime? lastMessageAt,
  DateTime? lastReadAt,
  String title = 'Plan',
}) {
  return Event.fromMap({
    'creatorUid': 'a',
    'eventKind': 'private',
    'visibility': 'private',
    'title': title,
    'chatEnabled': chat,
    'date': date,
    'createdAt': DateTime(2026, 1, 1),
    'lastMessageAt': ?lastMessageAt,
    'lastReadMessageAt': ?lastReadAt,
  }, id);
}

void main() {
  final now = DateTime(2026, 11, 13, 14);

  group('chats list', () {
    test('only plans with chat are listed, unread first, then upcoming, then past', () {
      final events = [
        _event(id: 'past', date: now.subtract(const Duration(days: 3))),
        _event(
          id: 'quiet',
          date: now.add(const Duration(days: 1)),
          lastMessageAt: now.subtract(const Duration(hours: 5)),
          lastReadAt: now.subtract(const Duration(hours: 4)),
        ),
        _event(
          id: 'unread',
          date: now.add(const Duration(days: 9)),
          lastMessageAt: now.subtract(const Duration(hours: 1)),
          lastReadAt: now.subtract(const Duration(hours: 2)),
        ),
        _event(id: 'nochat', date: now.add(const Duration(days: 2)), chat: false),
      ];

      final ids = ChatsScreen.chatsFrom(events, now).map((e) => e.id).toList();

      expect(ids, ['unread', 'quiet', 'past']);
    });
  });

  group('home greeting line', () {
    test('invitations come first', () {
      expect(
        HomeGreeting.subtitleFor(pendingInvites: 1, upcoming: const [], now: now),
        '1 invitation is waiting for your answer.',
      );
      expect(
        HomeGreeting.subtitleFor(pendingInvites: 3, upcoming: const [], now: now),
        '3 invitations are waiting for your answer.',
      );
    });

    test('an empty calendar invites the user to plan something', () {
      expect(
        HomeGreeting.subtitleFor(pendingInvites: 0, upcoming: const [], now: now),
        "Nothing planned yet. Let's change that.",
      );
    });

    test('a plan tonight is called out by name', () {
      final tonight = _event(
        id: 't',
        date: DateTime(2026, 11, 13, 20),
        title: 'Cinema',
      );

      expect(
        HomeGreeting.subtitleFor(pendingInvites: 0, upcoming: [tonight], now: now),
        'Tonight: Cinema',
      );
    });

    test('a single later plan shows a countdown', () {
      final later = _event(
        id: 'l',
        date: DateTime(2026, 11, 20, 19),
        title: 'Hike',
      );

      expect(
        HomeGreeting.subtitleFor(pendingInvites: 0, upcoming: [later], now: now),
        'Next up: Hike, in 7 days.',
      );
    });
  });

  group('story model', () {
    test('legacy stories without an audience are treated as public', () {
      final story = Story.fromMap({
        'id': 's',
        'ownerUid': 'a',
        'imageUrl': 'https://example.com/a.jpg',
      });

      expect(story.audience, 'public');
      expect(story.viewerUids, isEmpty);
      expect(story.eventId, isNull);
    });

    test('audience, viewers and the event link survive a round trip', () {
      final story = Story(
        id: 's',
        ownerType: 'user',
        ownerUid: 'a',
        ownerDisplayName: 'Alice',
        ownerPhotoUrl: null,
        pageId: null,
        imageUrl: 'https://example.com/a.jpg',
        caption: null,
        createdAt: DateTime(2026, 11, 13),
        expiresAt: DateTime(2026, 11, 20),
        dayKey: '2026-11-13',
        isPublicPreview: false,
        audience: 'close',
        viewerUids: const ['b', 'c'],
        eventId: 'e1',
        eventTitle: 'Party',
      );

      final copy = Story.fromMap(story.toMap());

      expect(copy.audience, 'close');
      expect(copy.viewerUids, ['b', 'c']);
      expect(copy.eventId, 'e1');
      expect(copy.eventTitle, 'Party');
      expect(StoryAudience.fromId(copy.audience), StoryAudience.close);
      expect(StoryAudience.fromId('nonsense'), StoryAudience.public);
    });
  });

  group('story views', () {
    setUp(StoryViews.resetForTest);

    test('remembers which stories were watched', () async {
      expect(StoryViews.instance.isViewed('s1'), isFalse);

      await StoryViews.instance.markViewed('s1');
      await StoryViews.instance.markViewed('s1');

      expect(StoryViews.instance.isViewed('s1'), isTrue);
      expect(StoryViews.instance.viewedIds.value, {'s1'});
    });
  });
}
