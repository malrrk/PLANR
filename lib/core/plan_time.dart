const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _two(int value) => value.toString().padLeft(2, '0');

String clockLabel(DateTime date) => '${_two(date.hour)}:${_two(date.minute)}';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Tonight · 20:00", "Tomorrow · 18:30", "Sat · 21:00" or "14.11 · 20:00".
String planTimeLabel(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(date.year, date.month, date.day);
  final daysAway = day.difference(today).inDays;
  final clock = clockLabel(date);

  if (daysAway == 0) {
    return date.hour >= 17 ? 'Tonight · $clock' : 'Today · $clock';
  }
  if (daysAway == 1) return 'Tomorrow · $clock';
  if (daysAway > 1 && daysAway < 7) {
    return '${_weekdays[date.weekday - 1]} · $clock';
  }

  return '${_two(date.day)}.${_two(date.month)} · $clock';
}

/// Short urgency hint such as "Starting soon", "in 3 h" or "in 4 days".
String countdownLabel(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final difference = date.difference(current);

  if (difference.isNegative) return 'Happening now';
  if (difference.inMinutes < 60) return 'Starting soon';
  if (difference.inHours < 24 && isSameDay(date, current)) {
    return 'in ${difference.inHours} h';
  }

  final today = DateTime(current.year, current.month, current.day);
  final days = DateTime(date.year, date.month, date.day).difference(today).inDays;

  if (days == 1) return 'Tomorrow';
  return 'in $days days';
}

String greetingFor(DateTime now) {
  final hour = now.hour;

  if (hour < 5) return 'Still up';
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

String firstNameOf(String? displayName) {
  final trimmed = displayName?.trim() ?? '';
  if (trimmed.isEmpty) return '';

  return trimmed.split(RegExp(r'\s+')).first;
}

/// Upcoming slots offered by the quick plan sheet.
class QuickTimeOption {
  const QuickTimeOption(this.label, this.date);

  final String label;
  final DateTime date;
}

List<QuickTimeOption> quickTimeOptions(DateTime now) {
  final options = <QuickTimeOption>[];

  final tonight = DateTime(now.year, now.month, now.day, 20);
  if (tonight.isAfter(now.add(const Duration(minutes: 45)))) {
    options.add(QuickTimeOption('Tonight 20:00', tonight));
  } else {
    final soon = now.add(const Duration(hours: 1));
    final rounded = DateTime(soon.year, soon.month, soon.day, soon.hour, soon.minute)
        .add(Duration(minutes: (15 - soon.minute % 15) % 15));
    options.add(QuickTimeOption('In an hour', rounded));
  }

  final tomorrow = DateTime(now.year, now.month, now.day + 1, 19);
  options.add(QuickTimeOption('Tomorrow 19:00', tomorrow));

  var daysToSaturday = (DateTime.saturday - now.weekday) % 7;
  if (daysToSaturday == 0 && now.hour >= 17) daysToSaturday = 7;
  final saturday =
      DateTime(now.year, now.month, now.day + daysToSaturday, 18);
  if (!isSameDay(saturday, tomorrow) && saturday.isAfter(now)) {
    options.add(QuickTimeOption('Saturday 18:00', saturday));
  }

  return options;
}
