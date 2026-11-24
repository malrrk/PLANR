import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/core/story_views.dart';
import 'package:planner_app/l10n/gen/app_localizations.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/models/public_page.dart';
import 'package:planner_app/models/story.dart';
import 'package:planner_app/models/story_audience.dart';
import 'package:planner_app/models/user_profile.dart';
import 'package:planner_app/providers/event_provider.dart';
import 'package:planner_app/providers/friends_provider.dart';
import 'package:planner_app/providers/home_feed_provider.dart';
import 'package:planner_app/providers/moderation_provider.dart';
import 'package:planner_app/providers/public_page_provider.dart';
import 'package:planner_app/providers/saved_events_provider.dart';
import 'package:planner_app/providers/story_provider.dart';
import 'package:planner_app/providers/user_profile_provider.dart';
import 'package:planner_app/screens/chats_screen.dart';
import 'package:planner_app/screens/create_event_screen.dart';
import 'package:planner_app/screens/public_page_screen.dart';
import 'package:planner_app/screens/story_viewer_screen.dart';
import 'package:planner_app/widgets/event_detail/event_detail_header_image.dart';
import 'package:planner_app/widgets/home/home_greeting.dart';
import 'package:planner_app/widgets/home/home_discover_fallback.dart';
import 'package:planner_app/widgets/home/home_header.dart';
import 'package:planner_app/widgets/home/home_next_up_section.dart';
import 'package:planner_app/widgets/home/home_people_section.dart';
import 'package:planner_app/widgets/home/home_saved_section.dart';
import 'package:planner_app/widgets/home/home_stories_row.dart';
import 'package:planner_app/widgets/home/my_event_mini_card.dart';
import 'package:planner_app/widgets/save_event_button.dart';

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

class _HostUser extends Fake implements User {
  @override
  String get uid => 'a';
}

class _HostAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _HostUser();
}

class _StoryService extends Fake implements StoryService {
  @override
  List<StoryGroup> groupStoriesByOwnerAndDay(List<Story> stories) => [];
}

class _SavedEventsService extends Fake implements SavedEventsService {}

class _AnnouncementService extends Fake implements EventService {
  @override
  Future<bool> canManageEventUpdates(Event event) async => true;
}

class _PageStoryService extends Fake implements StoryService {
  _PageStoryService(this.group);

  final StoryGroup group;

  @override
  List<StoryGroup> groupStoriesByOwnerAndDay(List<Story> stories) => [group];

