import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../providers/event_provider.dart';
import '../providers/friends_provider.dart';

class AttendeePreview extends ConsumerWidget {
  const AttendeePreview({
    super.key,
    required this.eventId,
    required this.attendeeCount,
    this.maxVisible = 4,
    this.preferFriends = false,
    this.dark = false,
  });

  final String eventId;
  final int attendeeCount;
  final int maxVisible;
  final bool preferFriends;
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(eventAttendeesProvider(eventId));
    final friendsAsync = ref.watch(myFriendsProvider);

    final textColor = dark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = dark
        ? Colors.white.withOpacity(0.78)
        : const Color(0xFF475569);

    return attendeesAsync.when(
      data: (attendees) {
        final friends = friendsAsync.maybeWhen<List<UserProfile>>(
          data: (value) => value,
          orElse: () => const <UserProfile>[],
        );

        final friendUids = friends.map((friend) => friend.uid).toSet();

        final friendAttendees = attendees.where((attendee) {
          final uid = attendee['uid'] as String?;
          return uid != null && friendUids.contains(uid);
        }).toList();

        final visibleAttendees = preferFriends && friendAttendees.isNotEmpty
            ? friendAttendees.take(maxVisible).toList()
            : attendees.take(maxVisible).toList();

        final label = preferFriends && friendAttendees.isNotEmpty
            ? _buildFriendsGoingLabel(friendAttendees)
            : _buildGeneralGoingLabel(attendeeCount);

        if (visibleAttendees.isEmpty) {
          return Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mutedColor,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _avatarStackWidth(visibleAttendees.length),
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < visibleAttendees.length; i++)
                    Positioned(
                      left: i * 21,
                      child: _PreviewAvatar(
                        attendee: visibleAttendees[i],
                        dark: dark,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Text(
        _buildGeneralGoingLabel(attendeeCount),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: mutedColor,
          fontWeight: FontWeight.w800,
          fontSize: 13.5,
        ),
      ),
      error: (_, _) => Text(
        _buildGeneralGoingLabel(attendeeCount),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: mutedColor,
          fontWeight: FontWeight.w800,
          fontSize: 13.5,
        ),
      ),
    );
  }

  double _avatarStackWidth(int count) {
    if (count <= 0) return 0;
    return 32 + ((count - 1) * 21);
  }

  String _buildGeneralGoingLabel(int count) {
    if (count <= 0) return 'No one going yet';
    if (count == 1) return '1 going';
    return '$count going';
  }

  String _buildFriendsGoingLabel(List<Map<String, dynamic>> friendAttendees) {
    final count = friendAttendees.length;

    String nameAt(int index) {
      final name = friendAttendees[index]['displayName'] as String?;
      if (name == null || name.trim().isEmpty) return 'Friend';
      return name.trim().split(' ').first;
    }

    if (count == 1) {
      return '${nameAt(0)} is going';
    }

    if (count == 2) {
      return '${nameAt(0)} and ${nameAt(1)} are going';
    }

    return '${nameAt(0)} + ${count - 1} friends going';
  }
}

class _PreviewAvatar extends StatelessWidget {
  const _PreviewAvatar({
    required this.attendee,
    required this.dark,
  });

  final Map<String, dynamic> attendee;
  final bool dark;

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
      backgroundColor: dark ? Colors.white.withOpacity(0.92) : Colors.white,
      child: CircleAvatar(
        radius: 14.5,
        backgroundColor: dark
            ? Colors.white.withOpacity(0.18)
            : const Color(0xFFF1F2FA),
        backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
        child: !hasPhoto
            ? Text(
                initial,
                style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}