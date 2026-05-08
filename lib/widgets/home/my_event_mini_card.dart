import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../core/theme/planr_design.dart';
import '../../models/event_tag.dart';

class MyEventMiniCard extends StatelessWidget {
  const MyEventMiniCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  String _formatSmallEventDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          width: 252,
          decoration: BoxDecoration(
            color: PlanrDesign.ink,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.13),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _MiniEventImage(event: event),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: PlanrDesign.eventOverlayGradient(),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _MiniHostAvatar(event: event),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _MiniPrimaryTagPill(event: event),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniGoingPill(attendeeCount: event.attendeeCount),
                    const SizedBox(height: 9),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMetaLine(
                            icon: Icons.calendar_month_rounded,
                            label: _formatSmallEventDate(event.date),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _MiniMetaLine(
                            icon: Icons.location_on_outlined,
                            label: event.address.isEmpty
                                ? 'No location'
                                : event.address,
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
      ),
    );
  }
}

class _MiniEventImage extends StatelessWidget {
  const _MiniEventImage({
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
        errorBuilder: (_, _, _) => const _MiniImagePlaceholder(),
      );
    }

    return const _MiniImagePlaceholder();
  }
}

class _MiniImagePlaceholder extends StatelessWidget {
  const _MiniImagePlaceholder();

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
          size: 42,
        ),
      ),
    );
  }
}

class _MiniHostAvatar extends StatelessWidget {
  const _MiniHostAvatar({
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

    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.black.withOpacity(0.42),
      child: CircleAvatar(
        radius: 15,
        backgroundColor: Colors.white.withOpacity(0.18),
        backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
        child: !hasPhoto
            ? Text(
                name.characters.first.toUpperCase(),
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

class _MiniGoingPill extends StatelessWidget {
  const _MiniGoingPill({
    required this.attendeeCount,
  });

  final int attendeeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: PlanrDesign.accent.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.group_rounded,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            '$attendeeCount going',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetaLine extends StatelessWidget {
  const _MiniMetaLine({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white.withOpacity(0.88),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniPrimaryTagPill extends StatelessWidget {
  const _MiniPrimaryTagPill({
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    final tag = primaryEventTag(event.tags);

    if (tag == null) {
      final isPrivate = event.visibility == 'private';

      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.14),
          ),
        ),
        child: Icon(
          isPrivate ? Icons.lock_rounded : Icons.public_rounded,
          color: Colors.white,
          size: 16,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: PlanrDesign.accent.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tag.icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            tag.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}