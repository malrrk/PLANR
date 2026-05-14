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

class MyEventsSection extends ConsumerStatefulWidget {
  const MyEventsSection({
    super.key,
    this.onCollapsed,
  });

  final VoidCallback? onCollapsed;

  @override
  ConsumerState<MyEventsSection> createState() => _MyEventsSectionState();
}

class _MyEventsSectionState extends ConsumerState<MyEventsSection>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (!_isExpanded) {
      Future.delayed(const Duration(milliseconds: 280), () {
        if (!mounted) return;
        widget.onCollapsed?.call();
      });
    }
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

  void _openEventChat(BuildContext context, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventChatScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      child: AnimatedSize(
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleExpanded,
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
                        final eventText = events.length == 1
                            ? '1 upcoming plan'
                            : '${events.length} upcoming plans';

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
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 13),
              myEventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return const HomeEmptyStateCard(
                      message: 'No plans yet. Join an event or accept an invite.',
                      icon: Icons.event_available_rounded,
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < events.length; i++) ...[
                        MyEventMiniCard(
                          event: events[i],
                          onTap: () => _openEventDetails(
                            context,
                            events[i].id,
                          ),
                          onChatTap: events[i].chatEnabled
                              ? () => _openEventChat(
                                    context,
                                    events[i],
                                  )
                              : null,
                        ),
                        if (i != events.length - 1)
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
          ],
        ),
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