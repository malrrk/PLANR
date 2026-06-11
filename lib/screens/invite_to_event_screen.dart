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
import 'event_detail_screen.dart';

class InviteToEventScreen extends ConsumerStatefulWidget {
  const InviteToEventScreen({
    super.key,
    required this.event,
    this.openEventDetailOnFinish = false,
  });

  final Event event;

  /// Used after creating a new linked group.
  /// Skip/Done should then move the user to the new group detail page.
  final bool openEventDetailOnFinish;

  @override
  ConsumerState<InviteToEventScreen> createState() =>
      _InviteToEventScreenState();
}

class _InviteToEventScreenState extends ConsumerState<InviteToEventScreen> {
  final Set<String> _invitingUserIds = {};
  final Set<String> _invitedUserIds = {};

  Future<void> _inviteFriend(UserProfile friend) async {
    if (widget.event.isPublicEvent) {
      _showSnackBar('Create a private group before inviting friends.');
      return;
    }

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

    _showSnackBar(error ?? 'Invite sent');
  }

  void _finishInviteFlow() {
    if (!widget.openEventDetailOnFinish) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: widget.event.id),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String get _screenTitle {
    if (widget.event.isLinkedGroup) return 'Invite to Group';
    if (widget.event.isPublicEvent) return 'Public Event';
    return 'Invite Friends';
  }

  String get _friendsTitle {
    if (widget.event.isLinkedGroup) return 'Invite to your group';
    return 'Friends';
  }

  String get _friendsSubtitle {
    if (widget.event.isLinkedGroup) {
      return 'Choose who should be part of this private plan.';
    }

    return 'Choose who should get an invite.';
  }

  bool get _showFinishBar {
    return widget.openEventDetailOnFinish && widget.event.isLinkedGroup;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event.isPublicEvent) {
      return PlanrScaffold(
        title: _screenTitle,
        variant: PlanrBackgroundVariant.events,
        child: ListView(
          children: [
            _EventInviteHeader(event: widget.event),
            const SizedBox(height: 16),
            const _PublicInviteBlockedCard(),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    final friendsAsync = ref.watch(myFriendsProvider);

    return PlanrScaffold(
      title: _screenTitle,
      variant: PlanrBackgroundVariant.events,
      child: Column(
        children: [
          Expanded(
            child: friendsAsync.when(
              data: (friends) {
                if (friends.isEmpty) {
                  return Center(
                    child: PlanrEmptyState(
                      icon: Icons.group_add_rounded,
                      title: 'No friends to invite yet',
                      subtitle: widget.event.isLinkedGroup
                          ? 'Add friends first, then invite them to your private group.'
                          : 'Add friends first, then invite them to private events.',
                    ),
                  );
                }

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _EventInviteHeader(event: widget.event),
                    const SizedBox(height: 16),
                    Text(
                      _friendsTitle,
                      style: const TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.55,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _friendsSubtitle,
                      style: const TextStyle(
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
                        wasJustInvited:
                            _invitedUserIds.contains(friends[i].uid),
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
                  subtitle:
                      'Something went wrong while loading your friends.',
                ),
              ),
            ),
          ),
          if (_showFinishBar)
            _InviteFinishBar(
              invitedCount: _invitedUserIds.length,
              onSkip: _finishInviteFlow,
              onDone: _finishInviteFlow,
            ),
        ],
      ),
    );
  }
}

class _InviteFinishBar extends StatelessWidget {
  const _InviteFinishBar({
    required this.invitedCount,
    required this.onSkip,
    required this.onDone,
  });

  final int invitedCount;
  final VoidCallback onSkip;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: PlanrCard(
          padding: const EdgeInsets.all(12),
          radius: 26,
          color: PlanrDesign.cardLight.withOpacity(0.94),
          child: Row(
            children: [
              Expanded(
                child: PlanrButton(
                  label: 'Skip',
                  icon: Icons.arrow_forward_rounded,
                  variant: PlanrButtonVariant.outlined,
                  height: 46,
                  onPressed: onSkip,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PlanrButton(
                  label: invitedCount == 0 ? 'Done' : 'Done ($invitedCount)',
                  icon: Icons.check_rounded,
                  height: 46,
                  onPressed: onDone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicInviteBlockedCard extends StatelessWidget {
  const _PublicInviteBlockedCard();

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(18),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: PlanrDesign.accentSoft.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: PlanrDesign.accentDark,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Public events do not use direct invites',
                      style: TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Create a private group first, then invite friends into that group.',
                      style: TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PlanrButton(
            label: 'Go back',
            icon: Icons.arrow_back_rounded,
            variant: PlanrButtonVariant.soft,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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
    final imageUrl = event.isLinkedGroup
        ? event.linkedPublicEventImageUrl?.trim()
        : event.imageUrl?.trim();

    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    final eyebrow = event.isLinkedGroup
        ? 'Private group for'
        : event.isPublicEvent
            ? 'Public event'
            : 'Invite to';

    final title = event.isLinkedGroup &&
            event.linkedPublicEventTitle != null &&
            event.linkedPublicEventTitle!.trim().isNotEmpty
        ? event.linkedPublicEventTitle!.trim()
        : event.title;

    final subtitle = event.isLinkedGroup
        ? event.title
        : event.isPublicEvent
            ? 'Make a group to invite friends'
            : null;

    return PlanrCard(
      padding: EdgeInsets.zero,
      radius: 30,
      child: Container(
        height: 164,
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
                imageUrl,
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
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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