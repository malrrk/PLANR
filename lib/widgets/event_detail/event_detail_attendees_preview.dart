import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/planr_design.dart';
import '../../core/widgets/planr_avatar.dart';
import '../../providers/event_provider.dart';

class EventDetailAttendeesPreview extends ConsumerWidget {
  const EventDetailAttendeesPreview({
    super.key,
    required this.eventId,
    required this.attendeeCount,
    this.maxVisible = 6,
  });

  final String eventId;
  final int attendeeCount;
  final int maxVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(eventAttendeesProvider(eventId));

    return attendeesAsync.when(
      data: (attendees) {
        final visibleAttendees = attendees.take(maxVisible).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.42),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(0.92),
            ),
          ),
          child: Row(
            children: [
              if (visibleAttendees.isNotEmpty)
                SizedBox(
                  width: visibleAttendees.length * 24 + 22,
                  height: 44,
                  child: Stack(
                    children: [
                      for (var i = 0; i < visibleAttendees.length; i++)
                        Positioned(
                          left: i * 24,
                          child: _AttendeeAvatar(
                            data: visibleAttendees[i],
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PlanrDesign.accentSoft.withOpacity(0.72),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: PlanrDesign.accentDark,
                    size: 22,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  attendeeCount == 0
                      ? 'Be the first one going'
                      : attendeeCount == 1
                          ? '1 person is going'
                          : '$attendeeCount people are going',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 54,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _AttendeeAvatar extends StatelessWidget {
  const _AttendeeAvatar({
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final photoUrl = data['photoUrl'] as String?;
    final displayName = data['displayName'] as String?;

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PlanrAvatar(
        imageUrl: photoUrl,
        name: displayName,
        radius: 20,
      ),
    );
  }
}