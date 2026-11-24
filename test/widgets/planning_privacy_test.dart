import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/models/story_audience.dart';
import 'package:planner_app/providers/event_provider.dart';
import 'package:planner_app/providers/relationships_provider.dart';
import 'package:planner_app/screens/legal_screen.dart';
import 'package:planner_app/widgets/plans/plan_from_event.dart';
import 'package:planner_app/widgets/story/story_options_sheets.dart';

class _EventService extends Fake implements EventService {
  int calls = 0;

  @override
  Future<LinkedGroupCreationResult> createLinkedGroupFromPublicEventAndReturn({
    required Event publicEvent,
  }) async {
    calls++;
    return const LinkedGroupCreationResult(group: null, error: 'Test failure');
  }
}

void main() {
  testWidgets('story audience explains recipient visibility accurately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closeFriendUidsProvider.overrideWith(
            (ref) => Stream.value(<String>{}),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showStoryAudienceSheet(
                  context,
                  initial: const StoryAudienceChoice(StoryAudience.friends, {}),
                ),
                child: const Text('Choose audience'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Choose audience'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Only you know who is on your lists. Nobody gets a notification.',
      ),
      findsNothing,
    );
    expect(
      find.textContaining(
        'People who can view this story may be able to see who else',
      ),
      findsOneWidget,
    );
  });

  testWidgets('terms explain story audiences and the account deletion path', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: LegalScreen()));

    expect(
      find.textContaining('Stories are shown to your friends in the app.'),
      findsNothing,
    );
    expect(
      find.textContaining('Profile > Settings > Delete account'),
      findsOneWidget,
    );
  });

  testWidgets(
    'starting a public-event plan asks before marking the user going',
    (tester) async {
      final service = _EventService();
      final event = Event.fromMap({
        'creatorUid': 'owner',
        'eventKind': 'public',
        'visibility': 'public',
        'title': 'Concert',
        'date': DateTime.now().add(const Duration(days: 1)),
      }, 'event');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [eventServiceProvider.overrideWithValue(service)],
          child: MaterialApp(
            theme: ThemeData(splashFactory: InkRipple.splashFactory),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => startPlanFromEvent(context, ref, event),
                  child: const Text('Make a plan'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Make a plan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('marked as going'), findsOneWidget);
      expect(service.calls, 0);
    },
  );

  testWidgets('public-event attendance is changed only after confirmation', (
    tester,
  ) async {
    final service = _EventService();
    final event = Event.fromMap({
      'creatorUid': 'owner',
      'eventKind': 'public',
      'visibility': 'public',
      'title': 'Concert',
      'date': DateTime.now().add(const Duration(days: 1)),
    }, 'event');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [eventServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => startPlanFromEvent(context, ref, event),
                child: const Text('Make a plan'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Make a plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.calls, 0);

    await tester.tap(find.text('Make a plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(service.calls, 1);
  });

  testWidgets('story audience choices remain usable on a short screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closeFriendUidsProvider.overrideWith(
            (ref) => Stream.value(<String>{}),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showStoryAudienceSheet(
                  context,
                  initial: const StoryAudienceChoice(StoryAudience.friends, {}),
                ),
                child: const Text('Choose audience'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Choose audience'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
