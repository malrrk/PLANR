import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/profile/profile_action_section.dart';
import '../widgets/profile/profile_empty_state.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_pinned_moments.dart';
import '../widgets/profile/profile_stats_row.dart';
import 'edit_profile_screen.dart';
import 'event_invites_screen.dart';
import 'friend_requests_screen.dart';
import 'friends_screen.dart';
import 'user_search_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _createMissingProfile(WidgetRef ref) async {
    final authState = ref.read(currentFirebaseUserProvider);
    final user = authState.value;
    if (user == null) return;

    final fallbackUsername = 'user_${user.uid.substring(0, 8)}';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return PlanrBackground(
      variant: PlanrBackgroundVariant.profile,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return ProfileEmptyState(
                  onCreateProfile: () async {
                    await _createMissingProfile(ref);
                  },
                );
              }

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
                        onEditPressed: () =>
                            _open(context, const EditProfileScreen()),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      PlanrDesign.pagePadding,
                      0,
                      PlanrDesign.pagePadding,
                      118,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          ProfileHeader(
                            profile: profile,
                            onEditPressed: () =>
                                _open(context, const EditProfileScreen()),
                          ),
                          const SizedBox(height: 16),
                          ProfileStatsRow(profile: profile),
                          const SizedBox(height: 16),
                          ProfilePinnedMoments(profile: profile),
                          const SizedBox(height: 16),
                          ProfileActionSection(
                            onEditProfile: () =>
                                _open(context, const EditProfileScreen()),
                            onFriends: () =>
                                _open(context, const FriendsScreen()),
                            onFindFriends: () =>
                                _open(context, const UserSearchScreen()),
                            onFriendRequests: () =>
                                _open(context, const FriendRequestsScreen()),
                            onEventInvites: () =>
                                _open(context, const EventInvitesScreen()),
                            onLogout: () async {
                              await ref.read(authProvider).logout();
                            },
                          ),
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
    required this.onEditPressed,
  });

  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  height: 0.95,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your PLANR identity',
                style: TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
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
                  color: Colors.black.withOpacity(0.12),
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
      ],
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