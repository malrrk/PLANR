import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/core/story_views.dart';
import 'package:planner_app/l10n/gen/app_localizations.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/models/story.dart';
import 'package:planner_app/models/story_audience.dart';
import 'package:planner_app/providers/event_provider.dart';
import 'package:planner_app/providers/friends_provider.dart';
import 'package:planner_app/providers/home_feed_provider.dart';
import 'package:planner_app/providers/public_page_provider.dart';
import 'package:planner_app/providers/saved_events_provider.dart';
import 'package:planner_app/providers/story_provider.dart';
import 'package:planner_app/providers/user_profile_provider.dart';
import 'package:planner_app/screens/chats_screen.dart';
import 'package:planner_app/screens/create_event_screen.dart';
import 'package:planner_app/widgets/home/home_greeting.dart';
import 'package:planner_app/widgets/home/home_discover_fallback.dart';
import 'package:planner_app/widgets/home/home_header.dart';
import 'package:planner_app/widgets/home/home_next_up_section.dart';
import 'package:planner_app/widgets/home/home_stories_row.dart';
import 'package:planner_app/widgets/home/my_event_mini_card.dart';

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

class _StoryService extends Fake implements StoryService {
  @override
  List<StoryGroup> groupStoriesByOwnerAndDay(List<Story> stories) => [];
}

