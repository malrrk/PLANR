import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/core/widgets/planr_avatar.dart';
import 'package:planner_app/l10n/gen/app_localizations.dart';
import 'package:planner_app/models/user_profile.dart';
import 'package:planner_app/providers/friends_provider.dart';
import 'package:planner_app/providers/moderation_provider.dart';
import 'package:planner_app/providers/public_page_provider.dart';
import 'package:planner_app/providers/relationships_provider.dart';
import 'package:planner_app/providers/user_profile_provider.dart';
import 'package:planner_app/screens/friends_screen.dart';
import 'package:planner_app/screens/managed_public_pages_screen.dart';
import 'package:planner_app/screens/profile_screen.dart';
import 'package:planner_app/screens/user_search_screen.dart';
import 'package:planner_app/widgets/profile/profile_action_section.dart';
import 'package:planner_app/widgets/profile/profile_header.dart';
import 'package:planner_app/widgets/profile/profile_pinned_moments.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'owner';

  @override
  bool get emailVerified => true;
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _User();
}

const _profile = UserProfile(
  uid: 'owner',
  displayName: 'Alex Example',
  username: 'alex',
  usernameLower: 'alex',
  email: '',
);

Widget _app(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(splashFactory: InkRipple.splashFactory),
    home: child,
  );
}

Widget _profileScope(Widget child) {
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(_Auth()),
      currentFirebaseUserProvider.overrideWith((ref) => Stream.value(_User())),
      currentUserProfileProvider.overrideWith((ref) => Stream.value(_profile)),
      friendsCountProvider.overrideWith((ref, uid) => Stream.value(0)),
      myFriendsProvider.overrideWith((ref) => Stream.value([])),
      incomingFriendRequestsProvider.overrideWith(
        (ref) => Stream.value([{}, {}]),
      ),
      closeFriendUidsProvider.overrideWith((ref) => Stream.value(<String>{})),
      blockedUidsProvider.overrideWith((ref) => Stream.value(<String>{})),
      myManagedPublicPagesProvider.overrideWith((ref) => Stream.value([])),
    ],
    child: _app(child),
  );
}

Future<void> waitForImageFailure(String url) async {
  final completion = Completer<void>();
  final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
  final listener = ImageStreamListener(
    (image, synchronousCall) => completion.complete(),
    onError: (Object error, StackTrace? stackTrace) => completion.complete(),
  );
  stream.addListener(listener);
  try {
    await completion.future;
  } finally {
    stream.removeListener(listener);
  }
}

void main() {
  testWidgets('profile keeps one edit control and friend search', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_profileScope(const ProfileScreen()));
    await tester.pump();
    await tester.pump();

    expect(find.byTooltip('Edit profile'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Find friends'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2'), findsOneWidget);
    await tester.ensureVisible(find.text('Find friends'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find friends'));
    await tester.pumpAndSettle();
    expect(find.byType(UserSearchScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty friends list opens the find friends flow', (tester) async {
    await tester.pumpWidget(_profileScope(const FriendsScreen()));
    await tester.pump();
    await tester.pump();

    expect(find.text('No friends yet'), findsOneWidget);
    await tester.tap(find.text('Find friends'));
    await tester.pumpAndSettle();
    expect(find.byType(UserSearchScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile keeps moments and page management accessible', (
    tester,
  ) async {
    await tester.pumpWidget(_profileScope(const ProfileScreen()));
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Pinned moments'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Add'), findsNWidgets(3));
    await tester.scrollUntilVisible(
      find.text('Public Pages'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.getTopLeft(find.text('Public Pages')).dy,
      greaterThan(tester.getTopLeft(find.byType(ProfileActionSection)).dy),
    );
    expect(find.text('Edit profile'), findsNothing);
    await tester.tap(find.text('Public Pages'));
    await tester.pumpAndSettle();
    expect(find.byType(ManagedPublicPagesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('friend shortcuts fit a narrow German profile', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var requestsOpened = false;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: ProfileActionSection(
            onFriends: () {},
            onFindFriends: () {},
            onFriendRequests: () => requestsOpened = true,
            requestCount: 12,
          ),
        ),
        locale: const Locale('de'),
      ),
    );

    expect(find.text('Freunde finden'), findsOneWidget);
    expect(find.text('Freundschaftsanfragen'), findsOneWidget);
    expect(find.text('9+'), findsOneWidget);
    await tester.tap(find.text('Freundschaftsanfragen'));
    expect(requestsOpened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty pinned moments show three add tiles', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: ProfilePinnedMoments(
            profile: _profile,
            onManage: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.text('Add'), findsNWidgets(3));
    await tester.tap(find.text('Add').first);
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed profile cover renders the absent-cover placeholder', (
    tester,
  ) async {
    const url = 'https://example.invalid/failed-cover.jpg';
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileHeader(
              profile: UserProfile(
                uid: 'owner',
                displayName: 'Alex Example',
                username: 'alex',
                usernameLower: 'alex',
                email: '',
                backgroundImageUrl: url,
              ),
            ),
          ),
        ),
      );
      await waitForImageFailure(url);
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.waving_hand_rounded), findsOneWidget);
    expect(find.text('Alex Example'), findsOneWidget);
  });

  testWidgets('failed avatar shows initials without an unhandled image error', (
    tester,
  ) async {
    const url = 'https://example.invalid/failed-avatar.jpg';
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlanrAvatar(imageUrl: url, name: 'Alex Example'),
          ),
        ),
      );
      await waitForImageFailure(url);
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('AE'), findsOneWidget);
  });
}
