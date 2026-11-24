import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/models/event.dart';
import 'package:planner_app/providers/event_provider.dart';
import 'package:planner_app/screens/event_chat_screen.dart';

void main() {
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
