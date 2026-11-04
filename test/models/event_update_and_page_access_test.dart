import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/public_page.dart';
import 'package:planner_app/providers/event_provider.dart';

void main() {
  group('EventUpdate.fromMap', () {
    test('applies defaults', () {
      final update = EventUpdate.fromMap({}, 'u1');

      expect(update.id, 'u1');
      expect(update.authorName, 'Organizer');
      expect(update.text, '');
      expect(update.isPinned, isFalse);
    });

    test('reads values', () {
      final created = DateTime.utc(2030, 1, 1);
      final update = EventUpdate.fromMap({
        'authorUid': 'a1',
        'authorName': 'Alex',
        'text': 'Doors at 8',
        'isPinned': true,
        'createdAt': Timestamp.fromDate(created),
      }, 'u2');

      expect(update.authorUid, 'a1');
      expect(update.text, 'Doors at 8');
      expect(update.isPinned, isTrue);
      expect(update.createdAt.isAtSameMomentAs(created), isTrue);
    });
  });

  group('PublicPage.canBeManagedBy', () {
    final page = PublicPage.fromMap({
      'ownerUid': 'owner',
      'adminUids': ['owner', 'admin'],
    }, 'p1');

    test('owner and admins can manage', () {
      expect(page.canBeManagedBy('owner'), isTrue);
      expect(page.canBeManagedBy('admin'), isTrue);
    });

    test('other users cannot manage', () {
      expect(page.canBeManagedBy('someone'), isFalse);
    });
  });
}
