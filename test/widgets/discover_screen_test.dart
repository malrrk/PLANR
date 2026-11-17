import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/models/public_page.dart';
import 'package:planner_app/providers/event_provider.dart';
import 'package:planner_app/providers/friends_provider.dart';
import 'package:planner_app/providers/public_page_provider.dart';
import 'package:planner_app/providers/saved_events_provider.dart';
import 'package:planner_app/screens/discover_screen.dart';

class _SavedEventsService extends Fake implements SavedEventsService {}

Event _event(int index) {
  return Event.fromMap({
    'creatorUid': 'owner',
    'eventKind': 'public',
    'visibility': 'public',
    'title': 'Event $index',
    'description': 'A public event',
    'address': 'Nuremberg',
    'date': DateTime.now().add(Duration(days: index + 3)),
    'tags': index == 0 ? ['techno'] : ['food'],
    'attendeeCount': index,
  }, '$index');
}

Future<void> _pumpDiscover(
  WidgetTester tester, {
  List<Event>? events,
  List<PublicPage>? pages,
}) async {
  final availablePages =
      pages ??
      [
        PublicPage.fromMap({
          'name': 'Music Club',
          'handle': 'music',
          'category': 'club',
          'tags': ['techno'],
        }, 'page'),
      ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eventsProvider.overrideWith(
          (ref) => Stream.value(events ?? List.generate(6, _event)),
        ),
        publicPagesProvider.overrideWith((ref) => Stream.value(availablePages)),
        myFriendsProvider.overrideWith((ref) => Stream.value([])),
        eventAttendeesProvider.overrideWith((ref, eventId) => Stream.value([])),
        isEventSavedProvider.overrideWith(
          (ref, eventId) => Stream.value(false),
        ),
        savedEventsServiceProvider.overrideWithValue(_SavedEventsService()),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: InkRipple.splashFactory),
        home: const DiscoverScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Finder _feedHeading(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text && widget.data == text && widget.style?.fontSize == 26,
);

void main() {
  testWidgets('top pages precede the full photo-led event feed', (
    tester,
  ) async {
    await _pumpDiscover(tester);
    final scrollable = find.byType(Scrollable).first;

    expect(find.text('Top Pages'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Happening Now'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('6 upcoming events'), findsOneWidget);
    expect(find.text('Event 0'), findsOneWidget);
    expect(find.bySemanticsLabel('Save event'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Event 4'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Event 4'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search and tag filters focus results and can be cleared', (
    tester,
  ) async {
    await _pumpDiscover(tester);
    expect(find.text('Today'), findsNothing);
    await tester.tap(find.byTooltip('Expand filters'));
    await tester.pump();
    expect(find.text('Today'), findsOneWidget);
    await tester.tap(find.text('Techno').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byTooltip('Collapse filters'));
    await tester.pump();
    expect(find.text('Today'), findsNothing);
    await tester.tap(find.byTooltip('Expand filters'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.text('Techno').first).style?.color,
      Colors.white,
    );
    await tester.tap(find.byTooltip('Collapse filters'));
    await tester.pump();
    expect(find.text('Top Pages'), findsOneWidget);
    expect(find.text('Music Club'), findsOneWidget);
    await tester.scrollUntilVisible(
      _feedHeading('Techno'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Event 0'), findsOneWidget);
    expect(_feedHeading('Techno'), findsOneWidget);
    expect(find.text('1 upcoming event'), findsOneWidget);
    expect(find.text('Event 1'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Hot Events'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Hot Events'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(TextField),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'music');
    await tester.pump();
    expect(find.text('Music Club'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsOneWidget);
    await tester.scrollUntilVisible(
      _feedHeading('Techno · Search: music'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('0 upcoming events'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byTooltip('Clear search'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('Top Pages'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date filters can be reset on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpDiscover(tester);

    await tester.tap(find.byTooltip('Expand filters'));
    await tester.pump();
    await tester.tap(find.text('Today'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('No matching events.'), findsOneWidget);
    expect(_feedHeading('Today'), findsOneWidget);
    expect(find.text('0 upcoming events'), findsOneWidget);
    await tester.tap(find.text('Techno').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_feedHeading('Today · Techno'), findsOneWidget);
    await tester.ensureVisible(find.text('Reset filters'));
    await tester.tap(find.text('Reset filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.scrollUntilVisible(
      find.text('Event 0'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Event 0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date filters keep only pages hosting events on that date', (
    tester,
  ) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 12);
    final pages = [
      PublicPage.fromMap({'name': 'Music Club', 'category': 'club'}, 'music'),
      PublicPage.fromMap({'name': 'Other Club', 'category': 'club'}, 'other'),
    ];
    final events = [
      Event.fromMap({
        'creatorUid': 'owner',
        'eventKind': 'public',
        'visibility': 'public',
        'organizerType': 'publicPage',
        'organizerId': 'music',
        'title': 'Tomorrow event',
        'date': tomorrow,
      }, 'tomorrow'),
      Event.fromMap({
        'creatorUid': 'owner',
        'eventKind': 'public',
        'visibility': 'public',
        'organizerType': 'publicPage',
        'organizerId': 'other',
        'title': 'Later event',
        'date': tomorrow.add(const Duration(days: 3)),
      }, 'later'),
    ];
    await _pumpDiscover(tester, events: events, pages: pages);
    await tester.tap(find.byTooltip('Expand filters'));
    await tester.pump();
    await tester.tap(find.text('Tomorrow'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Top Pages'), findsOneWidget);
    expect(find.text('Music Club'), findsOneWidget);
    expect(find.text('Other Club'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Tomorrow event'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tomorrow event'), findsOneWidget);
    expect(find.text('Later event'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
