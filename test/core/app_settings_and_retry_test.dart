import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/app.dart';
import 'package:planner_app/core/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('provider retry policy', () {
    test('does not retry permission denied or signed-out reads', () {
      for (final code in ['permission-denied', 'unauthenticated']) {
        expect(
          planrProviderRetry(0, FirebaseException(plugin: 'cloud_firestore', code: code)),
          isNull,
        );
      }
    });

    test('keeps backing off for transient failures', () {
      final delay = planrProviderRetry(
        0,
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      expect(delay, isNotNull);
      expect(planrProviderRetry(10, Exception('network')), isNull);
    });
  });

  group('AppSettings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('follows the system language until one is chosen', () async {
      await AppSettings.load();
      expect(AppSettings.instance.locale.value, isNull);
    });

    test('a chosen language survives a restart', () async {
      await AppSettings.load();
      await AppSettings.instance.setLanguage('de');
      expect(AppSettings.instance.locale.value?.languageCode, 'de');

      await AppSettings.load();
      expect(AppSettings.instance.locale.value?.languageCode, 'de');
    });

    test('choosing System clears the stored language', () async {
      await AppSettings.load();
      await AppSettings.instance.setLanguage('en');
      await AppSettings.instance.setLanguage(null);

      await AppSettings.load();
      expect(AppSettings.instance.locale.value, isNull);
    });

    test('an unsupported stored language falls back to the system language', () async {
      SharedPreferences.setMockInitialValues({'languageCode': 'xx'});
      await AppSettings.load();
      expect(AppSettings.instance.locale.value, isNull);
    });

    test('notification choices survive a restart', () async {
      await AppSettings.load();
      await AppSettings.instance.setNotifyInvites(false);
      await AppSettings.instance.setNotifyFriendRequests(false);

      await AppSettings.load();
      expect(AppSettings.instance.notifyInvites.value, isFalse);
      expect(AppSettings.instance.notifyFriendRequests.value, isFalse);
    });
  });
}
