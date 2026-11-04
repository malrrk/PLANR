import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/public_page.dart';
import 'package:planner_app/models/user_profile.dart';

void main() {
  group('PublicPage', () {
    test('fromMap applies defaults', () {
      final page = PublicPage.fromMap({}, 'doc1');

      expect(page.id, 'doc1');
      expect(page.name, 'Untitled Page');
      expect(page.category, 'page');
      expect(page.isActive, isTrue);
      expect(page.isVerified, isFalse);
      expect(page.followerCount, 0);
      expect(page.adminUids, isEmpty);
      expect(page.displayHandle, '');
    });

    test('fromMap reads values and displayHandle adds @', () {
      final page = PublicPage.fromMap({
        'id': 'p1',
        'name': 'Club',
        'handle': 'club',
        'followerCount': 12,
        'ownerUid': 'u1',
        'adminUids': ['u1', 'u2'],
        'createdAt': Timestamp.fromDate(DateTime.utc(2030)),
      }, 'ignored');

      expect(page.id, 'p1');
      expect(page.displayHandle, '@club');
      expect(page.followerCount, 12);
      expect(page.adminUids, ['u1', 'u2']);
    });

    test('toMap and fromMap round trip', () {
      final page = PublicPage.fromMap({
        'name': 'Club',
        'handle': 'club',
        'tags': ['food'],
        'createdAt': Timestamp.fromDate(DateTime.utc(2030)),
      }, 'p2');

      final copy = PublicPage.fromMap(page.toMap(), 'p2');

      expect(copy.name, 'Club');
      expect(copy.tags, ['food']);
      expect(copy.createdAt, page.createdAt);
    });
  });

  group('UserProfile', () {
    test('fromMap applies defaults', () {
      final profile = UserProfile.fromMap({'uid': 'u1'});

      expect(profile.displayName, 'User');
      expect(profile.username, '');
      expect(profile.score, 0);
      expect(profile.pinnedStoryImageUrls, isEmpty);
    });

    test('toMap and fromMap round trip', () {
      const profile = UserProfile(
        uid: 'u1',
        displayName: 'Alex',
        username: 'alex',
        usernameLower: 'alex',
        email: 'a@b.c',
        pinnedStoryImageUrls: ['x', 'y'],
        hostedEventCount: 2,
      );

      final copy = UserProfile.fromMap(profile.toMap());

      expect(copy.username, 'alex');
      expect(copy.pinnedStoryImageUrls, ['x', 'y']);
      expect(copy.hostedEventCount, 2);
    });

    test('copyWith keeps untouched fields', () {
      const profile = UserProfile(
        uid: 'u1',
        displayName: 'Alex',
        username: 'alex',
        usernameLower: 'alex',
        email: 'a@b.c',
      );

      final copy = profile.copyWith(displayName: 'Sam');

      expect(copy.displayName, 'Sam');
      expect(copy.uid, 'u1');
      expect(copy.email, 'a@b.c');
    });
  });
}
