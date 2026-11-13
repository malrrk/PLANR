import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/user_profile.dart';
import 'package:planner_app/providers/moderation_provider.dart';
import 'package:planner_app/providers/user_profile_provider.dart';
import 'package:planner_app/screens/user_search_screen.dart';

class SearchService extends Fake implements UserProfileService {
  final requests = <String, Completer<List<UserProfile>>>{};

  @override
  Future<List<UserProfile>> searchUsers(String query) {
    return (requests[query] = Completer<List<UserProfile>>()).future;
  }
}

Future<void> openSearch(WidgetTester tester, SearchService service) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      userProfileServiceProvider.overrideWithValue(service),
      currentFirebaseUserProvider.overrideWith((ref) => Stream.value(null)),
      blockedUidsProvider.overrideWith((ref) => Stream.value(<String>{})),
    ],
    child: const MaterialApp(home: UserSearchScreen()),
  ));
  await tester.pump();
}

void main() {
  testWidgets('search failure is not an empty result or an endless spinner',
      (tester) async {
    final service = SearchService();
    await openSearch(tester, service);
    await tester.enterText(find.byType(TextField), 'louisa');
    await tester.pump(const Duration(milliseconds: 350));
    service.requests['louisa']!.completeError(StateError('query denied'));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Could not search users'), findsOneWidget);
    expect(find.text('No users found'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('clearing search ignores a response already in flight',
      (tester) async {
    final service = SearchService();
    await openSearch(tester, service);
    await tester.enterText(find.byType(TextField), 'louisa');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), '');
    service.requests['louisa']!.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Search by username'), findsOneWidget);
    expect(find.text('No users found'), findsNothing);
  });

  testWidgets('an older failed query cannot replace a newer empty result',
      (tester) async {
    final service = SearchService();
    await openSearch(tester, service);
    await tester.enterText(find.byType(TextField), 'louisa');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'alex');
    await tester.pump(const Duration(milliseconds: 350));
    service.requests['alex']!.complete([]);
    await tester.pumpAndSettle();
    service.requests['louisa']!.completeError(StateError('old query denied'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('No users found'), findsOneWidget);
    expect(find.text('Could not search users'), findsNothing);
  });
}