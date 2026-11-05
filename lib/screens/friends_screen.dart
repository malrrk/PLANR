import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_avatar.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_empty_state.dart';
import '../core/widgets/planr_scaffold.dart';
import '../models/user_profile.dart';
import '../providers/friends_provider.dart';
import 'profile_screen.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProfile(UserProfile friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: friend.uid),
      ),
    );
  }

  Future<void> _confirmRemoveFriend(UserProfile friend) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return _RemoveFriendDialog(
              friend: friend,
              onCancel: () => Navigator.pop(dialogContext, false),
              onRemove: () => Navigator.pop(dialogContext, true),
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) return;

    final error = await ref.read(friendsServiceProvider).removeFriend(
          friendUid: friend.uid,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '${friend.displayName} removed'),
      ),
    );
  }

  List<UserProfile> _filterFriends(List<UserProfile> friends) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) return friends;

    return friends.where((friend) {
      final name = friend.displayName.toLowerCase();
      final username = friend.username.toLowerCase();
      return name.contains(normalized) || username.contains(normalized);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(myFriendsProvider);

    return PlanrScaffold(
      title: 'Friends',
      variant: PlanrBackgroundVariant.friends,
      child: friendsAsync.when(
        data: (friends) {
          final filteredFriends = _filterFriends(friends);

          if (friends.isEmpty) {
            return const Center(
              child: PlanrEmptyState(
                icon: Icons.people_alt_outlined,
                title: 'No friends yet',
                subtitle:
                    'Find people by username and build your PLANR circle.',
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FriendsSearchField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                onClear: _query.isEmpty
                    ? null
                    : () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                        });
                      },
              ),
              const SizedBox(height: 16),
              Text(
                _query.trim().isEmpty
                    ? '${friends.length} friend${friends.length == 1 ? '' : 's'}'
                    : '${filteredFriends.length} result${filteredFriends.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredFriends.isEmpty
                    ? const Center(
                        child: PlanrEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matching friends',
                          subtitle:
                              'Try searching for another name or username.',
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredFriends.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final friend = filteredFriends[index];

                          return _FriendCard(
                            friend: friend,
                            onTap: () => _openProfile(friend),
                            onRemove: () => _confirmRemoveFriend(friend),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2.6),
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

class _FriendsSearchField extends StatelessWidget {
  const _FriendsSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.95),
        ),
        boxShadow: [PlanrDesign.softShadow],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: PlanrDesign.accent,
        style: const TextStyle(
          color: PlanrDesign.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Search friends',
          hintStyle: const TextStyle(
            color: PlanrDesign.softMuted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: PlanrDesign.softMuted,
            size: 22,
          ),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: PlanrDesign.softMuted,
                    size: 21,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.onTap,
    required this.onRemove,
  });

  final UserProfile friend;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: EdgeInsets.zero,
      radius: 26,
      shadow: false,
      color: PlanrDesign.cardLight.withValues(alpha: 0.74),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            PlanrAvatar(
              imageUrl: friend.photoUrl,
              name: friend.displayName,
              radius: 25,
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
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '@${friend.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PlanrDesign.muted,
                      fontSize: 13.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _RemoveFriendButton(
              onTap: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoveFriendButton extends StatelessWidget {
  const _RemoveFriendButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade50,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          child: Icon(
            Icons.person_remove_outlined,
            color: Colors.red.shade600,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _RemoveFriendDialog extends StatelessWidget {
  const _RemoveFriendDialog({
    required this.friend,
    required this.onCancel,
    required this.onRemove,
  });

  final UserProfile friend;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: PlanrCard(
        padding: const EdgeInsets.all(20),
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.person_remove_outlined,
                color: Colors.red.shade600,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Remove friend?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PlanrDesign.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Do you want to remove ${friend.displayName} from your friends?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PlanrDesign.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _DialogActionButton(
                    label: 'Cancel',
                    onTap: onCancel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogActionButton(
                    label: 'Remove',
                    destructive: true,
                    onTap: onRemove,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final background =
        destructive ? Colors.red.shade600 : PlanrDesign.accentSoft;
    final foreground =
        destructive ? Colors.white : PlanrDesign.accentDark;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: foreground,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}