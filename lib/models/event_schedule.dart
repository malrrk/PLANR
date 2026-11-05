import 'event.dart';

List<Event> upcomingEvents(
  List<Event> events, {
  required DateTime now,
  int? limit,
}) {
  final upcoming = events.where((event) => event.date.isAfter(now)).toList()
    ..sort((first, second) => first.date.compareTo(second.date));
  return limit == null ? upcoming : upcoming.take(limit).toList();
}

List<Event> pastEvents(List<Event> events, {required DateTime now}) {
  return events.where((event) => !event.date.isAfter(now)).toList()
    ..sort((first, second) => second.date.compareTo(first.date));
}