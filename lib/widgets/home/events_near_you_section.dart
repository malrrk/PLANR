import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/event_provider.dart';
import '../../screens/create_event_screen.dart';
import 'home_design.dart';
import 'home_empty_state_card.dart';
import 'home_error_state_card.dart';
import 'home_event_card.dart';
import 'home_loading_card.dart';

class EventsNearYouSection extends ConsumerWidget {
  const EventsNearYouSection({super.key});

  void _openCreateEvent(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateEventScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Happening Now', // changeable
          style: TextStyle(
            color: HomeDesign.ink,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Plans worth leaving the house for', // changeable
          style: TextStyle(
            color: HomeDesign.muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return HomeEmptyStateCard(
                message: 'No events yet. Create the first one.',
                actionLabel: 'Create',
                icon: Icons.celebration_rounded,
                onActionPressed: () => _openCreateEvent(context),
              );
            }

            return Column(
              children: [
                for (final event in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: HomeEventCard(event: event),
                  ),
              ],
            );
          },
          loading: () => const HomeLoadingCard(height: 230),
          error: (_, _) => const HomeErrorStateCard(
            message: 'Could not load events.',
          ),
        ),
      ],
    );
  }
}