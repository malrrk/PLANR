import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/story.dart';

void main() {
  test('dayKeyFromDate zero-pads month and day', () {
    expect(Story.dayKeyFromDate(DateTime(2030, 1, 5)), '2030-01-05');
    expect(Story.dayKeyFromDate(DateTime(2030, 12, 25)), '2030-12-25');
  });

  test('fromMap defaults to a user story that expires after seven days', () {
    final created = DateTime.utc(2030, 1, 1);
    final story = Story.fromMap({
      'id': 's1',
      'ownerUid': 'u1',
      'imageUrl': 'https://example.com/a.jpg',
      'createdAt': Timestamp.fromDate(created),
    });

    expect(story.isUserStory, isTrue);
    expect(story.ownerDisplayName, 'User');
    expect(story.expiresAt.toUtc(), created.add(const Duration(days: 7)));
    expect(story.isPublicPreview, isFalse);
    expect(story.storyOwnerKey, 'user_u1');
  });

  test('page stories use the page as owner key and default label', () {
    final story = Story.fromMap({
      'id': 's2',
      'ownerType': 'publicPage',
      'ownerUid': 'admin1',
      'pageId': 'page1',
      'imageUrl': 'https://example.com/b.jpg',
      'createdAt': Timestamp.fromDate(DateTime.utc(2030, 1, 1)),
    });

    expect(story.isPageStory, isTrue);
    expect(story.ownerDisplayName, 'Page');
    expect(story.storyOwnerKey, 'page_page1');
  });

  test('toMap and fromMap round trip', () {
    final story = Story(
      id: 's3',
      ownerType: 'user',
      ownerUid: 'u1',
      ownerDisplayName: 'Alex',
      ownerPhotoUrl: null,
      pageId: null,
      imageUrl: 'https://example.com/c.jpg',
      caption: null,
      createdAt: DateTime.utc(2030, 2, 2),
      expiresAt: DateTime.utc(2030, 2, 9),
      dayKey: '2030-02-02',
      isPublicPreview: false,
    );

    final copy = Story.fromMap(story.toMap());

    expect(copy.id, story.id);
    expect(copy.expiresAt.isAtSameMomentAs(story.expiresAt), isTrue);
    expect(copy.dayKey, story.dayKey);
    expect(copy.ownerDisplayName, 'Alex');
  });
}
