import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/core/widgets/planr_avatar.dart';
import 'package:planner_app/models/user_profile.dart';
import 'package:planner_app/widgets/profile/profile_header.dart';

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
  testWidgets('failed profile cover renders the absent-cover placeholder',
      (tester) async {
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

  testWidgets('failed avatar shows initials without an unhandled image error',
      (tester) async {
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