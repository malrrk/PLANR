import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which stories this device has already watched, to colour the story rings.
class StoryViews {
  StoryViews._(this._prefs, List<String> viewed)
      : _ids = [...viewed],
        viewedIds = ValueNotifier(Set.unmodifiable(viewed));

  static const _key = 'viewedStoryIds';
  static const _maxRemembered = 400;

  static StoryViews instance = StoryViews._(null, const []);

  final SharedPreferences? _prefs;
  final List<String> _ids;

  final ValueNotifier<Set<String>> viewedIds;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    instance = StoryViews._(prefs, prefs.getStringList(_key) ?? const []);
  }

  static void resetForTest() => instance = StoryViews._(null, const []);

  bool isViewed(String storyId) => viewedIds.value.contains(storyId);

  Future<void> markViewed(String storyId) async {
    if (_ids.contains(storyId)) return;

    _ids.add(storyId);
    if (_ids.length > _maxRemembered) {
      _ids.removeRange(0, _ids.length - _maxRemembered);
    }

    viewedIds.value = Set.unmodifiable(_ids);
    await _prefs?.setStringList(_key, _ids);
  }
}
