import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';
import '../../models/event.dart';

class MyEventMiniCard extends StatelessWidget {
  const MyEventMiniCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onChatTap,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onChatTap;

  String _formatImageDay(DateTime date) {
    return date.day.toString().padLeft(2, '0');
  }

  String _formatImageMonth(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return months[date.month - 1];
  }

  String _formatDayTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    final weekday = weekdays[date.weekday - 1];

    return '$weekday · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (event.isLinkedGroup) {
      return _LinkedGroupNormalMiniCard(
        event: event,
        onTap: onTap,
        onChatTap: onChatTap,
        dayText: _formatImageDay(event.linkedPublicEventDate ?? event.date),
        monthText: _formatImageMonth(event.linkedPublicEventDate ?? event.date),
        dayTime: _formatDayTime(event.linkedPublicEventDate ?? event.date),
      );
    }

    final location =
        event.address.trim().isEmpty ? 'No location' : event.address.trim();

    final isPrivate = event.visibility == 'private';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: onTap,
        child: Container(
          height: 98,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.43),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: Colors.black.withOpacity(0.07),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              _EventImage(
                imageUrl: event.imageUrl,
                dayText: _formatImageDay(event.date),
                monthText: _formatImageMonth(event.date),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EventContent(
                  title: event.title,
                  location: location,
                  dayTime: _formatDayTime(event.date),
                  isPrivate: isPrivate,
                  attendeeCount: event.attendeeCount,
                ),
              ),
              const SizedBox(width: 8),
              _ChatButton(
                enabled: event.chatEnabled,
                hasUnread: event.hasUnreadMessages,
                onTap: onChatTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkedGroupNormalMiniCard extends StatelessWidget {
  const _LinkedGroupNormalMiniCard({
    required this.event,
    required this.onTap,
    required this.onChatTap,
    required this.dayText,
    required this.monthText,
    required this.dayTime,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onChatTap;
  final String dayText;
  final String monthText;
  final String dayTime;

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final publicTitle =
        event.linkedPublicEventTitle?.trim().isNotEmpty == true
            ? event.linkedPublicEventTitle!.trim()
            : event.title;

    final publicLocation =
        event.linkedPublicEventAddress?.trim().isNotEmpty == true
            ? event.linkedPublicEventAddress!.trim()
            : event.address.trim();

    final inviteContext = event.creatorUid == currentUid
        ? 'Created by you'
        : 'Invited by ${event.creatorDisplayName}';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: onTap,
        child: Container(
          height: 116,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.43),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: PlanrDesign.accent.withOpacity(0.13),
              width: 1.15,
            ),
          ),
          child: Row(
            children: [
              _EventImage(
                imageUrl: event.linkedPublicEventImageUrl ?? event.imageUrl,
                dayText: dayText,
                monthText: monthText,
                linked: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: PlanrDesign.accentSoft.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.link_rounded,
                                size: 12,
                                color: PlanrDesign.accentDark,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Private group',
                                style: TextStyle(
                                  color: PlanrDesign.accentDark,
                                  fontSize: 11,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            inviteContext,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: PlanrDesign.softMuted.withOpacity(0.95),
                              fontSize: 11.5,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      publicTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 18,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14.5,
                          color: PlanrDesign.muted.withOpacity(0.82),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          flex: 6,
                          child: Text(
                            publicLocation.isEmpty ? 'No location' : publicLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: PlanrDesign.muted.withOpacity(0.92),
                              fontSize: 12.6,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          flex: 5,
                          child: Text(
                            dayTime,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlanrDesign.eventMetaOrange,
                              fontSize: 12.6,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ChatButton(
                enabled: event.chatEnabled,
                hasUnread: event.hasUnreadMessages,
                onTap: onChatTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({
    required this.imageUrl,
    required this.dayText,
    required this.monthText,
    this.linked = false,
  });

  final String? imageUrl;
  final String dayText;
  final String monthText;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    final trimmedImageUrl = imageUrl?.trim();
    final hasImage = trimmedImageUrl != null && trimmedImageUrl.isNotEmpty;

    return Container(
      width: 74,
      height: 82,
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withOpacity(0.75),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: linked
              ? PlanrDesign.accent.withOpacity(0.35)
              : Colors.black.withOpacity(0.16),
          width: 1.35,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 9,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              trimmedImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ImagePlaceholder(),
            )
          else
            const _ImagePlaceholder(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.18),
                  Colors.black.withOpacity(0.42),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: PlanrDesign.eventMetaOrange,
                      fontSize: 34,
                      height: 0.86,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.6,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    monthText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: PlanrDesign.eventMetaOrange,
                      fontSize: 16,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (linked)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: PlanrDesign.accentDark,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

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
          size: 24,
        ),
      ),
    );
  }
}

class _EventContent extends StatelessWidget {
  const _EventContent({
    required this.title,
    required this.location,
    required this.dayTime,
    required this.isPrivate,
    required this.attendeeCount,
  });

  final String title;
  final String location;
  final String dayTime;
  final bool isPrivate;
  final int attendeeCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlanrDesign.ink,
              fontSize: 19.2,
              height: 1.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.85,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14.5,
                color: PlanrDesign.muted.withOpacity(0.82),
              ),
              const SizedBox(width: 4),
              Flexible(
                flex: 6,
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PlanrDesign.muted.withOpacity(0.92),
                    fontSize: 13,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                flex: 5,
                child: Text(
                  dayTime,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.eventMetaOrange,
                    fontSize: 13,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                size: 13.5,
                color: PlanrDesign.softMuted.withOpacity(0.78),
              ),
              const SizedBox(width: 4),
              Text(
                isPrivate ? 'Private' : 'Public',
                style: TextStyle(
                  color: PlanrDesign.softMuted.withOpacity(0.9),
                  fontSize: 12.5,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.group_rounded,
                size: 14.5,
                color: PlanrDesign.softMuted.withOpacity(0.78),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '$attendeeCount going',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PlanrDesign.softMuted.withOpacity(0.9),
                    fontSize: 12.7,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
        ],
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  const _ChatButton({
    required this.enabled,
    required this.hasUnread,
    required this.onTap,
  });

  final bool enabled;
  final bool hasUnread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || onTap == null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: disabled
              ? Colors.black.withOpacity(0.045)
              : PlanrDesign.accent.withOpacity(0.115),
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: disabled ? null : onTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: disabled
                      ? Colors.black.withOpacity(0.04)
                      : PlanrDesign.accent.withOpacity(0.14),
                  width: 1.05,
                ),
              ),
              child: Icon(
                disabled
                    ? Icons.speaker_notes_off_rounded
                    : Icons.chat_bubble_rounded,
                color: disabled
                    ? PlanrDesign.softMuted.withOpacity(0.58)
                    : PlanrDesign.accent,
                size: 20,
              ),
            ),
          ),
        ),
        if (!disabled && hasUnread)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: PlanrDesign.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.7,
                ),
              ),
            ),
          ),
      ],
    );
  }
}