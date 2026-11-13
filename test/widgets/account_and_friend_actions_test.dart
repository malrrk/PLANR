import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/providers/account_provider.dart';
import 'package:planner_app/providers/auth_provider.dart';
import 'package:planner_app/providers/friends_provider.dart';
import 'package:planner_app/screens/auth_screen.dart';
import 'package:planner_app/screens/friend_requests_screen.dart';
import 'package:planner_app/widgets/account/delete_account_dialog.dart';

class RecordingAccountService extends Fake implements AccountService {
  int deletions = 0;
  bool requirePassword = false;
  String? lastPassword;

  @override
  Future<String?> deleteAccount({String? password}) async {
    deletions++;
    if (requirePassword && password == null) return AccountService.reauthRequired;
    lastPassword = password;
    return null;
  }
}

class RecordingAuthService extends Fake implements AuthService {
  String? submittedEmail;
  String? error;

  @override
  Future<String?> resetPassword({required String email}) async {
    submittedEmail = email;
    return error;
  }
}

class RecordingFriendsService extends Fake implements FriendsService {
  String? declinedRequest;
  String? error;

  @override
  Future<String?> declineFriendRequest({required String requestId}) async {
    declinedRequest = requestId;
    return error;
  }
}

void main() {
  for (final secondStep in [false, true]) {
    testWidgets('cancel deletion at ${secondStep ? 'second' : 'first'} step',
        (tester) async {
      final service = RecordingAccountService();
      await tester.pumpWidget(ProviderScope(
        overrides: [accountServiceProvider.overrideWithValue(service)],
        child: MaterialApp(home: Consumer(builder: (context, ref, child) {
          return Scaffold(body: TextButton(
            onPressed: () => showDeleteAccountDialog(context, ref),
            child: const Text('Open deletion'),
          ));
        })),
      ));
      await tester.tap(find.text('Open deletion'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      if (secondStep) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Are you sure?'), findsOneWidget);
      }
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.deletions, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });
  }

  testWidgets('an old sign-in asks for the password only after the final confirmation',
      (tester) async {
    final service = RecordingAccountService()..requirePassword = true;
    await tester.pumpWidget(ProviderScope(
      overrides: [accountServiceProvider.overrideWithValue(service)],
      child: MaterialApp(home: Consumer(builder: (context, ref, child) {
        return Scaffold(body: TextButton(
          onPressed: () => showDeleteAccountDialog(context, ref),
          child: const Text('Open deletion'),
        ));
      })),
    ));
    await tester.tap(find.text('Open deletion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(service.lastPassword, isNull);

    await tester.enterText(find.byType(TextField), 'secret');
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();

    expect(service.lastPassword, 'secret');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('deletion starts only after the second confirmation', (tester) async {
    final service = RecordingAccountService();
    await tester.pumpWidget(ProviderScope(
      overrides: [accountServiceProvider.overrideWithValue(service)],
      child: MaterialApp(home: Consumer(builder: (context, ref, child) {
        return Scaffold(body: TextButton(
          onPressed: () => showDeleteAccountDialog(context, ref),
          child: const Text('Open deletion'),
        ));
      })),
    ));
    await tester.tap(find.text('Open deletion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(service.deletions, 0);
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
    expect(service.deletions, 1);
  });

  testWidgets('password recovery submits email and shows a neutral result',
      (tester) async {
    final service = RecordingAuthService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWithValue(service)],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
    final forgot = find.text('Forgot password?');
    expect(forgot, findsOneWidget);
    await tester.ensureVisible(forgot);
    await tester.tap(forgot);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'alex@example.com');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(service.submittedEmail, 'alex@example.com');
    expect(
      find.text('If an account exists for this email, a reset link has been sent.'),
      findsOneWidget,
    );
  });

  testWidgets('password recovery displays service errors', (tester) async {
    final service = RecordingAuthService()
      ..error = 'Please enter a valid email address.';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWithValue(service)],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
    final forgot = find.text('Forgot password?');
    expect(forgot, findsOneWidget);
    await tester.ensureVisible(forgot);
    await tester.tap(forgot);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
  });

  for (final fail in [false, true]) {
    testWidgets('decline request ${fail ? 'reports failure' : 'confirms success'}',
        (tester) async {
      final service = RecordingFriendsService()
        ..error = fail ? 'Could not decline request.' : null;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendsServiceProvider.overrideWithValue(service),
            incomingFriendRequestsProvider.overrideWith(
              (ref) => Stream.value([
                {
                  'docId': 'request1',
                  'fromUid': 'sender',
                  'fromDisplayName': 'Alex',
                },
              ]),
            ),
          ],
          child: const MaterialApp(home: FriendRequestsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Decline request'), findsOneWidget);
      await tester.tap(find.byTooltip('Decline request'));
      await tester.pumpAndSettle();

      expect(service.declinedRequest, 'request1');
      expect(
        find.text(fail ? 'Could not decline request.' : 'Friend request declined.'),
        findsOneWidget,
      );
    });
  }
}