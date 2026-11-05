import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/providers/friends_provider.dart';

void main() {
  test('friend request ids are ordered pairs the Firestore rules can derive', () {
    expect(friendRequestId(fromUid: 'alice', toUid: 'bob'), 'alice_bob');
    expect(
      friendRequestId(fromUid: 'alice', toUid: 'bob'),
      isNot(friendRequestId(fromUid: 'bob', toUid: 'alice')),
    );
  });
}
