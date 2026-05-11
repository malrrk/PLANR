import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_avatar.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_empty_state.dart';
import '../core/widgets/planr_scaffold.dart';
import '../models/event.dart';
import '../models/user_profile.dart';
import '../providers/event_provider.dart';
import '../providers/friends_provider.dart';

class InviteToEventScreen extends ConsumerStatefulWidget {
  const InviteToEventScreen({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  ConsumerState<InviteToEventScreen> createState() =>
      _InviteToEventScreenState();
}

class _InviteToEventScreenState extends ConsumerState<InviteToEventScreen> {
  final Set<String> _invitingUserIds = {};
  final Set<String> _invitedUserIds = {};

  Future<void> _inviteFriend(UserProfile friend) async {
    if (_invitingUserIds.contains(friend.uid) ||
        _invitedUserIds.contains(friend.uid)) {
      return;
    }

    setState(() {
      _invitingUserIds.add(friend.uid);
    });

    final error = await ref.read(eventServiceProvider).inviteUserToEvent(
          event: widget.event,
          invitedUid: friend.uid,
          invitedDisplayName: friend.displayName,
          invitedPhotoUrl: friend.photoUrl,
        );

    if (!mounted) return;

    setState(() {
      _invitingUserIds.remove(friend.uid);

      if (error == null) {
        _invitedUserIds.add(friend.uid);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Invite sent'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(myFriendsProvider);

    return PlanrScaffold(
      title: 'Invite Friends',
      variant: PlanrBackgroundVariant.events,
      child: friendsAsync.when(
        data: (friends) {
          if (friends.isEmpty) {
            return const Center(
              child: PlanrEmptyState(
                icon: Icons.group_add_rounded,
                title: 'No friends to invite yet',
                subtitle:
                    'Add friends first, then invite them to private events.',
              ),
            );
          }

          return ListView(
            children: [
              _EventInviteHeader(event: widget.event),
              const SizedBox(height: 16),
              const Text(
                'Friends',
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.55,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose who should get an invite.',
                style: TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              for (int i = 0; i < friends.length; i++) ...[
                _FriendInviteTile(
                  eventId: widget.event.id,
                  friend: friends[i],
                  isInviting: _invitingUserIds.contains(friends[i].uid),
                  wasJustInvited: _invitedUserIds.contains(friends[i].uid),
                  onInvite: () => _inviteFriend(friends[i]),
                ),
                if (i != friends.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 20),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => const Center(
          child: PlanrEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Friends could not load',
            subtitle: 'Something went wrong while loading your friends.',
          ),
        ),
      ),
    );
  }
}

class _EventInviteHeader extends StatelessWidget {
  const _EventInviteHeader({
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    final hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;

    return PlanrCard(
      padding: EdgeInsets.zero,
      radius: 30,
      child: Container(
        height: 142,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: PlanrDesign.accentSoft.withOpacity(0.45),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(
                event.imageUrl!,
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PlanrDesign.cardLight.withOpacity(0.95),
                      PlanrDesign.accentSoft.withOpacity(0.58),
                      const Color(0xFFFFE3CC).withOpacity(0.78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: PlanrDesign.eventOverlayGradient(),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invite to',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.05,
                    ),
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

class _FriendInviteTile extends ConsumerWidget {
  const _FriendInviteTile({
    required this.eventId,
    required this.friend,
    required this.isInviting,
    required this.wasJustInvited,
    required this.onInvite,
  });

  final String eventId;
  final UserProfile friend;
  final bool isInviting;
  final bool wasJustInvited;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(
      friendEventInviteStatusProvider(
        FriendEventInviteStatusArgs(
          eventId: eventId,
          userId: friend.uid,
        ),
      ),
    );

    final status = statusAsync.whenOrNull(
      data: (value) => value,
    );

    final effectiveStatus = wasJustInvited
        ? EventInviteFriendStatus.invited
        : status ?? EventInviteFriendStatus.invite;

    final buttonLabel = switch (effectiveStatus) {
      EventInviteFriendStatus.going => 'Going',
      EventInviteFriendStatus.accepted => 'Going',
      EventInviteFriendStatus.invited => 'Invited',
      EventInviteFriendStatus.declined => 'Invite again',
      EventInviteFriendStatus.invite => 'Invite',
    };

    final canInvite = effectiveStatus == EventInviteFriendStatus.invite ||
        effectiveStatus == EventInviteFriendStatus.declined;

    final variant = switch (effectiveStatus) {
      EventInviteFriendStatus.going => PlanrButtonVariant.soft,
      EventInviteFriendStatus.accepted => PlanrButtonVariant.soft,
      EventInviteFriendStatus.invited => PlanrButtonVariant.soft,
      EventInviteFriendStatus.declined => PlanrButtonVariant.outlined,
      EventInviteFriendStatus.invite => PlanrButtonVariant.filled,
    };

    return PlanrCard(
      padding: const EdgeInsets.all(14),
      radius: 24,
      shadow: false,
      color: PlanrDesign.card.withOpacity(0.64),
      child: Row(
        children: [
          PlanrAvatar(
            imageUrl: friend.photoUrl,
            name: friend.displayName,
            radius: 24,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${friend.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: effectiveStatus == EventInviteFriendStatus.declined
                ? 118
                : 96,
            child: PlanrButton(
              label: statusAsync.isLoading && !wasJustInvited
                  ? '...'
                  : buttonLabel,
              variant: variant,
              isLoading: isInviting,
              height: 44,
              onPressed: isInviting || !canInvite ? null : onInvite,
            ),
          ),
        ],
      ),
    );
  }
}