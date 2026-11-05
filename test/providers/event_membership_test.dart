import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/providers/event_provider.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'bob';

  @override
  String? get displayName => 'Bob';

  @override
  String? get photoURL => null;
}

class _FakeAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _FakeUser();
}

class _UnusedStorage extends Fake implements FirebaseStorage {}

Future<int> _count(FakeFirebaseFirestore firestore, String eventId) async {
  final data = (await firestore.doc('events/$eventId').get()).data()!;
  return (data['attendeeCount'] as num).toInt();
}

void main() {
  late FakeFirebaseFirestore firestore;
  late EventService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = EventService(firestore, _UnusedStorage(), _FakeAuth());
  });

  Future<Event> seedPublicEvent() async {
    final data = {
      'creatorUid': 'alice',
      'creatorDisplayName': 'Alice',
      'eventKind': 'public',
      'visibility': 'public',
      'title': 'Party',
      'description': 'Fun',
      'address': 'Somewhere',
      'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
      'attendeeCount': 3,
    };
    await firestore.doc('events/e1').set(data);
    return Event.fromMap(data, 'e1');
  }

  test('joining adds one attendee, bumps the count and keeps a copy for the user', () async {
    final event = await seedPublicEvent();

    expect(await service.joinEvent(event), isNull);

    expect(await _count(firestore, 'e1'), 4);
    expect((await firestore.doc('events/e1/attendees/bob').get()).exists, isTrue);
    final mine = await firestore.doc('users/bob/my_events/e1').get();
    expect(mine.data()!['attendeeCount'], 4);
  });

  test('joining twice never counts the same person twice', () async {
    final event = await seedPublicEvent();

    await service.joinEvent(event);
    final second = await service.joinEvent(event);

    expect(second, 'You are already going.');
    expect(await _count(firestore, 'e1'), 4);
  });

  test('leaving removes the attendee and lowers the count', () async {
    final event = await seedPublicEvent();
    await service.joinEvent(event);

    expect(await service.leaveEvent(event), isNull);

    expect(await _count(firestore, 'e1'), 3);
    expect((await firestore.doc('events/e1/attendees/bob').get()).exists, isFalse);
    expect((await firestore.doc('users/bob/my_events/e1').get()).exists, isFalse);
    expect(await service.leaveEvent(event), 'You are not going to this event.');
  });

  test('accepting a declined invite joins once and marks both invite copies', () async {
    await firestore.doc('events/e2').set({
      'creatorUid': 'alice',
      'eventKind': 'private',
      'visibility': 'private',
      'attendeeCount': 1,
    });
    final invite = {'uid': 'bob', 'status': 'declined'};
    await firestore.doc('events/e2/invites/bob').set(invite);
    await firestore.doc('users/bob/event_invites/e2').set(invite);

    expect(await service.acceptEventInvite(eventId: 'e2'), isNull);

    expect(await _count(firestore, 'e2'), 2);
    expect((await firestore.doc('events/e2/invites/bob').get()).data()!['status'], 'accepted');
    expect(
      (await firestore.doc('users/bob/event_invites/e2').get()).data()!['status'],
      'accepted',
    );
    expect(await service.acceptEventInvite(eventId: 'e2'), 'You are already going.');
    expect(await _count(firestore, 'e2'), 2);
  });

  test('accepting without an invite or for a missing event fails cleanly', () async {
    await firestore.doc('events/e3').set({'creatorUid': 'alice', 'attendeeCount': 1});

    expect(await service.acceptEventInvite(eventId: 'e3'), 'Invite not found.');
    expect(await _count(firestore, 'e3'), 1);
  });

  test('new events reject over-long text and past dates before touching the database', () async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    Future<String?> create({String title = 'Party', String? description, DateTime? date}) {
      return service.createEvent(
        title: title,
        description: description ?? 'Fun',
        address: 'Somewhere',
        date: date ?? tomorrow,
        visibility: 'public',
        chatEnabled: false,
        guestsCanInvite: true,
        tags: const [],
      );
    }

    expect(await create(title: 'x' * 121), 'Title can be at most 120 characters.');
    expect(
      await create(description: 'x' * 2001),
      'Description can be at most 2000 characters.',
    );
    expect(
      await create(date: DateTime.now().subtract(const Duration(days: 1))),
      'Event date must be in the future.',
    );
    expect((await firestore.collection('events').get()).docs, isEmpty);
  });

  test('chat messages longer than the limit are refused', () async {
    final data = {
      'creatorUid': 'alice',
      'eventKind': 'private',
      'visibility': 'private',
      'chatEnabled': true,
    };
    await firestore.doc('events/e4').set(data);
    await firestore.doc('events/e4/attendees/bob').set({'uid': 'bob'});

    expect(
      await service.sendEventMessage(event: Event.fromMap(data, 'e4'), text: 'x' * 1001),
      'Message is too long.',
    );
  });
}
