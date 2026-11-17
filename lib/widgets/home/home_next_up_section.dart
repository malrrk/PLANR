import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/planr_design.dart';
import '../../models/event_schedule.dart';
import '../../providers/event_provider.dart';
import '../../screens/create_event_screen.dart';
import '../../screens/event_chat_screen.dart';
import '../../screens/event_detail_screen.dart';
import '../../screens/plans_screen.dart';
import 'home_error_state_card.dart';
import 'home_header.dart';
import 'home_loading_card.dart';
import 'my_event_mini_card.dart';

class HomeNextUpSection extends ConsumerWidget {
  const HomeNextUpSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(myEventsProvider);
    final upcoming = eventsAsync.whenData(
      (events) => upcomingEvents(events, now: DateTime.now()),
    );

    void openCalendar() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlansScreen()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My plans',
                    style: TextStyle(
                      color: PlanrDesign.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    upcoming.when(
                      data: (events) => events.length == 1
                          ? '1 upcoming plan'
                          : '${events.length} upcoming plans',
                      loading: () => 'Loading your plans',
                      error: (_, _) => 'Could not load your plans',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PlanrDesign.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            HomeRoundButton(
              icon: Icons.calendar_month_rounded,
              tooltip: 'Calendar',
              onTap: openCalendar,
            ),
          ],
        ),
        const SizedBox(height: 13),
        upcoming.when(
          data: (events) {
            final visible = events.take(3).toList();
            final remaining = events.length - visible.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < visible.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MyEventMiniCard(
                      event: visible[index],
                      featured: index == 0,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EventDetailScreen(eventId: visible[index].id),
                        ),
                      ),
                      onChatTap: visible[index].chatEnabled
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventChatScreen(event: visible[index]),
                              ),
                            )
                          : null,
                    ),
                  ),
                if (events.length < 3)
                  _CreateEventBanner(
                    isEmpty: events.isEmpty,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateEventScreen(),
                      ),
                    ),
                  ),
                if (remaining > 0)
                  TextButton(
                    onPressed: openCalendar,
                    child: Text('View $remaining more in your calendar'),
                  ),
              ],
            );
          },
          loading: () => const HomeLoadingCard(height: 120),
          error: (_, _) =>
              const HomeErrorStateCard(message: 'Could not load your plans.'),
        ),
      ],
    );
  }
}

class _CreateEventBanner extends StatelessWidget {
  const _CreateEventBanner({required this.isEmpty, required this.onTap});

  final bool isEmpty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: PlanrDesign.cardDecoration(radius: 21),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: PlanrDesign.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add_rounded, color: PlanrDesign.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create an event',
                      style: TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmpty
                          ? 'Start your first plan.'
                          : 'Make room for another plan.',
                      style: const TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: PlanrDesign.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
