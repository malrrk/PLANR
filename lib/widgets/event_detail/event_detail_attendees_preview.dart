import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/event_provider.dart';
import 'event_detail_design.dart';

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

        if (visibleAttendees.isEmpty) {
          return _AttendeeShell(
            child: Text(
              '$attendeeCount going',
              style: const TextStyle(
                color: EventDetailDesign.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        return _AttendeeShell(
          child: Row(
            children: [
              SizedBox(
                width: visibleAttendees.length * 24 + 16,
                height: 42,
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
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  attendeeCount == 1
                      ? '1 person is going'
                      : '$attendeeCount people are going',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EventDetailDesign.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _AttendeeShell extends StatelessWidget {
  const _AttendeeShell({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FB),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
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
    final initial = displayName != null && displayName.isNotEmpty
        ? displayName.characters.first.toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 21,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFEDEFF8),
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: photoUrl == null
            ? Text(
                initial,
                style: const TextStyle(
                  color: EventDetailDesign.ink,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}