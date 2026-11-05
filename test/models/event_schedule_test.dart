import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/models/event_schedule.dart';

void main() {
  final now = DateTime.utc(2030, 1, 10);

  Event event(String id, int day) => Event.fromMap({
        'date': DateTime.utc(2030, 1, day),
        'createdAt': now,
      }, id);

  test('upcoming plans are ordered earliest first', () {
    final events = [event('later', 14), event('past', 9), event('next', 11)];

    expect(
      upcomingEvents(events, now: now).map((event) => event.id),
      ['next', 'later'],
    );
    expect(events.first.id, 'later');
  });

  test('Home preview can include the next three plans', () {
    final events = [
      event('fourth', 14),
      event('second', 12),
      event('first', 11),
      event('third', 13),
    ];

    expect(
      upcomingEvents(events, now: now, limit: 3).map((event) => event.id),
      ['first', 'second', 'third'],
    );
  });

  test('history is newest first and includes the exact start boundary', () {
    final events = [event('old', 1), event('future', 11), event('boundary', 10)];

    expect(
      pastEvents(events, now: now).map((event) => event.id),
      ['boundary', 'old'],
    );
  });

  test('empty collections produce empty lists', () {
    expect(upcomingEvents([], now: now), isEmpty);
    expect(pastEvents([], now: now), isEmpty);
  });
}