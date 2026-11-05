import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/providers/moderation_provider.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);

  @override
  final String uid;
}

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(this.currentUser);

  @override
  final User? currentUser;
}

void main() {
  late FakeFirebaseFirestore firestore;
  late ModerationService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = ModerationService(firestore, _FakeAuth(_FakeUser('alice')));
  });

  test('report stores the reporter, target and reason', () async {
    final error = await service.report(
      target: ReportTarget.event,
      targetId: 'event1',
      reason: reportReasons.first,
      details: '  looks fake  ',
    );

    expect(error, isNull);

    final reports = await firestore.collection('reports').get();
    expect(reports.docs, hasLength(1));
    final data = reports.docs.single.data();
    expect(data['reporterUid'], 'alice');
    expect(data['targetType'], 'event');
    expect(data['targetId'], 'event1');
    expect(data['details'], 'looks fake');
  });

  test('report refuses an empty target and a signed-out user', () async {
    expect(
      await service.report(target: ReportTarget.user, targetId: ' ', reason: 'Spam'),
      isNotNull,
    );

    final signedOut = ModerationService(firestore, _FakeAuth(null));
    expect(
      await signedOut.report(target: ReportTarget.user, targetId: 'bob', reason: 'Spam'),
      'No user logged in.',
    );
    expect((await firestore.collection('reports').get()).docs, isEmpty);
  });

  test('blocking records the block and ends the friendship on both sides', () async {
    await firestore.doc('users/alice/friends/bob').set({'uid': 'bob'});
    await firestore.doc('users/bob/friends/alice').set({'uid': 'alice'});

    expect(await service.blockUser('bob'), isNull);

    expect((await firestore.doc('users/alice/blocked/bob').get()).exists, isTrue);
    expect((await firestore.doc('users/alice/friends/bob').get()).exists, isFalse);
    expect((await firestore.doc('users/bob/friends/alice').get()).exists, isFalse);
  });

  test('a user cannot block themselves, and unblocking removes the block', () async {
    expect(await service.blockUser('alice'), 'You cannot block yourself.');

    await service.blockUser('bob');
    expect(await service.unblockUser('bob'), isNull);
    expect((await firestore.doc('users/alice/blocked/bob').get()).exists, isFalse);
  });
}
