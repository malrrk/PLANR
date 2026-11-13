import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/core/app_settings.dart';
import 'package:planner_app/l10n/gen/app_localizations.dart';
import 'package:planner_app/providers/auth_provider.dart';
import 'package:planner_app/providers/firebase_providers.dart';
import 'package:planner_app/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _User extends Fake implements User {
  @override
  String? get email => 'alex@example.com';

  @override
  bool get emailVerified => false;
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _User();
}

class _AuthService extends Fake implements AuthService {
  int logouts = 0;
  String? resetEmail;

  @override
  Future<void> logout() async => logouts++;

  @override
  Future<String?> resetPassword({required String email}) async {
    resetEmail = email;
    return null;
  }
}

Future<void> pumpSettings(WidgetTester tester, AuthService service) async {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(_Auth()),
        authProvider.overrideWithValue(service),
      ],
      child: ValueListenableBuilder<Locale?>(
        valueListenable: AppSettings.instance.locale,
        builder: (context, locale, _) => MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SettingsScreen(versionLoader: () async => '1.2.3 (45)'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.load();
  });

  testWidgets('shows the account, privacy, help sections and the app version',
      (tester) async {
    await pumpSettings(tester, _AuthService());

    expect(find.text('alex@example.com'), findsOneWidget);
    expect(find.text('Not verified'), findsOneWidget);
    expect(find.text('Blocked users'), findsOneWidget);
    expect(find.text('Terms & Privacy'), findsOneWidget);
    expect(find.text('1.2.3 (45)'), findsOneWidget);
    // No support address is configured yet, so no dead contact link is offered.
    expect(find.text('Support and problem reports are not available yet.'), findsOneWidget);
  });

  for (final confirm in [false, true]) {
    testWidgets('logout ${confirm ? 'confirmed signs out' : 'cancelled keeps the session'}',
        (tester) async {
      final service = _AuthService();
      await pumpSettings(tester, service);

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      expect(service.logouts, 0);

      await tester.tap(find.widgetWithText(confirm ? FilledButton : TextButton, confirm ? 'Log out' : 'Cancel'));
      await tester.pumpAndSettle();

      expect(service.logouts, confirm ? 1 : 0);
      expect(find.text('Are you sure you want to log out?'), findsNothing);
    });
  }

  testWidgets('dismissing the logout dialog keeps the session', (tester) async {
    final service = _AuthService();
    await pumpSettings(tester, service);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(service.logouts, 0);
  });

  testWidgets('password reset is sent to the account email', (tester) async {
    final service = _AuthService();
    await pumpSettings(tester, service);

    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle();

    expect(service.resetEmail, 'alex@example.com');
    expect(
      find.text('If an account exists for this email, a reset link has been sent.'),
      findsOneWidget,
    );
  });

  testWidgets('choosing Deutsch switches the visible strings and is stored',
      (tester) async {
    await pumpSettings(tester, _AuthService());
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Abmelden'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('languageCode'), 'de');

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getString('languageCode'), isNull);
  });

  testWidgets('notification switches are stored', (tester) async {
    await pumpSettings(tester, _AuthService());

    await tester.tap(find.text('Event invitations'));
    await tester.pumpAndSettle();

    expect(AppSettings.instance.notifyInvites.value, isFalse);
    expect(AppSettings.instance.notifyFriendRequests.value, isTrue);
  });
}
