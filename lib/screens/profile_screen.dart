import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/profile/profile_action_section.dart';
import '../widgets/profile/profile_design.dart';
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

    return Container(
      decoration: const BoxDecoration(
        gradient: ProfileDesign.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: ProfileDesign.ink,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () => _open(context, const EditProfileScreen()),
                icon: const Icon(Icons.edit_rounded),
              ),
            ),
          ],
        ),
        body: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return ProfileEmptyState(
                onCreateProfile: () async {
                  await _createMissingProfile(ref);
                },
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                ProfileHeader(
                  profile: profile,
                  onEditPressed: () =>
                      _open(context, const EditProfileScreen()),
                ),
                const SizedBox(height: 18),
                ProfileStatsRow(profile: profile),
                const SizedBox(height: 18),
                ProfilePinnedMoments(profile: profile),
                const SizedBox(height: 18),
                ProfileActionSection(
                  onEditProfile: () => _open(context, const EditProfileScreen()),
                  onFriends: () => _open(context, const FriendsScreen()),
                  onFindFriends: () => _open(context, const UserSearchScreen()),
                  onFriendRequests: () =>
                      _open(context, const FriendRequestsScreen()),
                  onEventInvites: () =>
                      _open(context, const EventInvitesScreen()),
                  onLogout: () async {
                    await ref.read(authProvider).logout();
                  },
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          error: (_, _) => const Center(
            child: Text(
              'Could not load profile.',
              style: TextStyle(
                color: ProfileDesign.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}