class _SavedEventsService extends Fake implements SavedEventsService {}

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

  testWidgets('home header keeps the brand and notifications', (tester) async {
    var notificationsOpened = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingEventInvitesProvider.overrideWith(
            (ref) => const AsyncData([]),
          ),
          incomingFriendRequestsProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: HomeHeader(
              onNotificationTap: () => notificationsOpened = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SOCIAL PLANS. REAL CONNECTIONS.'), findsOneWidget);
    expect(find.byTooltip('Calendar'), findsNothing);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.notifications_none_rounded)).size,
      19,
    );
    final bell = tester.widget<HomeRoundButton>(
      find.ancestor(
        of: find.byTooltip('Notifications'),
        matching: find.byType(HomeRoundButton),
      ),
    );
    expect(bell.circleSize, 36);
    expect(tester.getSize(find.byTooltip('Notifications')), const Size(42, 42));
    await tester.tap(find.byTooltip('Notifications'));
    expect(notificationsOpened, isTrue);
  });

  testWidgets('stories show the add button beside the heading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(_Auth()),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
          friendsStoriesProvider.overrideWith((ref) => Stream.value([])),
          storyServiceProvider.overrideWithValue(_StoryService()),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeStoriesRow())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Friends & Stories'), findsOneWidget);
    expect(find.byTooltip('Add story'), findsOneWidget);
    expect(find.text('Add story'), findsNothing);
    expect(
      find.text('No stories yet. Be the first to share a moment.'),
      findsOneWidget,
    );
    expect(
      tester.getCenter(find.byTooltip('Add story')).dy,
      closeTo(
        (tester.getTopLeft(find.text('Friends & Stories')).dy +
                tester
                    .getBottomLeft(find.text('Little moments from your people'))
                    .dy) /
            2,
        1,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('my plans shows three upcoming rows and a calendar link', (
    tester,
  ) async {
    final future = DateTime.now().add(const Duration(days: 1));
    final events = List.generate(
      4,
      (index) => _event(
        id: '$index',
        date: future.add(Duration(days: index)),
        title: 'Plan $index',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myEventsProvider.overrideWith((ref) => Stream.value(events)),
          eventByIdProvider.overrideWith((ref, eventId) => Stream.value(null)),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: const Scaffold(
            body: SingleChildScrollView(child: HomeNextUpSection()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('My plans'), findsOneWidget);
    expect(find.text('4 upcoming plans'), findsOneWidget);
    expect(find.text('Plan 0'), findsOneWidget);
    expect(find.text('Plan 2'), findsOneWidget);
    expect(find.text('Plan 3'), findsNothing);
    expect(find.text('Create an event'), findsNothing);
    final cards = tester
        .widgetList<MyEventMiniCard>(find.byType(MyEventMiniCard))
        .toList();
    expect(cards.map((card) => card.featured), [true, false, false]);
    expect(find.text('View 1 more in your calendar'), findsOneWidget);
    expect(find.byTooltip('Calendar'), findsOneWidget);
    expect(
      tester.getCenter(find.text('My plans')).dy,
      closeTo(tester.getCenter(find.byTooltip('Calendar')).dy, 15),
    );
    await tester.tap(find.byTooltip('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Your calendar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final count in [0, 1, 2, 3]) {
    testWidgets('create event banner reflects $count upcoming plans', (
      tester,
    ) async {
      final future = DateTime.now().add(const Duration(days: 1));
      final events = List.generate(
        count,
        (index) => _event(
          id: '$index',
          date: future.add(Duration(days: index)),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsProvider.overrideWith((ref) => Stream.value(events)),
            eventByIdProvider.overrideWith(
              (ref, eventId) => Stream.value(null),
            ),
            myManagedPublicPagesProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(splashFactory: InkRipple.splashFactory),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: HomeNextUpSection()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Create an event'),
        count < 3 ? findsOneWidget : findsNothing,
      );
      if (count > 0) {
        final cards = tester
            .widgetList<MyEventMiniCard>(find.byType(MyEventMiniCard))
            .toList();
        expect(cards.first.featured, isTrue);
        expect(tester.getSize(find.byType(MyEventMiniCard).first).height, 120);
        expect(cards.skip(1).every((card) => !card.featured), isTrue);
      }
      if (count == 0) {
        await tester.tap(find.text('Create an event'));
        await tester.pumpAndSettle();
        expect(find.byType(CreateEventScreen), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'home fallback shows popular events without a find friends card',
    (tester) async {
      final event = _event(
        id: 'popular',
        date: DateTime.now().add(const Duration(days: 1)),
        title: 'Popular event',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aroundYourPeopleProvider.overrideWith((ref) async => []),
            eventsProvider.overrideWith((ref) => Stream.value([event])),
            isEventSavedProvider.overrideWith(
              (ref, eventId) => Stream.value(false),
            ),
            savedEventsServiceProvider.overrideWithValue(_SavedEventsService()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HomeDiscoverFallback()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Popular right now'), findsOneWidget);
      expect(find.text('Popular event'), findsOneWidget);
      expect(find.text('Plans are better together'), findsNothing);
      expect(
        find.text('Find your friends and see what they are up to.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  group('chats list', () {
    test(
      'only plans with chat are listed, unread first, then upcoming, then past',
      () {
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
          _event(
            id: 'nochat',
            date: now.add(const Duration(days: 2)),
            chat: false,
          ),
        ];

        final ids = ChatsScreen.chatsFrom(
          events,
          now,
        ).map((e) => e.id).toList();

        expect(ids, ['unread', 'quiet', 'past']);
      },
    );
  });

  group('home greeting line', () {
    test('invitations come first', () {
      expect(
        HomeGreeting.subtitleFor(
          pendingInvites: 1,
          upcoming: const [],
          now: now,
        ),
        '1 invitation is waiting for your answer.',
      );
      expect(
        HomeGreeting.subtitleFor(
          pendingInvites: 3,
          upcoming: const [],
          now: now,
        ),
        '3 invitations are waiting for your answer.',
      );
    });

    test('an empty calendar invites the user to plan something', () {
      expect(
        HomeGreeting.subtitleFor(
          pendingInvites: 0,
          upcoming: const [],
          now: now,
        ),
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
        HomeGreeting.subtitleFor(
          pendingInvites: 0,
          upcoming: [tonight],
          now: now,
        ),
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
        HomeGreeting.subtitleFor(
          pendingInvites: 0,
          upcoming: [later],
          now: now,
        ),
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
