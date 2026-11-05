import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/user_profile.dart';
import 'package:planner_app/providers/friends_provider.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'alice';

  @override
  String? get displayName => 'Alice';

  @override
  String? get photoURL => null;
}

class _FakeAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _FakeUser();
}

UserProfile _bob() => const UserProfile(
      uid: 'bob',
      displayName: 'Bob',
      username: 'bob',
      usernameLower: 'bob',
      email: '',
    );

void main() {
  late FakeFirebaseFirestore firestore;
  late FriendsService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FriendsService(firestore, _FakeAuth());
  });

  test('a request is stored under the id the Firestore rules expect', () async {
    expect(await service.sendFriendRequest(toUser: _bob()), isNull);

    final doc = await firestore.doc('friend_requests/alice_bob').get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['status'], 'pending');
    expect(doc.data()!['fromUid'], 'alice');
  });

  test('sending twice reports the pending request', () async {
    await service.sendFriendRequest(toUser: _bob());

    expect(await service.sendFriendRequest(toUser: _bob()), 'Request already sent.');
  });

  test('a pending request from the other person is not duplicated', () async {
    await firestore.doc('friend_requests/bob_alice').set({
      'fromUid': 'bob',
      'toUid': 'alice',
      'status': 'pending',
    });

    final error = await service.sendFriendRequest(toUser: _bob());

    expect(error, contains('already sent you a request'));
    expect((await firestore.doc('friend_requests/alice_bob').get()).exists, isFalse);
  });

  test('a recently declined request cannot be sent again', () async {
    await firestore.doc('friend_requests/alice_bob').set({
      'fromUid': 'alice',
      'toUid': 'bob',
      'status': 'declined',
      'declinedAt': Timestamp.now(),
    });

    expect(
      await service.sendFriendRequest(toUser: _bob()),
      'You cannot send another request right now.',
    );
  });

  test('a request declined long ago can be sent again', () async {
    await firestore.doc('friend_requests/alice_bob').set({
      'fromUid': 'alice',
      'toUid': 'bob',
      'status': 'declined',
      'declinedAt': Timestamp.fromDate(
        DateTime.now().subtract(friendRequestCooldown + const Duration(days: 1)),
      ),
    });

    expect(await service.sendFriendRequest(toUser: _bob()), isNull);
    expect(
      (await firestore.doc('friend_requests/alice_bob').get()).data()!['status'],
      'pending',
    );
  });

  test('existing friends are told so instead of sending a request', () async {
    await firestore.doc('users/alice/friends/bob').set({'uid': 'bob'});

    expect(await service.sendFriendRequest(toUser: _bob()), 'You are already friends.');
  });
}
