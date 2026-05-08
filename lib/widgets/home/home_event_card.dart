import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../screens/event_detail_screen.dart';
import '../../core/theme/planr_design.dart';
import '../../models/event_tag.dart';
import '../event_tag_chips.dart';

class HomeEventCard extends ConsumerWidget {
  const HomeEventCard({
    super.key,
    required this.event,
  });

  final Event event;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month · $hour:$minute';
  }

  EventTag? _primaryTag(Event event) {
    return primaryEventTag(event.tags);
  }

  String _categoryLabel(Event event) {
    final tag = _primaryTag(event);
    if (tag != null) return tag.label.toUpperCase();

    if (event.visibility == 'private') return 'PRIVATE';
    if (event.attendeeCount >= 20) return 'TRENDING';

    return 'EVENT';
  }

  IconData _categoryIcon(Event event) {
    final tag = _primaryTag(event);
    if (tag != null) return tag.icon;

    if (event.visibility == 'private') return Icons.lock_rounded;
    if (event.attendeeCount >= 20) {
      return Icons.local_fire_department_rounded;
    }

    return Icons.celebration_rounded;
  }

  Color _categoryColor(Event event) {
    final tag = _primaryTag(event);

    if (tag == null && event.visibility == 'private') {
      return const Color(0xFF6D5DF6);
    }

    return PlanrDesign.accent;
  }

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: event.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        height: 286,
        decoration: BoxDecoration(
          color: PlanrDesign.ink,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'event-image-${event.id}',
              child: _EventImage(event: event),
            ),
            const _EventImageOverlay(),
            Positioned(
              top: 18,
              left: 18,
              child: _CategoryPill(
                icon: _categoryIcon(event),
                label: _categoryLabel(event),
                color: _categoryColor(event),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _HostAvatarButton(event: event),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 29,
                                height: 1.04,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.9,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.description,
                              maxLines: event.tags.isEmpty ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 13.5,
                                height: 1.32,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (event.tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              EventTagChips(
                                tagIds: event.tags,
                                maxVisible: 3,
                                dark: true,
                                compact: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 118,
                        ),
                        child: _GoingRow(
                          eventId: event.id,
                          attendeeCount: event.attendeeCount,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _EventMetaLine(
                          icon: Icons.calendar_month_rounded,
                          text: _formatDate(event.date),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _EventMetaLine(
                          icon: Icons.location_on_outlined,
                          text: event.address.isEmpty ? 'No location' : event.address,
                        ),
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

class _EventImage extends StatelessWidget {
  const _EventImage({
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl?.trim();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _EventPlaceholderImage(),
      );
    }

    return const _EventPlaceholderImage();
  }
}

class _EventPlaceholderImage extends StatelessWidget {
  const _EventPlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: PlanrDesign.brandGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.celebration_rounded,
          color: Colors.white,
          size: 58,
        ),
      ),
    );
  }
}

class _EventImageOverlay extends StatelessWidget {
  const _EventImageOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: PlanrDesign.eventOverlayGradient(),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _HostAvatarButton extends StatelessWidget {
  const _HostAvatarButton({
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    final photoUrl = event.creatorPhotoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final name = event.creatorDisplayName.trim().isEmpty
        ? 'User'
        : event.creatorDisplayName.trim();

    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFFFDFC3),
        backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
        child: !hasPhoto
            ? Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: PlanrDesign.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}

class _GoingRow extends ConsumerWidget {
  const _GoingRow({
    required this.eventId,
    required this.attendeeCount,
  });

  final String eventId;
  final int attendeeCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(eventAttendeesProvider(eventId));

    return attendeesAsync.when(
      data: (attendees) {
        final visible = attendees.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (visible.isNotEmpty)
              SizedBox(
                width: 68,
                height: 34,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < visible.length; i++)
                      Positioned(
                        left: i * 20,
                        child: _SmallAttendeeAvatar(attendee: visible[i]),
                      ),
                  ],
                ),
              )
            else
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              '$attendeeCount going',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        );
      },
      loading: () => Text(
        '$attendeeCount going',
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      error: (_, _) => Text(
        '$attendeeCount going',
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallAttendeeAvatar extends StatelessWidget {
  const _SmallAttendeeAvatar({
    required this.attendee,
  });

  final Map<String, dynamic> attendee;

  @override
  Widget build(BuildContext context) {
    final photoUrl = (attendee['photoUrl'] as String?)?.trim();
    final displayName = (attendee['displayName'] as String?)?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final initial = displayName != null && displayName.isNotEmpty
        ? displayName.characters.first.toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 17,
      backgroundColor: Colors.white.withOpacity(0.9),
      child: CircleAvatar(
        radius: 14.5,
        backgroundColor: Colors.white.withOpacity(0.22),
        backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
        child: !hasPhoto
            ? Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}

class _EventMetaLine extends StatelessWidget {
  const _EventMetaLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: PlanrDesign.eventMetaOrange,
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlanrDesign.eventMetaOrange,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}