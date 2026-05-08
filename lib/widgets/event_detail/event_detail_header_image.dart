import 'package:flutter/material.dart';

import '../../models/event.dart';
import 'event_detail_design.dart';

class EventDetailHeaderImage extends StatelessWidget {
  const EventDetailHeaderImage({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 330,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: EventDetailDesign.ink,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Hero(
          tag: 'event-image-${event.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              event.imageUrl != null
                  ? Image.network(
                      event.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : const _EventImagePlaceholder(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x22000000),
                      Color(0xCC000000),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 48,
                child: Row(
                  children: [
                    _HeaderBadge(
                      icon: Icons.local_fire_department_rounded,
                      label: '${event.attendeeCount} going',
                    ),
                    const SizedBox(width: 10),
                    if (event.chatEnabled)
                      const _HeaderBadge(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chat open',
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

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: EventDetailDesign.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: EventDetailDesign.ink,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventImagePlaceholder extends StatelessWidget {
  const _EventImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: EventDetailDesign.brandGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.celebration_rounded,
          color: Colors.white,
          size: 78,
        ),
      ),
    );
  }
}