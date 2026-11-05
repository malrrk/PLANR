import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/moderation_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/account/delete_account_dialog.dart';
import '../widgets/moderation/moderation_actions.dart';
import '../widgets/profile/profile_action_section.dart';
import '../widgets/profile/profile_empty_state.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_pinned_moments.dart';
import '../widgets/profile/profile_stats_row.dart';
import 'edit_profile_screen.dart';
import 'blocked_users_screen.dart';
import 'legal_screen.dart';
import 'friend_requests_screen.dart';
import 'friends_screen.dart';
import 'user_search_screen.dart';
import 'manage_pinned_moments_screen.dart';
import 'managed_public_pages_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    this.userId,
  });

  final String? userId;

  Future<void> _createMissingProfile(WidgetRef ref) async {
    final authState = ref.read(currentFirebaseUserProvider);
    final user = authState.value;
    if (user == null) return;

    final fallbackUsername = 'user_${user.uid.substring(0, 8).toLowerCase()}';

    await ref.read(userProfileServiceProvider).createUserProfile(
          uid: user.uid,
          displayName: user.displayName ?? 'User',
          username: fallbackUsername,
          email: user.email ?? '',
          photoUrl: user.photoURL,
          bio: null,
        );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _moreMenu(BuildContext context, WidgetRef ref, UserProfile profile) {
    final blocked = ref.watch(blockedUidsProvider).value ?? const <String>{};
    final isBlocked = blocked.contains(profile.uid);

    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: const Icon(Icons.more_horiz_rounded, color: PlanrDesign.accentDark),
      onSelected: (value) async {
        switch (value) {
          case 'report':
            await showReportDialog(
              context,
              ref,
              target: ReportTarget.user,
              targetId: profile.uid,
              title: 'Report ${profile.displayName}',
            );
          case 'block':
            await confirmAndBlockUser(
              context,
              ref,
              uid: profile.uid,
              name: profile.displayName,
            );
          case 'unblock':
            await ref.read(moderationServiceProvider).unblockUser(profile.uid);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'report', child: Text('Report')),
        PopupMenuItem(
          value: isBlocked ? 'unblock' : 'block',
          child: Text(isBlocked ? 'Unblock' : 'Block'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final targetUid = userId ?? currentUid;

    if (targetUid == null) {
      return const _ProfileNotFoundState(
        title: 'No user found',
        subtitle: 'Please sign in again to view your profile.',
      );
    }

    final isOwnProfile = currentUid == targetUid;

    final profileAsync = isOwnProfile
        ? ref.watch(currentUserProfileProvider)
        : ref.watch(userProfileByIdProvider(targetUid));

    final friendsCountAsync = ref.watch(friendsCountProvider(targetUid));

    return PlanrBackground(
      variant: PlanrBackgroundVariant.profile,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                if (isOwnProfile) {
                  return ProfileEmptyState(
                    onCreateProfile: () async {
                      await _createMissingProfile(ref);
                    },
                  );
                }

                return const _ProfileNotFoundState(
                  title: 'Profile not found',
                  subtitle: 'This user profile is no longer available.',
                );
              }

              final friendsCount = friendsCountAsync.maybeWhen(
                data: (count) => count,
                orElse: () => 0,
              );

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      PlanrDesign.pagePadding,
                      14,
                      PlanrDesign.pagePadding,
                      18,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _ProfileTopBar(
                        profile: profile,
                        isOwnProfile: isOwnProfile,
                        onEditPressed: isOwnProfile
                            ? () => _open(context, const EditProfileScreen())
                            : null,
                        trailing:
                            isOwnProfile ? null : _moreMenu(context, ref, profile),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      PlanrDesign.pagePadding,
                      0,
                      PlanrDesign.pagePadding,
                      isOwnProfile ? 118 : 28,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          if (isOwnProfile) ...[
                            const _EmailVerificationBanner(),
                            const SizedBox(height: 16),
                          ],
                          ProfileHeader(
                            profile: profile,
                            isOwnProfile: isOwnProfile,
                          ),
                          if (!isOwnProfile) ...[
                            const SizedBox(height: 16),
                            _FriendProfileActionCard(profile: profile),
                          ],
                          const SizedBox(height: 16),
                          ProfileStatsRow(
                            profile: profile,
                            friendsCount: friendsCount,
                          ),
                          const SizedBox(height: 16),
                          ProfilePinnedMoments(
                            profile: profile,
                            isOwnProfile: isOwnProfile,
                            onManage: isOwnProfile
                                ? () => _open(
                                      context,
                                      ManagePinnedMomentsScreen(profile: profile),
                                    )
                                : null,
                          ),
                          if (isOwnProfile) ...[
                            const SizedBox(height: 16),
                            _PublicPagesEntryCard(
                              onTap: () => _open(
                                context,
                                const ManagedPublicPagesScreen(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ProfileActionSection(
                              onEditProfile: () => _open(context, const EditProfileScreen()),
                              onFriends: () => _open(context, const FriendsScreen()),
                              onFindFriends: () => _open(context, const UserSearchScreen()),
                              onFriendRequests: () => _open(
                                context,
                                const FriendRequestsScreen(),
                              ),
                              onBlockedUsers: () =>
                                  _open(context, const BlockedUsersScreen()),
                              onLegal: () => _open(context, const LegalScreen()),
                              onDeleteAccount: () =>
                                  showDeleteAccountDialog(context, ref),
                              onLogout: () async {
                                await ref.read(authProvider).logout();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const _ProfileLoadingState(),
            error: (_, _) => const _ProfileErrorState(),
          ),
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.profile,
    required this.isOwnProfile,
    required this.onEditPressed,
    this.trailing,
  });

  final UserProfile profile;
  final bool isOwnProfile;
  final VoidCallback? onEditPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return Row(
      children: [
        if (!isOwnProfile && canGoBack) ...[
          Material(
            color: PlanrDesign.backgroundButton,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: Colors.black12,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: const CircleBorder(),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.12),
                    width: 1.1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: PlanrDesign.accentDark,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOwnProfile ? 'Profile' : profile.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isOwnProfile ? 'Your PLANR identity' : '@${profile.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
        if (isOwnProfile && onEditPressed != null)
          Material(
            color: PlanrDesign.backgroundButton,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: Colors.black12,
            child: InkWell(
              onTap: onEditPressed,
              customBorder: const CircleBorder(),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.12),
                    width: 1.1,
                  ),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: PlanrDesign.accentDark,
                  size: 21,
                ),
              ),
            ),
          ),
        ?trailing,
      ],
    );
  }
}

class _EmailVerificationBanner extends StatefulWidget {
  const _EmailVerificationBanner();

  @override
  State<_EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<_EmailVerificationBanner> {
  bool _busy = false;

  Future<void> _run(Future<String> Function(User user) action) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _busy) return;

    setState(() => _busy = true);

    String message;
    try {
      message = await action(user);
    } on FirebaseAuthException catch (e) {
      message = e.code == 'too-many-requests'
          ? 'Please wait a moment before trying again.'
          : 'Something went wrong. Please try again.';
    } catch (_) {
      message = 'Something went wrong. Please try again.';
    }

    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.emailVerified) return const SizedBox.shrink();

    return PlanrCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verify your email',
            style: TextStyle(
              color: PlanrDesign.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'We sent a link to your email address. Open it to confirm this account.',
            style: TextStyle(color: PlanrDesign.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run((user) async {
                          await user.sendEmailVerification();
                          return 'Verification email sent.';
                        }),
                child: const Text('Resend email'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run((user) async {
                          await user.reload();
                          return FirebaseAuth.instance.currentUser?.emailVerified ==
                                  true
                              ? 'Email verified. Thank you!'
                              : 'Not verified yet.';
                        }),
                child: const Text('I verified it'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendProfileActionCard extends ConsumerStatefulWidget {
  const _FriendProfileActionCard({
    required this.profile,
  });

  final UserProfile profile;

  @override
  ConsumerState<_FriendProfileActionCard> createState() =>
      _FriendProfileActionCardState();
}

class _FriendProfileActionCardState
    extends ConsumerState<_FriendProfileActionCard> {
  bool _processing = false;

  Future<void> _sendRequest() async {
    if (_processing) return;

    setState(() {
      _processing = true;
    });

    final error = await ref.read(friendsServiceProvider).sendFriendRequest(
          toUser: widget.profile,
        );

    if (!mounted) return;

    setState(() {
      _processing = false;
    });

    ref.invalidate(friendRelationshipProvider(widget.profile.uid));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Friend request sent.'),
      ),
    );
  }

  Future<void> _acceptRequest(FriendRelationship relationship) async {
    if (_processing) return;

    final requestId = relationship.incomingRequestId;
    final request = relationship.incomingRequest;

    if (requestId == null || request == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request not found.'),
        ),
      );
      return;
    }

    setState(() {
      _processing = true;
    });

    final error = await ref.read(friendsServiceProvider).acceptFriendRequest(
          requestId: requestId,
          request: request,
        );

    if (!mounted) return;

    setState(() {
      _processing = false;
    });

    ref.invalidate(friendRelationshipProvider(widget.profile.uid));
    ref.invalidate(myFriendsProvider);
    ref.invalidate(incomingFriendRequestsProvider);
    ref.invalidate(friendsCountProvider(widget.profile.uid));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Friend request accepted.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final relationshipAsync =
        ref.watch(friendRelationshipProvider(widget.profile.uid));

    return PlanrCard(
      padding: const EdgeInsets.all(16),
      radius: 28,
      child: relationshipAsync.when(
        data: (relationship) {
          final status = relationship.status;

          final icon = switch (status) {
            FriendRelationshipStatus.friends => Icons.check_circle_rounded,
            FriendRelationshipStatus.outgoingPending =>
              Icons.hourglass_top_rounded,
            FriendRelationshipStatus.incomingPending =>
              Icons.person_add_alt_1_rounded,
            FriendRelationshipStatus.none => Icons.person_add_rounded,
            FriendRelationshipStatus.self => Icons.person_rounded,
          };

          final title = switch (status) {
            FriendRelationshipStatus.friends => 'You are friends',
            FriendRelationshipStatus.outgoingPending => 'Request sent',
            FriendRelationshipStatus.incomingPending =>
              '${widget.profile.displayName} sent you a request',
            FriendRelationshipStatus.none => 'Add ${widget.profile.displayName}',
            FriendRelationshipStatus.self => 'This is your profile',
          };

          final subtitle = switch (status) {
            FriendRelationshipStatus.friends =>
              'You can see each other’s stories and plans.',
            FriendRelationshipStatus.outgoingPending =>
              'Waiting for ${widget.profile.displayName} to accept.',
            FriendRelationshipStatus.incomingPending =>
              'Accept the request to become friends.',
            FriendRelationshipStatus.none =>
              'Send a friend request to connect.',
            FriendRelationshipStatus.self => 'Manage your profile from here.',
          };

          final buttonLabel = switch (status) {
            FriendRelationshipStatus.friends => 'Friends',
            FriendRelationshipStatus.outgoingPending => 'Requested',
            FriendRelationshipStatus.incomingPending => 'Accept',
            FriendRelationshipStatus.none => 'Add Friend',
            FriendRelationshipStatus.self => 'You',
          };

          final canPress = status == FriendRelationshipStatus.none ||
              status == FriendRelationshipStatus.incomingPending;

          final variant = switch (status) {
            FriendRelationshipStatus.friends => PlanrButtonVariant.soft,
            FriendRelationshipStatus.outgoingPending => PlanrButtonVariant.soft,
            FriendRelationshipStatus.incomingPending =>
              PlanrButtonVariant.filled,
            FriendRelationshipStatus.none => PlanrButtonVariant.filled,
            FriendRelationshipStatus.self => PlanrButtonVariant.soft,
          };

          return Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: PlanrDesign.accentSoft.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                child: Icon(
                  icon,
                  color: PlanrDesign.accentDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ProfileFriendCompactButton(
                label: buttonLabel,
                variant: variant,
                isLoading: _processing,
                onPressed: !canPress || _processing
                    ? null
                    : status == FriendRelationshipStatus.incomingPending
                        ? () => _acceptRequest(relationship)
                        : _sendRequest,
              ),
            ],
          );
        },
        loading: () {
          return const SizedBox(
            height: 54,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        },
        error: (_, _) {
          return const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: PlanrDesign.accentDark,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Could not load friend status.',
                  style: TextStyle(
                    color: PlanrDesign.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileFriendCompactButton extends StatelessWidget {
  const _ProfileFriendCompactButton({
    required this.label,
    required this.variant,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final PlanrButtonVariant variant;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    final backgroundColor = switch (variant) {
      PlanrButtonVariant.filled => PlanrDesign.accent,
      PlanrButtonVariant.soft => PlanrDesign.accentSoft,
      PlanrButtonVariant.outlined => Colors.white.withValues(alpha: 0.42),
      PlanrButtonVariant.ghost => Colors.transparent,
    };

    final foregroundColor = switch (variant) {
      PlanrButtonVariant.filled => Colors.white,
      PlanrButtonVariant.soft => PlanrDesign.accentDark,
      PlanrButtonVariant.outlined => PlanrDesign.ink,
      PlanrButtonVariant.ghost => PlanrDesign.accentDark,
    };

    final borderColor = switch (variant) {
      PlanrButtonVariant.filled => PlanrDesign.accent,
      PlanrButtonVariant.soft => PlanrDesign.accentSoft,
      PlanrButtonVariant.outlined => Colors.white.withValues(alpha: 0.95),
      PlanrButtonVariant.ghost => Colors.transparent,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 86,
        maxWidth: 104,
      ),
      child: Material(
        color: disabled
            ? PlanrDesign.softMuted.withValues(alpha: 0.25)
            : backgroundColor,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: disabled
                    ? Colors.black.withValues(alpha: 0.05)
                    : borderColor,
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.1,
                      color: foregroundColor,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PublicPagesEntryCard extends StatelessWidget {
  const _PublicPagesEntryCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      radius: 28,
      color: PlanrDesign.cardLight.withValues(alpha: 0.88),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: PlanrDesign.accentDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public Pages',
                  style: TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Create and manage pages for public events.',
                  style: TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right_rounded,
            color: PlanrDesign.softMuted,
            size: 27,
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.6),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlanrDesign.pagePadding),
        child: PlanrCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.error_outline_rounded,
                color: PlanrDesign.accentDark,
                size: 36,
              ),
              SizedBox(height: 12),
              Text(
                'Could not load profile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Please try again in a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileNotFoundState extends StatelessWidget {
  const _ProfileNotFoundState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return PlanrBackground(
      variant: PlanrBackgroundVariant.profile,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(PlanrDesign.pagePadding),
              child: PlanrCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: PlanrDesign.accentSoft.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.person_off_rounded,
                        color: PlanrDesign.accentDark,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (canGoBack) ...[
                      const SizedBox(height: 20),
                      Material(
                        color: PlanrDesign.accent,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            child: const Text(
                              'Go back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}