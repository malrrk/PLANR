import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/plan_time.dart';
import '../../core/theme/planr_design.dart';
import '../../models/event.dart';
import '../../models/event_schedule.dart';
import '../../providers/event_provider.dart';
import '../../screens/event_chat_screen.dart';
import '../../screens/event_detail_screen.dart';
import '../../screens/plans_screen.dart';
import '../attendee_preview.dart';
import '../event_cover.dart';
import '../plans/quick_plan_sheet.dart';
import 'home_error_state_card.dart';
import 'home_loading_card.dart';
import 'home_section_header.dart';
import 'my_event_mini_card.dart';

/// The nearest plan as a large hero, then a short list of what comes after it.
class HomeNextUpSection extends ConsumerWidget {
  const HomeNextUpSection({super.key});

  static const _laterCount = 3;

  void _openEvent(BuildContext context, String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventId)),
    );
  }

  void _openChat(BuildContext context, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventChatScreen(event: event)),
    );
  }

  void _openAllPlans(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlansScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(myEventsProvider);

    return eventsAsync.when(
      data: (events) {
        final upcoming = upcomingEvents(events, now: DateTime.now());

        if (upcoming.isEmpty) {
          return _EmptyPlans(
            onStart: () => showQuickPlanSheet(context),
          );
        }

        final next = upcoming.first;
        final later = upcoming.skip(1).take(_laterCount).toList();
        final remaining = upcoming.length - 1 - later.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionHeader(
              title: 'Next up',
              subtitle: upcoming.length == 1
                  ? '1 upcoming plan'
                  : '${upcoming.length} upcoming plans',
              onTap: () => _openAllPlans(context),
              trailing: const _AllPlansLink(),
            ),
            const SizedBox(height: 14),
            _HeroPlanCard(
              event: next,
              onTap: () => _openEvent(context, next.id),
              onChatTap: next.chatEnabled
                  ? () => _openChat(context, next)
                  : null,
            ),
            if (later.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final event in later)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MyEventMiniCard(
                    event: event,
                    onTap: () => _openEvent(context, event.id),
                    onChatTap:
                        event.chatEnabled ? () => _openChat(context, event) : null,
                  ),
                ),
            ],
            if (remaining > 0)
              GestureDetector(
                onTap: () => _openAllPlans(context),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+ $remaining more in your calendar',
                    style: const TextStyle(
                      color: PlanrDesign.accentDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const HomeLoadingCard(height: 230),
      error: (_, _) => const HomeErrorStateCard(
        message: 'Could not load your plans.',
      ),
    );
  }
}

class _AllPlansLink extends StatelessWidget {
  const _AllPlansLink();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'All plans',
          style: TextStyle(
            color: PlanrDesign.accentDark,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: PlanrDesign.accentDark,
          size: 20,
        ),
      ],
    );
  }
}

class _HeroPlanCard extends StatelessWidget {
  const _HeroPlanCard({
    required this.event,
    required this.onTap,
    required this.onChatTap,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onChatTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final linked = event.isLinkedGroup;
    final date = linked ? (event.linkedPublicEventDate ?? event.date) : event.date;
    final title = linked
        ? (event.linkedPublicEventTitle ?? event.title)
        : event.title;
    final imageUrl =
        linked ? (event.linkedPublicEventImageUrl ?? event.imageUrl) : event.imageUrl;
    final address = (linked
            ? (event.linkedPublicEventAddress ?? event.address)
            : event.address)
        .trim();

    final today = isSameDay(date, now);
    final pillText = today
        ? (date.hour >= 17 ? 'TONIGHT' : 'TODAY')
        : countdownLabel(date, now: now).toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 236,
        decoration: BoxDecoration(
          color: PlanrDesign.ink,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: (today ? PlanrDesign.accent : Colors.black)
                  .withValues(alpha: today ? 0.32 : 0.16),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            EventCover(imageUrl: imageUrl, tags: event.tags, iconSize: 44),
            const EventScrim(),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: today ? PlanrDesign.storyRingGradient : null,
                  color: today ? null : Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      today ? Icons.bolt_rounded : Icons.schedule_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      pillText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.04,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    [
                      planTimeLabel(date, now: now),
                      if (address.isNotEmpty) address,
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AttendeePreview(
                          eventId: event.id,
                          attendeeCount: event.attendeeCount,
                          maxVisible: 4,
                          preferFriends: true,
                          dark: true,
                        ),
                      ),
                      if (onChatTap != null)
                        _ChatBubble(
                          hasUnread: event.hasUnreadMessages,
                          onTap: onChatTap!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.hasUnread, required this.onTap});

  final bool hasUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: PlanrDesign.accent,
              size: 21,
            ),
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: PlanrDesign.storyRingStart,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PlanrDesign.accentSoft.withValues(alpha: 0.8),
            PlanrDesign.cardLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [PlanrDesign.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: PlanrDesign.brandGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Your calendar is wide open',
            style: TextStyle(
              color: PlanrDesign.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Plans you make or accept show up here. Start one with a friend, it takes a few taps.',
            style: TextStyle(
              color: PlanrDesign.muted,
              fontSize: 14.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Make a plan',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: PlanrDesign.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
