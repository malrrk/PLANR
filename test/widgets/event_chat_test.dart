import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/providers/event_provider.dart';
import 'package:planner_app/providers/firebase_providers.dart';
import 'package:planner_app/screens/event_chat_screen.dart';

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

class _EventService extends Fake implements EventService {
  @override
  Future<String?> markEventChatReadAt({required String eventId, required DateTime lastMessageAt}) async => null;
}

void main() {
  testWidgets('chat can load messages older than the first page', (tester) async {
    final firestore = FakeFirebaseFirestore();
    for (var index = 0; index < 55; index++) {
      await firestore.doc('events/event/messages/$index').set({
        'senderUid': 'user',
        'senderDisplayName': 'User',
        'text': 'Message $index',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1).add(Duration(minutes: index))),
      });
    }
    final event = Event.fromMap({
      'creatorUid': 'owner', 'title': 'Coffee', 'eventKind': 'private',
      'visibility': 'private', 'chatEnabled': true,
      'date': DateTime.now().add(const Duration(days: 1)),
    }, 'event');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(_Auth()),
          firestoreProvider.overrideWithValue(firestore),
          eventServiceProvider.overrideWithValue(_EventService()),
        ],
        child: MaterialApp(home: EventChatScreen(event: event)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pump();
    expect(find.byType(ListView), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Load older messages'), 500,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Load older messages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load older messages'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Message 0'), 500,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Message 0'), findsOneWidget);
  });

  testWidgets('write first message focuses the chat composer', (tester) async {
    final event = Event.fromMap({
      'creatorUid': 'owner',
      'title': 'Coffee',
      'eventKind': 'private',
      'visibility': 'private',
      'chatEnabled': true,
      'date': DateTime.now().add(const Duration(days: 1)),
    }, 'event');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventMessagesProvider.overrideWith(
            (ref, eventId) => Stream.value([]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: EventChatScreen(event: event),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Write first message'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });
}
