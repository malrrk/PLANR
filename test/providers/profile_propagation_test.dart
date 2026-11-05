import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/providers/user_profile_provider.dart';

class _UnusedStorage extends Fake implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore firestore;
  late UserProfileService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = UserProfileService(firestore, _UnusedStorage());
  });

  test('a changed name and photo reach every copy other people see', () async {
    await firestore.doc('users/alice/friends/bob').set({'uid': 'bob'});
    await firestore.doc('users/bob/friends/alice').set({
      'uid': 'alice',
      'displayName': 'Old',
    });

    // Event hosted by alice, attended by bob.
    await firestore.doc('events/e1').set({
      'creatorUid': 'alice',
      'creatorDisplayName': 'Old',
      'organizerType': 'profile',
      'organizerDisplayName': 'Old',
    });
    await firestore.doc('events/e1/attendees/alice').set({'uid': 'alice', 'displayName': 'Old'});
    await firestore.doc('events/e1/attendees/bob').set({'uid': 'bob', 'displayName': 'Bob'});
    final hosted = {
      'creatorUid': 'alice',
      'creatorDisplayName': 'Old',
      'organizerType': 'profile',
      'organizerDisplayName': 'Old',
    };
    await firestore.doc('users/alice/my_events/e1').set(hosted);
    await firestore.doc('users/bob/my_events/e1').set(hosted);

    // Event hosted by someone else that alice attends.
    await firestore.doc('events/e2').set({'creatorUid': 'bob', 'creatorDisplayName': 'Bob'});
    await firestore.doc('events/e2/attendees/alice').set({'uid': 'alice', 'displayName': 'Old'});
    await firestore.doc('users/alice/my_events/e2').set({
      'creatorUid': 'bob',
      'creatorDisplayName': 'Bob',
    });

    await firestore.doc('stories/s1').set({
      'ownerUid': 'alice',
      'ownerType': 'user',
      'ownerDisplayName': 'Old',
    });

    await service.propagateProfileChange(
      uid: 'alice',
      displayName: 'Alice New',
      bio: 'hi',
      photoUrl: 'https://example.com/a.jpg',
    );

    Future<Map<String, dynamic>> read(String path) async =>
        (await firestore.doc(path).get()).data()!;

    expect((await read('users/bob/friends/alice'))['displayName'], 'Alice New');
    expect((await read('users/bob/friends/alice'))['photoUrl'], 'https://example.com/a.jpg');

    expect((await read('events/e1'))['creatorDisplayName'], 'Alice New');
    expect((await read('events/e1'))['organizerDisplayName'], 'Alice New');
    expect((await read('users/bob/my_events/e1'))['creatorDisplayName'], 'Alice New');
    expect((await read('events/e1/attendees/alice'))['displayName'], 'Alice New');

    // Someone else's event keeps its host but shows the new attendee name.
    expect((await read('events/e2'))['creatorDisplayName'], 'Bob');
    expect((await read('events/e2/attendees/alice'))['displayName'], 'Alice New');

    expect((await read('stories/s1'))['ownerDisplayName'], 'Alice New');
  });

  test('copies that no longer exist do not fail the update', () async {
    await firestore.doc('users/alice/friends/ghost').set({'uid': 'ghost'});

    await service.propagateProfileChange(uid: 'alice', displayName: 'Alice New');
  });

  test('over-long names and bios are rejected with a readable message', () async {
    expect(
      () => service.updateProfile(uid: 'alice', displayName: 'x' * 61),
      throwsA(isA<ProfileException>()),
    );
    expect(
      () => service.updateProfile(uid: 'alice', displayName: 'Alice', bio: 'x' * 301),
      throwsA(isA<ProfileException>()),
    );
    expect(
      () => service.updateProfile(uid: 'alice', displayName: '  '),
      throwsA(
        isA<ProfileException>().having((e) => e.message, 'message', 'Display name is required.'),
      ),
    );
  });
}