  @override
  StoryGroup? storyGroupById(List<Story> stories, String groupId) => group;
}

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

  testWidgets('public event details offer a save action', (tester) async {
    final event = Event.fromMap({
      'creatorUid': 'host',
      'eventKind': 'public',
      'visibility': 'public',
      'title': 'Concert',
      'date': DateTime.now().add(const Duration(days: 1)),
    }, 'concert');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isEventSavedProvider.overrideWith((ref, eventId) => Stream.value(false)),
          savedEventsServiceProvider.overrideWithValue(_SavedEventsService()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(slivers: [EventDetailHeaderImage(event: event)]),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SaveEventButton), findsOneWidget);
  });

  testWidgets('home shows followed public pages', (tester) async {
    final page = PublicPage(
      id: 'venue',
      name: 'The Venue',
      handle: 'venue',
      description: '',
      photoUrl: null,
      backgroundImageUrl: null,
      category: 'venue',
      tags: const [],
      followerCount: 2,
      eventCount: 1,
      isVerified: false,
      isActive: true,
      ownerUid: 'host',
      adminUids: const ['host'],
      createdAt: DateTime(2026),
      updatedAt: null,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          followedPagesProvider.overrideWith((ref) => Stream.value([page])),
          aroundYourPeopleProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: Scaffold(body: HomePeopleSection())),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('The Venue'), findsOneWidget);
  });

  testWidgets('home can show events organized by the user', (tester) async {
    final event = _event(id: 'hosted', date: DateTime.now().add(const Duration(days: 1)), title: 'Hosted plan');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(_HostAuth()),
          myEventsProvider.overrideWith((ref) => Stream.value([event])),
          myManagedPublicPagesProvider.overrideWith((ref) => Stream.value([])),
          eventsProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeNextUpSection())),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Hosting'));
    await tester.pump();
    expect(find.text('Hosted plan'), findsOneWidget);
  });

  testWidgets('saved events can be opened as a full list', (tester) async {
    final event = Event.fromMap({
      'creatorUid': 'host', 'eventKind': 'public', 'visibility': 'public',
      'title': 'Saved concert', 'date': DateTime.now().add(const Duration(days: 1)),
    }, 'concert');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedEventsProvider.overrideWith((ref) => Stream.value([event])),
          isEventSavedProvider.overrideWith((ref, eventId) => Stream.value(true)),
          savedEventsServiceProvider.overrideWithValue(_SavedEventsService()),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeSavedSection())),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.text('Saved events'), findsOneWidget);
    expect(find.text('Saved concert'), findsOneWidget);
  });

  testWidgets('home suggests events matching profile interests', (tester) async {
    final event = Event.fromMap({
      'creatorUid': 'host', 'eventKind': 'public', 'visibility': 'public',
      'title': 'Food festival', 'tags': ['food'],
      'date': DateTime.now().add(const Duration(days: 1)),
    }, 'festival');
    const profile = UserProfile(
      uid: 'a', displayName: 'Alex', username: 'alex', usernameLower: 'alex',
      email: '', interests: ['food'],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aroundYourPeopleProvider.overrideWith((ref) async => []),
          eventsProvider.overrideWith((ref) => Stream.value([event])),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(profile)),
          myEventsProvider.overrideWith((ref) => Stream.value([])),
          savedEventsProvider.overrideWith((ref) => Stream.value([])),
          isEventSavedProvider.overrideWith((ref, eventId) => Stream.value(false)),
          savedEventsServiceProvider.overrideWithValue(_SavedEventsService()),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeDiscoverFallback())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Picked for you'), findsOneWidget);
    expect(find.text('Food festival'), findsOneWidget);
  });

  testWidgets('page managers can delete a page story without pinning it', (tester) async {
    final story = Story(
      id: 'story',
      ownerType: 'publicPage',
      ownerUid: 'other',
      ownerDisplayName: 'Venue',
      ownerPhotoUrl: null,
      pageId: 'venue',
      imageUrl: 'https://example.com/story.jpg',
      caption: null,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      dayKey: '2026-11-24',
      isPublicPreview: true,
    );
    final group = StoryGroup(
      groupId: 'page_venue_2026-11-24',
      ownerType: story.ownerType,
      ownerUid: story.ownerUid,
      ownerDisplayName: story.ownerDisplayName,
      ownerPhotoUrl: null,
      pageId: 'venue',
      dayKey: story.dayKey,
      stories: [story],
    );
    final page = PublicPage(
      id: 'venue', name: 'Venue', handle: 'venue', description: '',
      photoUrl: null, backgroundImageUrl: null, category: 'venue', tags: const [],
      followerCount: 0, eventCount: 0, isVerified: false, isActive: true,
      ownerUid: 'a', adminUids: const ['a'], createdAt: DateTime(2026), updatedAt: null,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(_HostAuth()),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
          friendsStoriesProvider.overrideWith((ref) => Stream.value([story])),
          publicPageByIdProvider.overrideWith((ref, pageId) => Stream.value(page)),
          storyServiceProvider.overrideWithValue(_PageStoryService(group)),
        ],
        child: MaterialApp(home: StoryViewerScreen(initialGroupId: group.groupId)),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Delete story'), findsOneWidget);
    expect(find.text('Pin to profile'), findsNothing);
  });

  testWidgets('public pages show their active story previews', (tester) async {
    final page = PublicPage(
      id: 'venue', name: 'Venue', handle: 'venue', description: '',
      photoUrl: null, backgroundImageUrl: null, category: 'venue', tags: const [],
      followerCount: 0, eventCount: 0, isVerified: false, isActive: true,
      ownerUid: 'a', adminUids: const ['a'], createdAt: DateTime(2026), updatedAt: null,
    );
    final story = Story(
      id: 'story', ownerType: 'publicPage', ownerUid: 'a', ownerDisplayName: 'Venue',
      ownerPhotoUrl: null, pageId: 'venue', imageUrl: 'https://example.com/story.jpg',
      caption: null, createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      dayKey: '2026-11-24', isPublicPreview: true,
    );
    final group = StoryGroup(
      groupId: 'page_venue_2026-11-24', ownerType: story.ownerType,
      ownerUid: story.ownerUid, ownerDisplayName: story.ownerDisplayName,
      ownerPhotoUrl: null, pageId: 'venue', dayKey: story.dayKey, stories: [story],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(_HostAuth()),
          publicPageByIdProvider.overrideWith((ref, pageId) => Stream.value(page)),
          publicPageEventsProvider.overrideWith((ref, pageId) => Stream.value([])),
          publicPagePreviewStoriesProvider.overrideWith((ref, pageId) => Stream.value([story])),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
          storyServiceProvider.overrideWithValue(_PageStoryService(group)),
        ],
        child: const MaterialApp(home: PublicPageScreen(pageId: 'venue')),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Stories'), findsOneWidget);
    expect(find.text('View story'), findsOneWidget);
    await tester.tap(find.text('View story'));
    await tester.pumpAndSettle();
    expect(find.byType(StoryViewerScreen), findsOneWidget);
  });

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

  testWidgets('stories report a failed friends feed instead of appearing empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          firebaseAuthProvider.overrideWithValue(_HostAuth()),
          myFriendsProvider.overrideWith((ref) => Stream.error(Exception('Unavailable'))),
          followedPagesProvider.overrideWith((ref) => Stream.value([])),
          myManagedPublicPagesProvider.overrideWith((ref) => Stream.value([])),
          blockedUidsProvider.overrideWith((ref) => Stream.value(<String>{})),
          storyServiceProvider.overrideWithValue(_StoryService()),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeStoriesRow())),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(HomeStoriesRow)));
    expect(container.read(friendsStoriesProvider).error.toString(), contains('Unavailable'));
    expect(find.text('Could not load stories.'), findsOneWidget);
    expect(find.text('No stories yet. Be the first to share a moment.'), findsNothing);
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
    testWidgets('new organizer announcements show an unread indicator', (tester) async {
      final event = Event.fromMap({
        'creatorUid': 'host', 'eventKind': 'public', 'visibility': 'public',
        'chatEnabled': false, 'title': 'Concert',
        'date': DateTime.now().add(const Duration(days: 1)),
      }, 'concert');
      final update = EventUpdate(
        id: 'update', authorUid: 'host', authorName: 'Host', authorPhotoUrl: null,
        text: 'Doors open at seven', createdAt: DateTime.now(), isPinned: false,
      );
      final firestore = FakeFirebaseFirestore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(_HostAuth()),
            firestoreProvider.overrideWithValue(firestore),
            myEventsProvider.overrideWith((ref) => Stream.value([event])),
            myManagedPublicPagesProvider.overrideWith((ref) => Stream.value([])),
            eventUpdatesProvider.overrideWith((ref, eventId) => Stream.value([update])),
            eventByIdProvider.overrideWith((ref, eventId) => Stream.value(event)),
            eventServiceProvider.overrideWithValue(_AnnouncementService()),
          ],
          child: const MaterialApp(home: ChatsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pump();
      final container = ProviderScope.containerOf(tester.element(find.byType(ChatsScreen)));
      expect(container.read(announcementReadAtProvider('concert')).hasValue, isTrue);
      expect(
        find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == 'Unread announcements'),
        findsOneWidget,
      );
      await tester.tap(find.text('Concert'));
      await tester.pumpAndSettle();
      await tester.pump();
      expect((await firestore.doc('users/a/announcement_reads/concert').get()).exists, isTrue);
    });

    testWidgets('page admins see announcement channels for managed events', (tester) async {
      final page = PublicPage(
        id: 'venue', name: 'Venue', handle: 'venue', description: '',
        photoUrl: null, backgroundImageUrl: null, category: 'venue', tags: const [],
        followerCount: 0, eventCount: 1, isVerified: false, isActive: true,
        ownerUid: 'owner', adminUids: const ['owner', 'a'],
        createdAt: DateTime(2026), updatedAt: null,
      );
      final event = Event.fromMap({
        'creatorUid': 'owner', 'eventKind': 'public', 'visibility': 'public',
        'organizerType': 'publicPage', 'organizerId': 'venue',
        'chatEnabled': false, 'title': 'Venue concert',
        'date': DateTime.now().add(const Duration(days: 1)),
      }, 'concert');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsProvider.overrideWith((ref) => Stream.value([])),
            myManagedPublicPagesProvider.overrideWith((ref) => Stream.value([page])),
            eventsProvider.overrideWith((ref) => Stream.value([event])),
          ],
          child: const MaterialApp(home: ChatsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Venue concert'), findsOneWidget);
    });

    testWidgets('public event channel opens organizer announcements', (tester) async {
      final event = Event.fromMap({
        'creatorUid': 'host',
        'eventKind': 'public',
        'visibility': 'public',
        'chatEnabled': false,
        'title': 'Concert',
        'date': DateTime.now().add(const Duration(days: 1)),
      }, 'concert');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsProvider.overrideWith((ref) => Stream.value([event])),
            myManagedPublicPagesProvider.overrideWith((ref) => Stream.value([])),
            eventByIdProvider.overrideWith((ref, eventId) => Stream.value(event)),
            eventUpdatesProvider.overrideWith((ref, eventId) => Stream.value([])),
            eventServiceProvider.overrideWithValue(_AnnouncementService()),
          ],
          child: const MaterialApp(home: ChatsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concert'));
      await tester.pumpAndSettle();
      expect(find.text('Announcements'), findsOneWidget);
      expect(find.text('Post an update for everyone...'), findsOneWidget);
    });

    test('public events appear as announcement channels', () {
      final publicEvent = Event.fromMap({
        'creatorUid': 'host',
        'eventKind': 'public',
        'visibility': 'public',
        'chatEnabled': false,
        'title': 'Concert',
        'date': now.add(const Duration(days: 1)),
      }, 'concert');

      expect(ChatsScreen.chatsFrom([publicEvent], now), [publicEvent]);
    });

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
