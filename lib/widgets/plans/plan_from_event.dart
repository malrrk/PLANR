import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../screens/invite_to_event_screen.dart';

/// Turns a public event (saved, in a story, in Discover) into a private plan with chat,
/// then lets the user invite friends right away.
Future<void> startPlanFromEvent(
  BuildContext context,
  WidgetRef ref,
  Event publicEvent,
) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  HapticFeedback.mediumImpact();

  final result = await ref
      .read(eventServiceProvider)
      .createLinkedGroupFromPublicEventAndReturn(publicEvent: publicEvent);

  final group = result.group;
  if (group == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(result.error ?? 'Could not start a plan.')),
    );
    return;
  }

  navigator.push(
    MaterialPageRoute(
      builder: (_) => InviteToEventScreen(
        event: group,
        openEventDetailOnFinish: true,
      ),
    ),
  );
}
