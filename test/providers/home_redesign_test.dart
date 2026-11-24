import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/models/public_page.dart';
import 'package:planner_app/models/story_audience.dart';
import 'package:planner_app/models/user_profile.dart';
import 'package:planner_app/providers/event_provider.dart';
import 'package:planner_app/providers/firebase_providers.dart';
import 'package:planner_app/providers/public_page_provider.dart';
import 'package:planner_app/providers/relationships_provider.dart';
import 'package:planner_app/providers/saved_events_provider.dart';
import 'package:planner_app/providers/story_provider.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'alice';

  @override
  String? get displayName => 'Alice';

  @override
  String? get photoURL => null;
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _User();
}

class _UnusedStorage extends Fake implements FirebaseStorage {}

Event _publicEvent() {
  return Event.fromMap({
    'creatorUid': 'bob',
    'eventKind': 'public',
    'visibility': 'public',
    'title': 'Rooftop party',
    'description': 'Fun',
    'address': 'Nuremberg',
    'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
    'attendeeCount': 12,
  }, 'e1');
}

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  group('saved events', () {
    test('saving keeps a private copy and does not make the user attend', () async {
      final service = SavedEventsService(firestore, _Auth());

      expect(await service.save(_publicEvent()), isNull);

      final saved = await firestore.doc('users/alice/saved_events/e1').get();
      expect(saved.exists, isTrue);
      expect(saved.data()!['title'], 'Rooftop party');
      expect(saved.data()!['savedAt'], isNotNull);
      expect((await firestore.collection('events/e1/attendees').get()).docs, isEmpty);
    });

    test('a saved copy can be read back as an event and removed again', () async {
      final service = SavedEventsService(firestore, _Auth());
      await service.save(_publicEvent());

      final doc = await firestore.doc('users/alice/saved_events/e1').get();
      final event = Event.fromMap(doc.data()!, doc.id);
      expect(event.title, 'Rooftop party');
      expect(event.attendeeCount, 12);

      expect(await service.unsave('e1'), isNull);
      expect((await firestore.doc('users/alice/saved_events/e1').get()).exists, isFalse);
    });

    testWidgets('saved events use current data and omit deleted events', (tester) async {
      final service = SavedEventsService(firestore, _Auth());
      await service.save(_publicEvent());
      await firestore.doc('events/e1').set({
        ..._publicEvent().toMap(),
        'title': 'Updated party',
      });
      await firestore.doc('users/alice/saved_events/deleted').set({
        ..._publicEvent().toMap(),
        'savedAt': Timestamp.now(),
      });
      final container = ProviderContainer(overrides: [
        firebaseAuthProvider.overrideWithValue(_Auth()),
        firestoreProvider.overrideWithValue(firestore),
      ]);
      addTearDown(container.dispose);
      final subscription = container.listen(savedEventsProvider, (_, _) {});
      addTearDown(subscription.close);
      await tester.pump();
      await tester.pump();

      final events = container.read(savedEventsProvider).requireValue;
      expect(events.map((event) => event.title), ['Updated party']);

      await firestore.doc('events/e1').update({'title': 'Rescheduled party'});
      await tester.pump();
      await tester.pump();
      expect(
        container.read(savedEventsProvider).requireValue.single.title,
        'Rescheduled party',
      );

      await firestore.doc('events/e1').delete();
      await tester.pump();
      await tester.pump();
      expect(container.read(savedEventsProvider).requireValue, isEmpty);
    });
  });

  group('close friends', () {
    test('marking and unmarking only touches the owner\'s private list', () async {
      final service = RelationshipsService(firestore, _Auth());

      expect(await service.setCloseFriend('bob', true), isNull);
      final doc = await firestore.doc('users/alice/relationships/bob').get();
      expect(doc.data()!['tier'], 'close');
      expect((await firestore.doc('users/bob/relationships/alice').get()).exists, isFalse);

      expect(await service.setCloseFriend('bob', false), isNull);
      expect((await firestore.doc('users/alice/relationships/bob').get()).exists, isFalse);
    });
  });

  test('page admins are resolved through the username registry', () async {
    final page = PublicPage(
      id: 'venue', name: 'Venue', handle: 'venue', description: '',
      photoUrl: null, backgroundImageUrl: null, category: 'venue', tags: const [],
      followerCount: 0, eventCount: 0, isVerified: false, isActive: true,
      ownerUid: 'alice', adminUids: const ['alice'],
      createdAt: DateTime(2026), updatedAt: null,
    );
    await firestore.doc('public_pages/venue').set(page.toMap());
    await firestore.doc('usernames/bob').set({'uid': 'bob'});
    final service = PublicPageService(firestore, _UnusedStorage(), _Auth());

    expect(await service.addPageAdminByUsername(page: page, username: '@Bob'), isNull);
    expect((await firestore.doc('public_pages/venue').get()).data()!['adminUids'], contains('bob'));
  });

  testWidgets('page discovery includes active pages beyond the first 300', (tester) async {
    for (var index = 0; index < 301; index++) {
      await firestore.doc('public_pages/page$index').set({
        'name': 'Page $index',
        'handle': 'page$index',
        'isActive': true,
        'followerCount': index,
      });
    }
    final container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(publicPagesProvider, (_, _) {});
    addTearDown(subscription.close);
    await tester.pump();
    await tester.pump();
    expect(container.read(publicPagesProvider).requireValue, hasLength(301));
  });

  group('story audience', () {
    late StoryService service;

    setUp(() async {
      service = StoryService(firestore, _UnusedStorage(), _Auth());

      for (final uid in ['bob', 'cara', 'dan']) {
        await firestore.doc('users/alice/friends/$uid').set({'uid': uid});
      }
      await firestore
          .doc('users/alice/relationships/cara')
          .set({'uid': 'cara', 'tier': 'close'});
      // Not a friend any more, so never part of an audience.
      await firestore
          .doc('users/alice/relationships/zed')
          .set({'uid': 'zed', 'tier': 'close'});
    });

    Future<List<String>> viewers(StoryAudience audience, [List<String> picked = const []]) async {
      final uids = await service.viewerUidsFor(
        uid: 'alice',
        audience: audience,
        selectedUids: picked,
      );
      return [...uids]..sort();
    }

    test('public and only me store no viewer list', () async {
      expect(await viewers(StoryAudience.public), isEmpty);
      expect(await viewers(StoryAudience.onlyMe), isEmpty);
    });

    test('friends means every current friend', () async {
      expect(await viewers(StoryAudience.friends), ['bob', 'cara', 'dan']);
    });

    test('close friends are the private close list limited to current friends', () async {
      expect(await viewers(StoryAudience.close), ['cara']);
    });

    test('selected people must still be friends', () async {
      expect(
        await viewers(StoryAudience.selected, ['bob', 'stranger']),
        ['bob'],
      );
    });

    test('a story that needs picked people cannot be posted without any', () async {
      expect(
        await service.addStory(
          file: File('photo.jpg'),
          audience: StoryAudience.selected,
        ),
        'Pick at least one person.',
      );
    });
  });

  group('quick plans', () {
    test('creates a private plan with chat and invites the chosen friends', () async {
      final service = EventService(firestore, _UnusedStorage(), _Auth());

      final error = await service.createQuickPlan(
        title: 'Coffee',
        date: DateTime.now().add(const Duration(hours: 3)),
        invitees: const [
          UserProfile(
            uid: 'bob',
            displayName: 'Bob',
            username: 'bob',
            usernameLower: 'bob',
            email: '',
          ),
        ],
      );

      expect(error, isNull);

      final events = await firestore.collection('events').get();
      expect(events.docs, hasLength(1));
      final event = events.docs.single.data();
      expect(event['visibility'], 'private');
      expect(event['chatEnabled'], isTrue);
      expect(event['address'], 'Place to be decided');

      final id = events.docs.single.id;
      expect((await firestore.doc('events/$id/invites/bob').get()).exists, isTrue);
      final invite = await firestore.doc('users/bob/event_invites/$id').get();
      expect(invite.data()!['status'], 'pending');
      expect(invite.data()!['eventTitle'], 'Coffee');
    });

    test('works without invitees and rejects plans in the past', () async {
      final service = EventService(firestore, _UnusedStorage(), _Auth());

      expect(
        await service.createQuickPlan(
          title: 'Walk',
          date: DateTime.now().add(const Duration(days: 1)),
          place: 'Park',
        ),
        isNull,
      );
      expect(
        await service.createQuickPlan(
          title: 'Too late',
          date: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        'Event date must be in the future.',
      );
    });
  });
}
