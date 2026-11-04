import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/event_tag.dart';

void main() {
  test('there are 20 unique tags', () {
    expect(eventTags.length, 20);
    expect(eventTags.map((t) => t.id).toSet().length, 20);
  });

  test('eventTagById finds known ids and returns null otherwise', () {
    expect(eventTagById('techno')?.label, 'Techno');
    expect(eventTagById('nope'), isNull);
  });

  group('sanitizeEventTagIds', () {
    test('normalizes case and whitespace', () {
      expect(sanitizeEventTagIds([' Techno ', 'FOOD']), ['techno', 'food']);
    });

    test('drops unknown ids and duplicates', () {
      expect(
        sanitizeEventTagIds(['techno', 'unknown', 'techno']),
        ['techno'],
      );
    });

    test('keeps at most three tags in input order', () {
      expect(
        sanitizeEventTagIds(['techno', 'house', 'food', 'bar']),
        ['techno', 'house', 'food'],
      );
    });
  });

  test('primaryEventTag returns the first valid tag', () {
    expect(primaryEventTag(['unknown', 'house'])?.id, 'house');
    expect(primaryEventTag(const []), isNull);
  });
}
