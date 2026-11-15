import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/plan_time.dart';
import '../../core/theme/planr_design.dart';
import '../../models/event.dart';
import '../../models/event_schedule.dart';
import '../../providers/event_provider.dart';
import '../../providers/user_profile_provider.dart';

/// A warm, changing line that tells the user what matters today.
class HomeGreeting extends ConsumerWidget {
  const HomeGreeting({super.key});

  static String subtitleFor({
    required int pendingInvites,
    required List<Event> upcoming,
    required DateTime now,
  }) {
    if (pendingInvites == 1) return '1 invitation is waiting for your answer.';
    if (pendingInvites > 1) {
      return '$pendingInvites invitations are waiting for your answer.';
    }

    if (upcoming.isEmpty) return "Nothing planned yet. Let's change that.";

    final next = upcoming.first;
    final today = isSameDay(next.date, now);
    final title = next.isLinkedGroup
        ? (next.linkedPublicEventTitle ?? next.title)
        : next.title;

    if (today) return '${planTimeLabel(next.date, now: now).split(' · ').first}: $title';

    final weekCount =
        upcoming.where((e) => e.date.difference(now).inDays < 7).length;
    if (weekCount > 1) return '$weekCount plans this week. Nice.';

    return 'Next up: $title, ${countdownLabel(next.date, now: now).toLowerCase()}.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final profile = ref.watch(currentUserProfileProvider).value;
    final events = ref.watch(myEventsProvider).value ?? const <Event>[];
    final invites = ref.watch(pendingEventInvitesProvider).value ?? const [];

    final name = firstNameOf(profile?.displayName);
    final greeting = name.isEmpty ? greetingFor(now) : '${greetingFor(now)}, $name';

    final subtitle = subtitleFor(
      pendingInvites: invites.length,
      upcoming: upcomingEvents(events, now: now),
      now: now,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            color: PlanrDesign.ink,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.9,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            subtitle,
            key: ValueKey(subtitle),
            style: const TextStyle(
              color: PlanrDesign.muted,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
