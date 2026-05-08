import 'package:flutter/material.dart';

import '../../models/event.dart';
import 'event_detail_design.dart';

class EventDetailHostRow extends StatelessWidget {
  const EventDetailHostRow({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: const Color(0xFFF1F2FA),
          backgroundImage: event.creatorPhotoUrl != null
              ? NetworkImage(event.creatorPhotoUrl!)
              : null,
          child: event.creatorPhotoUrl == null
              ? Text(
                  event.creatorDisplayName.isNotEmpty
                      ? event.creatorDisplayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: EventDetailDesign.ink,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hosted by',
                style: TextStyle(
                  color: EventDetailDesign.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                event.creatorDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EventDetailDesign.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}