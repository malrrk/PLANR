import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../screens/event_chat_screen.dart';
import '../../screens/event_detail_screen.dart';
import '../../screens/event_invites_screen.dart';
import '../../core/theme/planr_design.dart';
import 'home_empty_state_card.dart';
import 'home_error_state_card.dart';
import 'home_loading_card.dart';
import 'my_event_mini_card.dart';

class MyEventsSection extends ConsumerWidget {
  const MyEventsSection({
    super.key,
    this.onCollapsed,
    this.onOpenMyPlanr,
  });

  // Kept so older code does not break. Not used anymore.
  final VoidCallback? onCollapsed;

  final VoidCallback? onOpenMyPlanr;

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

  void _openEventChat(BuildContext context, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventChatScreen(event: event),
      ),
    );
  }

  List<Event> _nextTwoUpcomingEvents(List<Event> events) {
    final now = DateTime.now();

    final upcomingEvents = events.where((event) {
      return event.date.isAfter(now);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return upcomingEvents.take(2).toList();
  }

  int _upcomingEventCount(List<Event> events) {
    final now = DateTime.now();

    return events.where((event) {
      return event.date.isAfter(now);
    }).length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myEventsAsync = ref.watch(myEventsProvider);
    final invitesAsync = ref.watch(myEventInvitesProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: PlanrDesign.card.withOpacity(0.68),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.black.withOpacity(0.095),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onOpenMyPlanr,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: PlanrDesign.accentSoft.withOpacity(0.84),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: PlanrDesign.accent,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: myEventsAsync.when(
                        data: (events) {
                          final count = _upcomingEventCount(events);

                          final eventText = count == 1
                              ? '1 upcoming plan'
                              : '$count upcoming plans';

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
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: PlanrDesign.softMuted,
                      size: 25,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          myEventsAsync.when(
            data: (events) {
              final visibleEvents = _nextTwoUpcomingEvents(events);

              if (visibleEvents.isEmpty) {
                return const HomeEmptyStateCard(
                  message: 'No plans yet. Join an event or accept an invite.',
                  icon: Icons.event_available_rounded,
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < visibleEvents.length; i++) ...[
                    MyEventMiniCard(
                      event: visibleEvents[i],
                      onTap: () => _openEventDetails(
                        context,
                        visibleEvents[i].id,
                      ),
                      onChatTap: visibleEvents[i].chatEnabled
                          ? () => _openEventChat(
                                context,
                                visibleEvents[i],
                              )
                          : null,
                    ),
                    if (i != visibleEvents.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              );
            },
            loading: () => const HomeLoadingCard(height: 120),
            error: (_, _) => const HomeErrorStateCard(
              message: 'Could not load your events.',
            ),
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
    final hasInvites = invitesAsync.maybeWhen(
      data: (invites) => invites.isNotEmpty,
      orElse: () => false,
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'My plans',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: PlanrDesign.ink,
                  letterSpacing: -0.5,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        _InviteIconButton(
          hasInvites: hasInvites,
          onTap: onInvitesTap,
        ),
      ],
    );
  }
}

class _InviteIconButton extends StatelessWidget {
  const _InviteIconButton({
    required this.hasInvites,
    required this.onTap,
  });

  final bool hasInvites;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  Icons.mail_rounded,
                  color: hasInvites
                      ? PlanrDesign.accent
                      : PlanrDesign.softMuted.withOpacity(0.75),
                  size: 25,
                ),
              ),
              if (hasInvites)
                Positioned(
                  top: 7,
                  right: 6,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: PlanrDesign.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}