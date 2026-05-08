import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/event_provider.dart';
import '../../screens/event_detail_screen.dart';
import '../../screens/event_invites_screen.dart';
import '../../core/theme/planr_design.dart';
import 'home_empty_state_card.dart';
import 'home_error_state_card.dart';
import 'home_loading_card.dart';
import 'my_event_mini_card.dart';

class MyEventsSection extends ConsumerStatefulWidget {
  const MyEventsSection({super.key});

  @override
  ConsumerState<MyEventsSection> createState() => _MyEventsSectionState();
}

class _MyEventsSectionState extends ConsumerState<MyEventsSection> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _openInvites(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EventInvitesScreen(),
      ),
    );
  }

  void _openEventDetails(BuildContext context, String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: eventId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myEventsAsync = ref.watch(myEventsProvider);
    final invitesAsync = ref.watch(myEventInvitesProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PlanrDesign.card.withOpacity(0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.black.withOpacity(0.12), // changeable
          width: 2.3, // changeable
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleExpanded,
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: PlanrDesign.accentSoft,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: PlanrDesign.accent,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: myEventsAsync.when(
                    data: (events) {
                      final eventText = events.length == 1
                          ? '1 upcoming event'
                          : '${events.length} upcoming events';

                      return _MyEventsHeaderText(
                        subtitle: eventText,
                        invitesAsync: invitesAsync,
                        onInvitesTap: () => _openInvites(context),
                      );
                    },
                    loading: () => _MyEventsHeaderText(
                      subtitle: 'Loading your plans',
                      invitesAsync: invitesAsync,
                      onInvitesTap: () => _openInvites(context),
                    ),
                    error: (_, _) => _MyEventsHeaderText(
                      subtitle: 'Could not load your plans',
                      invitesAsync: invitesAsync,
                      onInvitesTap: () => _openInvites(context),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF4B403A),
                    size: 30,
                  ),
                ),
              ],
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 240),
            sizeCurve: Curves.easeInOutCubic,
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: myEventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return const HomeEmptyStateCard(
                      message: 'No plans yet. Join an event or accept an invite.',
                      icon: Icons.event_available_rounded,
                    );
                  }

                  return SizedBox(
                    height: 252,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final event = events[index];

                        return MyEventMiniCard(
                          event: event,
                          onTap: () => _openEventDetails(context, event.id),
                        );
                      },
                    ),
                  );
                },
                loading: () => const HomeLoadingCard(height: 150),
                error: (_, _) => const HomeErrorStateCard(
                  message: 'Could not load your events.',
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MyEventsHeaderText extends StatelessWidget {
  const _MyEventsHeaderText({
    required this.subtitle,
    required this.invitesAsync,
    required this.onInvitesTap,
  });

  final String subtitle;
  final AsyncValue<List<Map<String, dynamic>>> invitesAsync;
  final VoidCallback onInvitesTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Events',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: PlanrDesign.ink,
            letterSpacing: -0.6,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            invitesAsync.maybeWhen(
              data: (invites) {
                if (invites.isEmpty) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: onInvitesTap,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PlanrDesign.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${invites.length} invites',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }
}