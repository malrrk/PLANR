import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';
import '../../core/widgets/planr_avatar.dart';
import '../../models/event.dart';

class EventDetailHostRow extends StatelessWidget {
  const EventDetailHostRow({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.42),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
        ),
      ),
      child: Row(
        children: [
          PlanrAvatar(
            imageUrl: event.creatorPhotoUrl,
            name: event.creatorDisplayName,
            radius: 23,
            showRing: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hosted by',
                  style: TextStyle(
                    color: PlanrDesign.softMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.creatorDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withOpacity(0.72),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: PlanrDesign.accentDark,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}