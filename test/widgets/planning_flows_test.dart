import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/core/widgets/planr_button.dart';
import 'package:planner_app/l10n/gen/app_localizations.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/models/public_page.dart';
import 'package:planner_app/models/user_profile.dart';
import 'package:planner_app/providers/event_provider.dart';
import 'package:planner_app/providers/friends_provider.dart';
import 'package:planner_app/providers/moderation_provider.dart';
import 'package:planner_app/providers/public_page_provider.dart';
import 'package:planner_app/providers/relationships_provider.dart';
import 'package:planner_app/providers/user_profile_provider.dart';
import 'package:planner_app/screens/create_event_screen.dart';
import 'package:planner_app/screens/edit_event_screen.dart';
import 'package:planner_app/screens/invite_to_event_screen.dart';
import 'package:planner_app/screens/user_search_screen.dart';
import 'package:planner_app/widgets/plans/quick_plan_sheet.dart';

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

class _EventService extends Fake implements EventService {
  _EventService(this.firestore, {this.failInvitees = const {}});

  final FakeFirebaseFirestore firestore;
  final Set<String> failInvitees;
  final invited = <String>[];

  @override
  Future<String?> createEvent({
    required String title,
    required String description,
    required String address,
    required DateTime date,
    required String visibility,
    required bool chatEnabled,
    required bool guestsCanInvite,
    required List<String> tags,
    File? imageFile,
    String? eventKind,
    String organizerType = 'profile',
    String? organizerId,
    String? organizerDisplayName,
    String? organizerPhotoUrl,
    bool organizerVerified = false,
    PublicPage? organizerPage,
    void Function(String eventId)? onCreated,
  }) async {
    await firestore.doc('events/created').set({
      'creatorUid': 'owner',
      'title': title,
      'description': description,
      'address': address,
      'date': date,
      'visibility': visibility,
      'eventKind': eventKind,
      'chatEnabled': chatEnabled,
      'guestsCanInvite': guestsCanInvite,
      'tags': tags,
    });
    onCreated?.call('created');
    return null;
  }

  @override
  Future<String?> inviteUserToEvent({
    required Event event,
    required String invitedUid,
    required String invitedDisplayName,
    String? invitedPhotoUrl,
  }) async {
    invited.add(invitedUid);
    return failInvitees.contains(invitedUid) ? 'Invite failed' : null;
  }
}

class _PartialQuickPlanService extends Fake implements EventService {
  @override
  Future<String?> createQuickPlan({
    required String title,
    required DateTime date,
    String? place,
    List<UserProfile> invitees = const [],
    void Function()? onCreated,
  }) async {
    onCreated?.call();
    return 'Plan created, but 1 invite(s) could not be sent.';
  }
}

