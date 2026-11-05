import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/providers/auth_provider.dart';
import 'package:planner_app/providers/friends_provider.dart';
import 'package:planner_app/screens/auth_screen.dart';
import 'package:planner_app/screens/friend_requests_screen.dart';

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