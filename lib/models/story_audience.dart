import 'package:flutter/material.dart';

/// Who can see a story. `close` is the author's private "Close friends" list.
enum StoryAudience {
  public('public', 'Public', 'Anyone who follows you or your page', Icons.public_rounded),
  friends('friends', 'Friends', 'Everyone you are connected with', Icons.people_alt_rounded),
  close('close', 'Close friends', 'Only people on your private close list', Icons.favorite_rounded),
  selected('selected', 'Selected people', 'Pick exactly who sees it', Icons.person_add_alt_1_rounded),
  onlyMe('onlyMe', 'Only me', 'A private memory just for you', Icons.lock_rounded);

  const StoryAudience(this.id, this.label, this.description, this.icon);

  final String id;
  final String label;
  final String description;
  final IconData icon;

  static StoryAudience fromId(String? id) {
    return StoryAudience.values.firstWhere(
      (audience) => audience.id == id,
      orElse: () => StoryAudience.public,
    );
  }
}
