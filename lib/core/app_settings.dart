import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-level choices that survive restarts and are shared by every account on this device.
class AppSettings {
  AppSettings._(this._prefs, {String? languageCode})
      : locale = ValueNotifier(_toLocale(languageCode)),
        notifyInvites = ValueNotifier(_prefs?.getBool(_invitesKey) ?? true),
        notifyFriendRequests =
            ValueNotifier(_prefs?.getBool(_friendRequestsKey) ?? true);

  static const _languageKey = 'languageCode';
  static const _invitesKey = 'notifyInvites';
  static const _friendRequestsKey = 'notifyFriendRequests';
  static const supportedLanguageCodes = ['de', 'en'];

  static AppSettings instance = AppSettings._(null);

  final SharedPreferences? _prefs;

  /// Null follows the device language.
  final ValueNotifier<Locale?> locale;
  final ValueNotifier<bool> notifyInvites;
  final ValueNotifier<bool> notifyFriendRequests;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    instance = AppSettings._(prefs, languageCode: prefs.getString(_languageKey));
  }

  /// A fresh in-memory instance for tests.
  static void resetForTest() => instance = AppSettings._(null);

  static Locale? _toLocale(String? code) =>
      supportedLanguageCodes.contains(code) ? Locale(code!) : null;

  Future<void> setLanguage(String? code) async {
    locale.value = _toLocale(code);
    if (code == null || !supportedLanguageCodes.contains(code)) {
      await _prefs?.remove(_languageKey);
    } else {
      await _prefs?.setString(_languageKey, code);
    }
  }

  Future<void> setNotifyInvites(bool value) async {
    notifyInvites.value = value;
    await _prefs?.setBool(_invitesKey, value);
  }

  Future<void> setNotifyFriendRequests(bool value) async {
    notifyFriendRequests.value = value;
    await _prefs?.setBool(_friendRequestsKey, value);
  }
}
