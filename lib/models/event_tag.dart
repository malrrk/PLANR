import 'package:flutter/material.dart';

class EventTag {
  const EventTag({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

const eventTags = [
  EventTag(id: 'techno', label: 'Techno', icon: Icons.graphic_eq_rounded),
  EventTag(id: 'house', label: 'House', icon: Icons.music_note_rounded),
  EventTag(id: 'hiphop', label: 'Hip-Hop', icon: Icons.headphones_rounded),
  EventTag(id: 'clubbing', label: 'Clubbing', icon: Icons.nightlife_rounded),
  EventTag(id: 'bar', label: 'Bar', icon: Icons.local_bar_rounded),
  EventTag(id: 'pub', label: 'Pub', icon: Icons.sports_bar_rounded),
  EventTag(id: 'house_party', label: 'House Party', icon: Icons.house_rounded),
  EventTag(id: 'game_night', label: 'Game Night', icon: Icons.videogame_asset_rounded),
  EventTag(id: 'board_games', label: 'Board Games', icon: Icons.casino_rounded),
  EventTag(id: 'chill', label: 'Chill', icon: Icons.weekend_rounded),
  EventTag(id: 'food', label: 'Food', icon: Icons.restaurant_rounded),
  EventTag(id: 'outdoor', label: 'Outdoor', icon: Icons.park_rounded),
  EventTag(id: 'sports', label: 'Sports', icon: Icons.sports_soccer_rounded),
  EventTag(id: 'cinema', label: 'Cinema', icon: Icons.movie_rounded),
  EventTag(id: 'concert', label: 'Concert', icon: Icons.mic_external_on_rounded),
  EventTag(id: 'festival', label: 'Festival', icon: Icons.festival_rounded),
  EventTag(id: 'study', label: 'Study', icon: Icons.school_rounded),
  EventTag(id: 'student', label: 'Student', icon: Icons.groups_rounded),
  EventTag(id: 'free_entry', label: 'Free Entry', icon: Icons.confirmation_number_rounded),
  EventTag(id: 'spontaneous', label: 'Spontaneous', icon: Icons.bolt_rounded),
];

EventTag? eventTagById(String id) {
  for (final tag in eventTags) {
    if (tag.id == id) return tag;
  }
  return null;
}

List<String> sanitizeEventTagIds(List<String> ids) {
  final validIds = eventTags.map((tag) => tag.id).toSet();

  return ids
      .map((id) => id.trim().toLowerCase())
      .where(validIds.contains)
      .toSet()
      .take(3)
      .toList();
}

EventTag? primaryEventTag(List<String> tagIds) {
  for (final id in tagIds) {
    final tag = eventTagById(id);
    if (tag != null) return tag;
  }
  return null;
}