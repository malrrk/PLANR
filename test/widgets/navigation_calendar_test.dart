import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/l10n/gen/app_localizations.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/models/story.dart';
import 'package:planner_app/providers/auth_provider.dart';
import 'package:planner_app/providers/event_provider.dart';
import 'package:planner_app/providers/friends_provider.dart';
import 'package:planner_app/providers/home_feed_provider.dart';
import 'package:planner_app/providers/public_page_provider.dart';
import 'package:planner_app/providers/saved_events_provider.dart';
import 'package:planner_app/providers/story_provider.dart';
import 'package:planner_app/providers/user_profile_provider.dart';
import 'package:planner_app/screens/main_shell.dart';
import 'package:planner_app/screens/auth_gate.dart';
import 'package:planner_app/screens/auth_screen.dart';
import 'package:planner_app/screens/plans_screen.dart';

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

class _StoryService extends Fake implements StoryService {
  @override
  List<StoryGroup> groupStoriesByOwnerAndDay(List<Story> stories) => [];
}

MaterialApp _app(Widget child) => MaterialApp(
  theme: ThemeData(splashFactory: InkRipple.splashFactory),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  testWidgets('a failed sign-in check can be retried', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(ProviderScope(
      retry: (count, error) => null,
      overrides: [
        authStateProvider.overrideWith((ref) {
          attempts++;
          return attempts == 1
              ? Stream<User?>.error(StateError('offline'))
              : Stream<User?>.value(null);
        }),
      ],
      child: _app(const AuthGate()),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('calendar shows loading instead of an empty day', (tester) async {
    final controller = StreamController<List<Event>>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [myEventsProvider.overrideWith((ref) => controller.stream)],
        child: _app(const PlansScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Nothing planned. Fancy something?'), findsNothing);
  });

  testWidgets('calendar shows an error instead of an empty day', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          myEventsProvider.overrideWith(
            (ref) => Stream<List<Event>>.error(StateError('offline')),
          ),
        ],
        child: _app(const PlansScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load your plans.'), findsOneWidget);
    expect(find.text('Nothing planned. Fancy something?'), findsNothing);
  });

  testWidgets('calendar lets users see more than twelve past plans', (
    tester,
  ) async {
    final events = List.generate(
      13,
      (index) => Event.fromMap({
        'creatorUid': 'owner',
        'eventKind': 'private',
        'visibility': 'private',
        'title': 'Past plan $index',
        'date': DateTime.now().subtract(Duration(days: index + 1)),
      }, '$index'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myEventsProvider.overrideWith((ref) => Stream.value(events)),
          eventByIdProvider.overrideWith((ref, eventId) => Stream.value(null)),
        ],
        child: _app(const PlansScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.textContaining('Past plans ('),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Past plans (13)'), findsOneWidget);
    await tester.tap(find.text('Past plans (13)'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Past plan 12'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Past plan 12'), findsOneWidget);
  });

  testWidgets('discover search survives switching between tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(_Auth()),
          myEventsProvider.overrideWith((ref) => Stream.value([])),
          eventsProvider.overrideWith((ref) => Stream.value([])),
          publicPagesProvider.overrideWith((ref) => Stream.value([])),
          savedEventsProvider.overrideWith((ref) => Stream.value([])),
          friendsStoriesProvider.overrideWith((ref) => Stream.value([])),
          storyServiceProvider.overrideWithValue(_StoryService()),
          pendingEventInvitesProvider.overrideWith(
            (ref) => const AsyncData([]),
          ),
          incomingFriendRequestsProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          aroundYourPeopleProvider.overrideWith((ref) async => []),
        ],
        child: _app(const MainShell()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Discover'));
    await tester.pump();
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump();
    await tester.tap(find.text('Chats'));
    await tester.pump();
    await tester.tap(find.text('Discover'));
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'coffee',
    );
  });
}
