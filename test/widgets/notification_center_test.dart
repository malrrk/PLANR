import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/providers/event_provider.dart';
import 'package:planner_app/providers/friends_provider.dart';
import 'package:planner_app/screens/notification_center_screen.dart';

void main() {
  testWidgets('counts and previews pending invites only', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myEventInvitesProvider.overrideWith(
            (ref) => Stream.value([
              {'status': 'pending', 'eventTitle': 'Pending plan'},
              {'status': 'declined', 'eventTitle': 'Declined plan'},
            ]),
          ),
          incomingFriendRequestsProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
        ],
        child: const MaterialApp(home: NotificationCenterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 pending invite'), findsOneWidget);
    expect(find.text('Pending plan'), findsOneWidget);
    expect(find.text('Declined plan'), findsNothing);
  });

  testWidgets('declined invites alone do not appear as pending', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myEventInvitesProvider.overrideWith(
            (ref) => Stream.value([
              {'status': 'declined', 'eventTitle': 'Declined plan'},
            ]),
          ),
          incomingFriendRequestsProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
        ],
        child: const MaterialApp(home: NotificationCenterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pending event invites.'), findsOneWidget);
    expect(find.text('Declined plan'), findsNothing);
  });
}