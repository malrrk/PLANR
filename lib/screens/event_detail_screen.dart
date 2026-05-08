import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/event_provider.dart';
import '../widgets/event_detail/event_detail_action_panel.dart';
import '../widgets/event_detail/event_detail_attendees_preview.dart';
import '../widgets/event_detail/event_detail_design.dart';
import '../widgets/event_detail/event_detail_header_image.dart';
import '../widgets/event_detail/event_detail_host_row.dart';
import '../widgets/event_detail/event_detail_info_card.dart';
import '../widgets/event_detail/event_detail_tile.dart';
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
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$weekday, $day.$month.$year · $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(eventId));

    return Container(
      decoration: const BoxDecoration(
        gradient: EventDetailDesign.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: eventAsync.when(
          data: (event) {
            if (event == null) {
              return const _EventNotFoundState();
            }

            return CustomScrollView(
              slivers: [
                EventDetailHeaderImage(event: event),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EventDetailInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _VisibilityBadge(visibility: event.visibility),
                                const SizedBox(height: 10),
                                EventTagChips(
                                  tagIds: event.tags,
                                  maxVisible: 3,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.9,
                                    height: 1.08,
                                    color: EventDetailDesign.ink,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                EventDetailHostRow(event: event),
                                const SizedBox(height: 22),
                                EventDetailTile(
                                  icon: Icons.schedule_rounded,
                                  title: 'Date & Time',
                                  value: _formatDate(event.date),
                                ),
                                const SizedBox(height: 12),
                                EventDetailTile(
                                  icon: Icons.place_rounded,
                                  title: 'Location',
                                  value: event.address,
                                ),
                                const SizedBox(height: 12),
                                EventDetailTile(
                                  icon: Icons.people_alt_rounded,
                                  title: 'Attendees',
                                  value: '${event.attendeeCount} going',
                                ),
                                const SizedBox(height: 18),
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
                                const Text(
                                  'About this event',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    color: EventDetailDesign.ink,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  event.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.55,
                                    color: EventDetailDesign.muted,
                                    fontWeight: FontWeight.w500,
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

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({
    required this.visibility,
  });

  final String visibility;

  @override
  Widget build(BuildContext context) {
    final isPrivate = visibility == 'private';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: isPrivate
            ? Colors.orange.withOpacity(0.12)
            : EventDetailDesign.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrivate ? Icons.lock_rounded : Icons.public_rounded,
            size: 16,
            color: isPrivate ? Colors.orange.shade700 : EventDetailDesign.primary,
          ),
          const SizedBox(width: 6),
          Text(
            isPrivate ? 'Private event' : 'Public event',
            style: TextStyle(
              color: isPrivate ? Colors.orange.shade700 : EventDetailDesign.primary,
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
    return const Center(
      child: Text(
        'Could not load event.',
        style: TextStyle(
          color: EventDetailDesign.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EventNotFoundState extends StatelessWidget {
  const _EventNotFoundState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Event not found.',
        style: TextStyle(
          color: EventDetailDesign.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}