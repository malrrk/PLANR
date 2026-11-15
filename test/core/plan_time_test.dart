import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/core/plan_time.dart';

void main() {
  // Friday 2026-11-13 14:00
  final now = DateTime(2026, 11, 13, 14);

  group('planTimeLabel', () {
    test('uses Tonight for evening plans today and Today otherwise', () {
      expect(planTimeLabel(DateTime(2026, 11, 13, 20), now: now), 'Tonight · 20:00');
      expect(planTimeLabel(DateTime(2026, 11, 13, 16, 5), now: now), 'Today · 16:05');
    });

    test('uses Tomorrow, weekday and a date for later plans', () {
      expect(planTimeLabel(DateTime(2026, 11, 14, 18, 30), now: now), 'Tomorrow · 18:30');
      expect(planTimeLabel(DateTime(2026, 11, 17, 9), now: now), 'Tue · 09:00');
      expect(planTimeLabel(DateTime(2026, 12, 1, 21), now: now), '01.12 · 21:00');
    });
  });

  group('countdownLabel', () {
    test('describes how soon it is', () {
      expect(countdownLabel(DateTime(2026, 11, 13, 14, 30), now: now), 'Starting soon');
      expect(countdownLabel(DateTime(2026, 11, 13, 20), now: now), 'in 6 h');
      expect(countdownLabel(DateTime(2026, 11, 14, 12), now: now), 'Tomorrow');
      expect(countdownLabel(DateTime(2026, 11, 17, 12), now: now), 'in 4 days');
      expect(countdownLabel(DateTime(2026, 11, 13, 13), now: now), 'Happening now');
    });
  });

  test('greeting follows the time of day', () {
    expect(greetingFor(DateTime(2026, 1, 1, 3)), 'Still up');
    expect(greetingFor(DateTime(2026, 1, 1, 9)), 'Good morning');
    expect(greetingFor(DateTime(2026, 1, 1, 15)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 1, 1, 21)), 'Good evening');
  });

  test('firstNameOf handles empty and multi word names', () {
    expect(firstNameOf(null), '');
    expect(firstNameOf('  '), '');
    expect(firstNameOf('Alec Scuda'), 'Alec');
  });

  group('quickTimeOptions', () {
    test('offers tonight, tomorrow and the weekend during the day', () {
      final options = quickTimeOptions(now);

      expect(options.map((o) => o.label), [
        'Tonight 20:00',
        'Tomorrow 19:00',
      ]);
      expect(options.every((o) => o.date.isAfter(now)), isTrue);
    });

    test('falls back to the next full hour late in the evening', () {
      final late = DateTime(2026, 11, 13, 20, 10);
      final options = quickTimeOptions(late);

      expect(options.first.label, 'In an hour');
      expect(options.first.date, DateTime(2026, 11, 13, 21, 15));
    });

    test('offers Saturday when it is not tomorrow', () {
      final monday = DateTime(2026, 11, 9, 10);
      final options = quickTimeOptions(monday);

      expect(options.last.label, 'Saturday 18:00');
      expect(options.last.date, DateTime(2026, 11, 14, 18));
    });
  });
}
