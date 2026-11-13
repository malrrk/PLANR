import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/providers/account_provider.dart';
import 'package:planner_app/providers/event_provider.dart';
import 'package:planner_app/providers/story_provider.dart';

/// A bucket that refuses every upload, like one whose billing account is closed (HTTP 402).
class _ClosedBucket extends Fake implements FirebaseStorage {
  @override
  Reference ref([String? path]) => _ClosedRef();
}

class _ClosedRef extends Fake implements Reference {
  @override
  Reference child(String path) => this;

  @override
  UploadTask putFile(File file, [SettableMetadata? metadata]) =>
      throw FirebaseException(plugin: 'firebase_storage', code: 'unknown');
}

class _User extends Fake implements User {
  _User({this.authTime});

  final DateTime? authTime;
  bool deleted = false;

  @override
  String get uid => 'alice';

  @override
  String? get email => 'alice@example.com';

  @override
  String? get displayName => 'Alice';

  @override
  String? get photoURL => null;

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async =>
      _Token(authTime);

  @override
  Future<void> delete() async => deleted = true;
}

class _Token extends Fake implements IdTokenResult {
  _Token(this._authTime);

  final DateTime? _authTime;

  @override
  DateTime? get authTime => _authTime;
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.currentUser);

  @override
  final User? currentUser;
}

void main() {
  late FakeFirebaseFirestore firestore;
  late _User user;
  late _Auth auth;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    user = _User(authTime: DateTime.now());
    auth = _Auth(user);
  });

  group('publishing', () {
    final future = DateTime.now().add(const Duration(days: 3));

    Future<String?> createPublicEvent(EventService service, {File? image}) {
      return service.createEvent(
        title: 'Rooftop party',
        description: 'Bring friends',
        address: 'Nuremberg',
        date: future,
        visibility: 'public',
        eventKind: 'public',
        chatEnabled: false,
        guestsCanInvite: true,
        tags: const [],
        imageFile: image,
      );
    }

    test('a public event created as the profile lands in events and My Planr', () async {
      final service = EventService(firestore, _ClosedBucket(), auth);

      expect(await createPublicEvent(service), isNull);

      final events = await firestore.collection('events').get();
      expect(events.docs, hasLength(1));
      expect(events.docs.single.data()['visibility'], 'public');
      expect(events.docs.single.data()['organizerType'], 'profile');
      final mine = await firestore.collection('users/alice/my_events').get();
      expect(mine.docs, hasLength(1));
    });

    test('an upload failure is reported as such and creates no event', () async {
      final service = EventService(firestore, _ClosedBucket(), auth);

      expect(
        await createPublicEvent(service, image: File('photo.jpg')),
        'Could not upload the photo. Please try again.',
      );
      expect((await firestore.collection('events').get()).docs, isEmpty);
      expect((await firestore.collection('users/alice/my_events').get()).docs, isEmpty);
    });

    test('a failed story upload is reported and creates no story', () async {
      final service = StoryService(firestore, _ClosedBucket(), auth);

      expect(
        await service.addStory(file: File('photo.jpg')),
        'Could not upload the photo. Please try again.',
      );
      expect((await firestore.collection('stories').get()).docs, isEmpty);
    });

    test('retrying after a failed upload still creates exactly one event', () async {
      final failing = EventService(firestore, _ClosedBucket(), auth);
      await createPublicEvent(failing, image: File('photo.jpg'));

      final working = EventService(firestore, _ClosedBucket(), auth);
      expect(await createPublicEvent(working), isNull);

      expect((await firestore.collection('events').get()).docs, hasLength(1));
    });
  });

  group('account deletion needs a fresh sign-in or a password', () {
    AccountService serviceFor(User account) {
      final accountAuth = _Auth(account);
      final storage = _ClosedBucket();
      return AccountService(
        firestore,
        storage,
        accountAuth,
        EventService(firestore, storage, accountAuth),
      );
    }

    setUp(() async {
      await firestore.doc('users/alice').set({'uid': 'alice', 'username': 'alice'});
    });

    test('an old sign-in asks for the password before anything is removed', () async {
      final stale = _User(authTime: DateTime.now().subtract(const Duration(hours: 2)));

      expect(await serviceFor(stale).deleteAccount(), AccountService.reauthRequired);

      expect(stale.deleted, isFalse);
      expect((await firestore.doc('users/alice').get()).exists, isTrue);
    });

    test('an unknown sign-in time is treated as old', () async {
      final unknown = _User();

      expect(await serviceFor(unknown).deleteAccount(), AccountService.reauthRequired);
      expect((await firestore.doc('users/alice').get()).exists, isTrue);
    });

    test('a recent sign-in deletes without asking for the password', () async {
      expect(await serviceFor(user).deleteAccount(), isNull);

      expect(user.deleted, isTrue);
      expect((await firestore.doc('users/alice').get()).exists, isFalse);
    });
  });
}
