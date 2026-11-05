import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../providers/event_provider.dart';
import '../providers/friends_provider.dart';
import 'event_invites_screen.dart';
import 'friend_requests_screen.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  void _openEventInvites(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EventInvitesScreen(),
      ),
    );
  }

  void _openFriendRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FriendRequestsScreen(),
      ),
    );
  }

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return '';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month · $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(pendingEventInvitesProvider);
    final friendRequestsAsync = ref.watch(incomingFriendRequestsProvider);

    return PlanrBackground(
      variant: PlanrBackgroundVariant.home,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              PlanrDesign.pagePadding,
              18,
              PlanrDesign.pagePadding,
              118,
            ),
            children: [
              Row(
                children: [
                  Material(
                    color: PlanrDesign.backgroundButton,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: PlanrDesign.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              invitesAsync.when(
                data: (invites) {
                  return _NotificationBlock(
                    title: 'Event invites',
                    subtitle: invites.isEmpty
                        ? 'No pending event invites.'
                        : '${invites.length} pending invite${invites.length == 1 ? '' : 's'}',
                    icon: Icons.mail_rounded,
                    onTap: invites.isEmpty
                        ? null
                        : () => _openEventInvites(context),
                    children: [
                      if (invites.isEmpty)
                        const _EmptyNotificationLine(
                          text: 'You are all caught up.',
                        )
                      else
                        for (final invite in invites.take(3))
                          _NotificationLine(
                            title: invite['eventTitle'] as String? ??
                                'Event invite',
                            subtitle: [
                              invite['invitedByDisplayName'] != null
                                  ? 'Invited by ${invite['invitedByDisplayName']}'
                                  : null,
                              _formatDate(invite['eventDate']),
                            ]
                                .whereType<String>()
                                .where((text) => text.trim().isNotEmpty)
                                .join(' · '),
                          ),
                    ],
                  );
                },
                loading: () => const _LoadingBlock(title: 'Event invites'),
                error: (_, _) => const _ErrorBlock(
                  title: 'Event invites',
                  message: 'Could not load event invites.',
                ),
              ),
              const SizedBox(height: 14),
              friendRequestsAsync.when(
                data: (requests) {
                  return _NotificationBlock(
                    title: 'Friend requests',
                    subtitle: requests.isEmpty
                        ? 'No pending friend requests.'
                        : '${requests.length} pending request${requests.length == 1 ? '' : 's'}',
                    icon: Icons.person_add_alt_1_rounded,
                    onTap: requests.isEmpty
                        ? null
                        : () => _openFriendRequests(context),
                    children: [
                      if (requests.isEmpty)
                        const _EmptyNotificationLine(
                          text: 'No new requests right now.',
                        )
                      else
                        for (final request in requests.take(3))
                          _NotificationLine(
                            title: request['fromDisplayName'] as String? ??
                                'Friend request',
                            subtitle: 'Wants to connect with you',
                          ),
                    ],
                  );
                },
                loading: () => const _LoadingBlock(title: 'Friend requests'),
                error: (_, _) => const _ErrorBlock(
                  title: 'Friend requests',
                  message: 'Could not load friend requests.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBlock extends StatelessWidget {
  const _NotificationBlock({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      color: PlanrDesign.cardLight.withValues(alpha: 0.84),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: PlanrDesign.accentSoft.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: PlanrDesign.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: PlanrDesign.softMuted,
                  size: 26,
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _NotificationLine extends StatelessWidget {
  const _NotificationLine({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.055),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: PlanrDesign.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotificationLine extends StatelessWidget {
  const _EmptyNotificationLine({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: PlanrDesign.muted,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(18),
      color: PlanrDesign.cardLight.withValues(alpha: 0.84),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading $title...',
            style: const TextStyle(
              color: PlanrDesign.muted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(18),
      color: PlanrDesign.cardLight.withValues(alpha: 0.84),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade500,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}