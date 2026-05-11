import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../widgets/event_detail/event_detail_action_panel.dart';
import '../widgets/event_detail/event_detail_fact_card.dart';
import '../widgets/event_detail/event_detail_header_image.dart';
import '../widgets/event_detail/event_detail_info_card.dart';
import 'profile_screen.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$weekday, $day.$month · $hour:$minute';
  }

  void _openProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(eventId));

    return PlanrBackground(
      variant: PlanrBackgroundVariant.events,
      child: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Scaffold(
              backgroundColor: Colors.transparent,
              body: _EventNotFoundState(),
            );
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: _FloatingGoingButton(event: event),
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                EventDetailHeaderImage(event: event),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PlanrDesign.pagePadding,
                      18,
                      PlanrDesign.pagePadding,
                      118,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EventDetailInfoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                title: 'About',
                                icon: Icons.notes_rounded,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                event.description.trim().isEmpty
                                    ? 'No description yet.'
                                    : event.description,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  height: 1.56,
                                  color: PlanrDesign.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        EventDetailActionPanel(event: event),
                        const SizedBox(height: 16),
                        EventDetailInfoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                title: 'Details',
                                icon: Icons.info_outline_rounded,
                              ),
                              const SizedBox(height: 14),
                              EventDetailFactCard(
                                icon: Icons.schedule_rounded,
                                label: 'Date & Time',
                                value: _formatDate(event.date),
                              ),
                              const SizedBox(height: 10),
                              EventDetailFactCard(
                                icon: Icons.place_rounded,
                                label: 'Location',
                                value: event.address,
                              ),
                              const SizedBox(height: 10),
                              _TappableHostFactCard(
                                hostName: event.creatorDisplayName,
                                onTap: () => _openProfile(context, event.creatorUid),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Scaffold(
          backgroundColor: Colors.transparent,
          body: _EventLoadingState(),
        ),
        error: (_, _) => const Scaffold(
          backgroundColor: Colors.transparent,
          body: _EventErrorState(),
        ),
      ),
    );
  }
}

class _FloatingGoingButton extends ConsumerWidget {
  const _FloatingGoingButton({
    required this.event,
  });

  final Event event;

  Future<void> _toggleGoing({
    required BuildContext context,
    required WidgetRef ref,
    required bool isGoing,
  }) async {
    final service = ref.read(eventServiceProvider);

    final error = isGoing
        ? await service.leaveEvent(event)
        : await service.joinEvent(event);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? (isGoing ? 'You left the event.' : 'You are going.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGoingAsync = ref.watch(isGoingProvider(event.id));

    return isGoingAsync.when(
      data: (isGoing) {
        return FloatingActionButton.extended(
          heroTag: 'event-going-${event.id}',
          onPressed: () => _toggleGoing(
            context: context,
            ref: ref,
            isGoing: isGoing,
          ),
          backgroundColor:
              isGoing ? PlanrDesign.accentSoft : PlanrDesign.accent,
          foregroundColor:
              isGoing ? PlanrDesign.accentDark : Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          icon: Icon(
            isGoing
                ? Icons.check_circle_rounded
                : Icons.add_circle_rounded,
          ),
          label: Text(
            isGoing ? 'Going' : 'I am going',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        );
      },
      loading: () {
        return FloatingActionButton(
          heroTag: 'event-going-loading-${event.id}',
          onPressed: null,
          backgroundColor: PlanrDesign.accentSoft,
          foregroundColor: PlanrDesign.accentDark,
          elevation: 4,
          child: const SizedBox(
            width: 21,
            height: 21,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        );
      },
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PlanrDesign.accentSoft.withOpacity(0.72),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: PlanrDesign.accentDark,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: PlanrDesign.ink,
          ),
        ),
      ],
    );
  }
}

class _TappableHostFactCard extends StatelessWidget {
  const _TappableHostFactCard({
    required this.hostName,
    required this.onTap,
  });

  final String hostName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanrDesign.cardLight.withOpacity(0.78),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.92),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: PlanrDesign.accentSoft.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: PlanrDesign.accentDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Host',
                      style: TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hostName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: PlanrDesign.softMuted,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventLoadingState extends StatelessWidget {
  const _EventLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.6),
    );
  }
}

class _EventErrorState extends StatelessWidget {
  const _EventErrorState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessageCard(
      icon: Icons.error_outline_rounded,
      title: 'Could not load event.',
      subtitle: 'Please try again in a moment.',
    );
  }
}

class _EventNotFoundState extends StatelessWidget {
  const _EventNotFoundState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessageCard(
      icon: Icons.search_off_rounded,
      title: 'Event not found.',
      subtitle: 'This event may have been deleted.',
    );
  }
}

class _CenteredMessageCard extends StatelessWidget {
  const _CenteredMessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlanrDesign.pagePadding),
        child: PlanrCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: PlanrDesign.accentDark,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PlanrDesign.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}