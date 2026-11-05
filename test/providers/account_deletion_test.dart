import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/providers/account_provider.dart';
import 'package:planner_app/providers/event_provider.dart';

class _FakeCredential extends Fake implements UserCredential {}

class _FakeUser extends Fake implements User {
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
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async {
    if ((credential as dynamic).password != 'correct') {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    return _FakeCredential();
  }

  @override
  Future<void> delete() async {
    deleted = true;
  }
}

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(this.currentUser);

  @override
  final User? currentUser;
}

/// Every call throws, like a bucket the user cannot reach. Deletion must carry on regardless.
class _BrokenStorage extends Fake implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _FakeUser user;
  late AccountService service;

  Future<bool> exists(String path) async => (await firestore.doc(path).get()).exists;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    user = _FakeUser();
    final auth = _FakeAuth(user);
    final storage = _BrokenStorage();
    service = AccountService(
      firestore,
      storage,
      auth,
      EventService(firestore, storage, auth),
    );

    await firestore.doc('users/alice').set({'uid': 'alice', 'username': 'alice'});
    await firestore.doc('usernames/alice').set({'uid': 'alice'});

    // An event alice hosts, with a guest, an invitee and a message.
    final hosted = {'creatorUid': 'alice', 'eventKind': 'private', 'visibility': 'private'};
    await firestore.doc('events/hosted').set({...hosted, 'attendeeCount': 2});
    await firestore.doc('events/hosted/attendees/alice').set({'uid': 'alice'});
    await firestore.doc('events/hosted/attendees/bob').set({'uid': 'bob'});
    await firestore.doc('events/hosted/invites/carl').set({'uid': 'carl'});
    await firestore.doc('users/carl/event_invites/hosted').set({'uid': 'carl'});
    await firestore.doc('events/hosted/messages/m1').set({'text': 'hi'});
    await firestore.doc('users/alice/my_events/hosted').set(hosted);
    await firestore.doc('users/bob/my_events/hosted').set(hosted);

    // An event bob hosts that alice joined.
    final joined = {'creatorUid': 'bob', 'eventKind': 'public', 'visibility': 'public'};
    await firestore.doc('events/joined').set({...joined, 'attendeeCount': 2});
    await firestore.doc('events/joined/attendees/alice').set({'uid': 'alice'});
    await firestore.doc('events/joined/attendees/bob').set({'uid': 'bob'});
    await firestore.doc('users/alice/my_events/joined').set(joined);

    // A pending invite alice never answered.
    await firestore.doc('events/invited').set({'creatorUid': 'bob', 'attendeeCount': 1});
    await firestore.doc('events/invited/invites/alice').set({'uid': 'alice'});
    await firestore.doc('users/alice/event_invites/invited').set({'uid': 'alice'});

    await firestore.doc('users/alice/friends/bob').set({'uid': 'bob'});
    await firestore.doc('users/bob/friends/alice').set({'uid': 'alice'});
    await firestore.doc('users/alice/blocked/mallory').set({'uid': 'mallory'});
    await firestore.doc('friend_requests/alice_dave').set({'fromUid': 'alice', 'toUid': 'dave'});
    await firestore.doc('friend_requests/erin_alice').set({'fromUid': 'erin', 'toUid': 'alice'});

    await firestore.doc('stories/s1').set({
      'ownerUid': 'alice',
      'ownerType': 'user',
      'imageUrl': 'not-a-storage-url',
    });
    await firestore.doc('stories/s2').set({'ownerUid': 'bob', 'ownerType': 'user'});

    await firestore.doc('public_pages/followed').set({'followerCount': 5, 'ownerUid': 'bob'});
    await firestore.doc('public_pages/followed/followers/alice').set({'uid': 'alice'});
    await firestore.doc('users/alice/followed_pages/followed').set({'pageId': 'followed'});
    await firestore.doc('public_pages/mine').set({'ownerUid': 'alice'});
  });

  test('a wrong password deletes nothing', () async {
    expect(await service.deleteAccount(password: 'wrong'), 'Password is incorrect.');

    expect(user.deleted, isFalse);
    expect(await exists('users/alice'), isTrue);
    expect(await exists('events/hosted'), isTrue);
  });

  test('deleting removes the account data and the login, and leaves other people alone', () async {
    expect(await service.deleteAccount(password: 'correct'), isNull);

    expect(user.deleted, isTrue);

    for (final path in [
      'users/alice',
      'usernames/alice',
      'events/hosted',
      'events/hosted/attendees/bob',
      'events/hosted/invites/carl',
      'events/hosted/messages/m1',
      'users/carl/event_invites/hosted',
      'users/bob/my_events/hosted',
      'users/alice/my_events/joined',
      'events/joined/attendees/alice',
      'events/invited/invites/alice',
      'users/alice/event_invites/invited',
      'users/alice/friends/bob',
      'users/bob/friends/alice',
      'users/alice/blocked/mallory',
      'friend_requests/alice_dave',
      'friend_requests/erin_alice',
      'stories/s1',
      'public_pages/followed/followers/alice',
      'users/alice/followed_pages/followed',
      'public_pages/mine',
    ]) {
      expect(await exists(path), isFalse, reason: '$path should be gone');
    }

    // Things that belong to other people survive.
    expect(await exists('events/joined'), isTrue);
    expect(await exists('events/joined/attendees/bob'), isTrue);
    expect(await exists('stories/s2'), isTrue);
    expect(await exists('public_pages/followed'), isTrue);

    // The event alice left lost exactly one attendee; the page lost exactly one follower.
    final joined = (await firestore.doc('events/joined').get()).data()!;
    expect(joined['attendeeCount'], 1);
    final page = (await firestore.doc('public_pages/followed').get()).data()!;
    expect(page['followerCount'], 4);
  });

  test('a signed-out user cannot delete anything', () async {
    final signedOut = AccountService(
      firestore,
      _BrokenStorage(),
      _FakeAuth(null),
      EventService(firestore, _BrokenStorage(), _FakeAuth(null)),
    );

    expect(await signedOut.deleteAccount(password: 'correct'), 'No user logged in.');
    expect(await exists('users/alice'), isTrue);
  });
}
