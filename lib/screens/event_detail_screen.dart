import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../providers/event_provider.dart';
import '../widgets/event_detail/event_detail_action_panel.dart';
import '../widgets/event_detail/event_detail_attendees_preview.dart';
import '../widgets/event_detail/event_detail_fact_card.dart';
import '../widgets/event_detail/event_detail_header_image.dart';
import '../widgets/event_detail/event_detail_host_row.dart';
import '../widgets/event_detail/event_detail_info_card.dart';
import '../widgets/event_tag_chips.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(eventId));

    return PlanrBackground(
      variant: PlanrBackgroundVariant.events,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: eventAsync.when(
          data: (event) {
            if (event == null) {
              return const _EventNotFoundState();
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                EventDetailHeaderImage(event: event),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -38),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        PlanrDesign.pagePadding,
                        0,
                        PlanrDesign.pagePadding,
                        34,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EventDetailInfoCard(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _VisibilityBadge(
                                      visibility: event.visibility,
                                    ),
                                    EventTagChips(
                                      tagIds: event.tags,
                                      maxVisible: 3,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontSize: 31,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.0,
                                    height: 1.05,
                                    color: PlanrDesign.ink,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                EventDetailHostRow(event: event),
                                const SizedBox(height: 16),
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
                                EventDetailFactCard(
                                  icon: Icons.people_alt_rounded,
                                  label: 'Attendees',
                                  value: event.attendeeCount == 1
                                      ? '1 person going'
                                      : '${event.attendeeCount} people going',
                                ),
                                const SizedBox(height: 14),
                                EventDetailAttendeesPreview(
                                  eventId: event.id,
                                  attendeeCount: event.attendeeCount,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          EventDetailInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle(
                                  title: 'About this event',
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
                          const SizedBox(height: 18),
                          EventDetailActionPanel(event: event),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const _EventLoadingState(),
          error: (_, _) => const _EventErrorState(),
        ),
      ),
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

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({
    required this.visibility,
  });

  final String visibility;

  @override
  Widget build(BuildContext context) {
    final isPrivate = visibility == 'private';

    final backgroundColor = isPrivate
        ? Colors.orange.withOpacity(0.14)
        : PlanrDesign.accentSoft.withOpacity(0.72);

    final foregroundColor =
        isPrivate ? Colors.orange.shade800 : PlanrDesign.accentDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.90),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrivate ? Icons.lock_rounded : Icons.public_rounded,
            size: 15,
            color: foregroundColor,
          ),
          const SizedBox(width: 6),
          Text(
            isPrivate ? 'Private' : 'Public',
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
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