MaterialApp _app(Widget child) => MaterialApp(
  theme: ThemeData(splashFactory: InkRipple.splashFactory),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  testWidgets('editing an older event opens the date picker', (tester) async {
    tester.view.physicalSize = const Size(600, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final event = Event.fromMap({
      'creatorUid': 'owner',
      'eventKind': 'public',
      'visibility': 'public',
      'title': 'Past event',
      'date': DateTime.now().subtract(const Duration(days: 30)),
    }, 'event');
    await tester.pumpWidget(ProviderScope(child: _app(EditEventScreen(event: event))));
    await tester.ensureVisible(find.text('Date & Time'));
    await tester.tap(find.text('Date & Time'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invite list can search friends by name or username', (
    tester,
  ) async {
    const friends = [
      UserProfile(
        uid: 'alice',
        displayName: 'Alice Adams',
        username: 'alice',
        usernameLower: 'alice',
        email: '',
      ),
      UserProfile(
        uid: 'bob',
        displayName: 'Bob Brown',
        username: 'bbrown',
        usernameLower: 'bbrown',
        email: '',
      ),
    ];
    final event = Event.fromMap({
      'creatorUid': 'owner',
      'eventKind': 'private',
      'visibility': 'private',
      'title': 'Coffee',
      'date': DateTime.now().add(const Duration(days: 1)),
    }, 'event');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myFriendsProvider.overrideWith((ref) => Stream.value(friends)),
          friendEventInviteStatusProvider.overrideWith(
            (ref, args) => Stream.value(EventInviteFriendStatus.invite),
          ),
        ],
        child: _app(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
            child: InviteToEventScreen(event: event),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'BBROWN');
    await tester.pump();
    expect(find.text('Alice Adams'), findsNothing);
    expect(find.text('Bob Brown'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no match');
    await tester.pump();
    expect(find.text('No matching friends.'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('Alice Adams'), findsOneWidget);
    expect(find.text('Bob Brown'), findsOneWidget);
  });

  testWidgets('invite buttons fit at normal text size', (tester) async {
    const friend = UserProfile(
      uid: 'alice',
      displayName: 'Alice Adams',
      username: 'alice',
      usernameLower: 'alice',
      email: '',
    );
    final event = Event.fromMap({
      'creatorUid': 'owner',
      'eventKind': 'private',
      'visibility': 'private',
      'title': 'Coffee',
      'date': DateTime.now().add(const Duration(days: 1)),
    }, 'event');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myFriendsProvider.overrideWith((ref) => Stream.value([friend])),
          friendEventInviteStatusProvider.overrideWith(
            (ref, args) => Stream.value(EventInviteFriendStatus.invite),
          ),
        ],
        child: _app(InviteToEventScreen(event: event)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switching a full plan to public does not send private invitations',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const friend = UserProfile(
        uid: 'alice',
        displayName: 'Alice',
        username: 'alice',
        usernameLower: 'alice',
        email: '',
      );
      final firestore = FakeFirebaseFirestore();
      final service = _EventService(firestore);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            eventServiceProvider.overrideWithValue(service),
            myManagedPublicPagesProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: _app(
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateEventScreen(
                        initialTitle: 'Coffee',
                        initialPlace: 'Nuremberg',
                        startPrivate: true,
                        initialInvitees: [friend],
                      ),
                    ),
                  ),
                  child: const Text('Open form'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'Coffee together');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tags'));
      await tester.tap(find.text('Tags'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Food').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').first);
      await tester.ensureVisible(find.text('Public').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Public').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Friends can only be invited to private plans.'),
        findsOneWidget,
      );
      final createButton = find.byWidgetPredicate(
        (widget) => widget is PlanrButton && widget.label == 'Create Event',
      );
      await tester.scrollUntilVisible(
        createButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(
        (await firestore.doc('events/created').get()).data()?['eventKind'],
        'public',
      );
      expect(service.invited, isEmpty);
    },
  );

  testWidgets('empty invite list offers a route to find friends', (
    tester,
  ) async {
    final event = Event.fromMap({
      'creatorUid': 'owner',
      'eventKind': 'private',
      'visibility': 'private',
      'title': 'Coffee',
      'date': DateTime.now().add(const Duration(days: 1)),
    }, 'event');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myFriendsProvider.overrideWith((ref) => Stream.value([])),
          currentFirebaseUserProvider.overrideWith((ref) => Stream.value(null)),
          blockedUidsProvider.overrideWith((ref) => Stream.value(<String>{})),
        ],
        child: _app(InviteToEventScreen(event: event)),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Find friends'));
    await tester.pumpAndSettle();
    expect(find.byType(UserSearchScreen), findsOneWidget);
  });

  testWidgets('quick plan closes after a partial invitation failure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const friend = UserProfile(
      uid: 'alice',
      displayName: 'Alice',
      username: 'alice',
      usernameLower: 'alice',
      email: '',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventServiceProvider.overrideWithValue(_PartialQuickPlanService()),
          myFriendsProvider.overrideWith((ref) => Stream.value([friend])),
          closeFriendUidsProvider.overrideWith((ref) => Stream.value(<String>{})),
        ],
        child: _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showQuickPlanSheet(context, initialTitle: 'Coffee'),
                child: const Text('Open quick plan'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open quick plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send plan'));
    await tester.tap(find.text('Send plan'));
    await tester.pumpAndSettle();

    expect(find.byType(QuickPlanSheet), findsNothing);
    expect(find.text('Plan created, but 1 invite(s) could not be sent.'), findsOneWidget);
  });

  testWidgets('quick plan preserves selected friends through more options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const friend = UserProfile(
      uid: 'alice',
      displayName: 'Alice',
      username: 'alice',
      usernameLower: 'alice',
      email: '',
    );
    final firestore = FakeFirebaseFirestore();
    final service = _EventService(firestore);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(_Auth()),
          firestoreProvider.overrideWithValue(firestore),
          eventServiceProvider.overrideWithValue(service),
          myFriendsProvider.overrideWith((ref) => Stream.value([friend])),
          closeFriendUidsProvider.overrideWith(
            (ref) => Stream.value(<String>{}),
          ),
          myManagedPublicPagesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showQuickPlanSheet(context, initialTitle: 'Coffee'),
                child: const Text('Open quick plan'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open quick plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Inviting 1'), findsOneWidget);
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateEventScreen), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'Coffee together');
    await tester.enterText(find.byType(TextField).at(2), 'Nuremberg');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tags'));
    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Food').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food').first);
    final createButton = find.byWidgetPredicate(
      (widget) => widget is PlanrButton && widget.label == 'Create Event',
    );
    await tester.ensureVisible(createButton);
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(service.invited, ['alice']);
  });

  testWidgets(
    'a failed invite reports partial success after creating the plan',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const friends = [
        UserProfile(
          uid: 'alice',
          displayName: 'Alice',
          username: 'alice',
          usernameLower: 'alice',
          email: '',
        ),
        UserProfile(
          uid: 'bob',
          displayName: 'Bob',
          username: 'bob',
          usernameLower: 'bob',
          email: '',
        ),
      ];
      final firestore = FakeFirebaseFirestore();
      final service = _EventService(firestore, failInvitees: {'bob'});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            eventServiceProvider.overrideWithValue(service),
            myManagedPublicPagesProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: _app(
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateEventScreen(
                        initialTitle: 'Coffee',
                        initialPlace: 'Nuremberg',
                        startPrivate: true,
                        initialInvitees: friends,
                      ),
                    ),
                  ),
                  child: const Text('Open form'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'Coffee together');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tags'));
      await tester.tap(find.text('Tags'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Food').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').first);
      final createButton = find.byWidgetPredicate(
        (widget) => widget is PlanrButton && widget.label == 'Create Event',
      );
      await tester.ensureVisible(createButton);
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(service.invited, ['alice', 'bob']);
      expect(find.byType(CreateEventScreen), findsNothing);
      expect(
        find.text('Plan created, but 1 invite(s) could not be sent.'),
        findsOneWidget,
      );
    },
  );
}
