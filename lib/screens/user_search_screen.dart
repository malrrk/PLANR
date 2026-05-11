import 'dart:async';

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
import '../providers/user_profile_provider.dart';
import 'profile_screen.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _controller = TextEditingController();

  Timer? _debounce;
  List<UserProfile> _results = [];
  bool _loading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _hasSearched = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 320), () {
      _search(query);
    });
  }

  Future<void> _search([String? forcedQuery]) async {
    final query = (forcedQuery ?? _controller.text).trim();

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    final users = await ref.read(userProfileServiceProvider).searchUsers(query);

    if (!mounted) return;

    setState(() {
      _results = users;
      _loading = false;
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();

    setState(() {
      _results = [];
      _loading = false;
      _hasSearched = false;
    });
  }

  void _openProfile(UserProfile user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: user.uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(currentFirebaseUserProvider);
    final currentUser = authState.value;

    final visibleResults = _results
        .where((user) => user.uid != currentUser?.uid)
        .toList();

    return PlanrScaffold(
      title: 'Find Friends',
      variant: PlanrBackgroundVariant.friends,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchHeader(
            controller: _controller,
            loading: _loading,
            onChanged: _onQueryChanged,
            onSubmitted: (_) => _search(),
            onClear: _controller.text.trim().isEmpty ? null : _clearSearch,
          ),
          const SizedBox(height: 16),
          if (!_hasSearched && !_loading)
            const Expanded(
              child: Center(
                child: PlanrEmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'Search by username',
                  subtitle:
                      'Start typing a username to find people on PLANR.',
                ),
              ),
            )
          else if (_loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
            )
          else if (visibleResults.isEmpty)
            const Expanded(
              child: Center(
                child: PlanrEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No users found',
                  subtitle:
                      'Try another username or check the spelling.',
                ),
              ),
            )
          else ...[
            Text(
              '${visibleResults.length} result${visibleResults.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: PlanrDesign.muted,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: visibleResults.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = visibleResults[index];

                  return _UserSearchResultCard(
                    user: user,
                    onTap: () => _openProfile(user),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.loading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool loading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(14),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discover people',
            style: TextStyle(
              color: PlanrDesign.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.55,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Search usernames and send friend requests.',
            style: TextStyle(
              color: PlanrDesign.muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: PlanrDesign.cardLight.withOpacity(0.88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: PlanrDesign.accent,
              style: const TextStyle(
                color: PlanrDesign.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Search username',
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
                suffixIcon: loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      )
                    : onClear == null
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
          ),
        ],
      ),
    );
  }
}

class _UserSearchResultCard extends ConsumerWidget {
  const _UserSearchResultCard({
    required this.user,
    required this.onTap,
  });

  final UserProfile user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationshipAsync = ref.watch(friendRelationshipProvider(user.uid));

    return PlanrCard(
      padding: EdgeInsets.zero,
      radius: 26,
      shadow: false,
      color: PlanrDesign.cardLight.withOpacity(0.74),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            PlanrAvatar(
              imageUrl: user.photoUrl,
              name: user.displayName,
              radius: 25,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
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
                    '@${user.username}',
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
            _SearchFriendActionButton(
              user: user,
              relationshipAsync: relationshipAsync,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchFriendActionButton extends ConsumerStatefulWidget {
  const _SearchFriendActionButton({
    required this.user,
    required this.relationshipAsync,
  });

  final UserProfile user;
  final AsyncValue<FriendRelationship> relationshipAsync;

  @override
  ConsumerState<_SearchFriendActionButton> createState() =>
      _SearchFriendActionButtonState();
}

class _SearchFriendActionButtonState
    extends ConsumerState<_SearchFriendActionButton> {
  bool _processing = false;

  Future<void> _sendRequest() async {
    if (_processing) return;

    setState(() {
      _processing = true;
    });

    final error = await ref.read(friendsServiceProvider).sendFriendRequest(
          toUser: widget.user,
        );

    if (!mounted) return;

    setState(() {
      _processing = false;
    });

    ref.invalidate(friendRelationshipProvider(widget.user.uid));

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
        const SnackBar(content: Text('Friend request not found.')),
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

    ref.invalidate(friendRelationshipProvider(widget.user.uid));
    ref.invalidate(myFriendsProvider);
    ref.invalidate(incomingFriendRequestsProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Friend request accepted.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.relationshipAsync.when(
      data: (relationship) {
        final status = relationship.status;

        final label = switch (status) {
          FriendRelationshipStatus.friends => 'Friends',
          FriendRelationshipStatus.outgoingPending => 'Requested',
          FriendRelationshipStatus.incomingPending => 'Accept',
          FriendRelationshipStatus.none => 'Add',
          FriendRelationshipStatus.self => 'You',
        };

        final canPress = status == FriendRelationshipStatus.none ||
            status == FriendRelationshipStatus.incomingPending;

        final variant = switch (status) {
          FriendRelationshipStatus.friends => _CompactButtonVariant.soft,
          FriendRelationshipStatus.outgoingPending => _CompactButtonVariant.soft,
          FriendRelationshipStatus.incomingPending => _CompactButtonVariant.filled,
          FriendRelationshipStatus.none => _CompactButtonVariant.filled,
          FriendRelationshipStatus.self => _CompactButtonVariant.soft,
        };

        return _CompactFriendButton(
          label: label,
          variant: variant,
          isLoading: _processing,
          onPressed: !canPress || _processing
              ? null
              : status == FriendRelationshipStatus.incomingPending
                  ? () => _acceptRequest(relationship)
                  : _sendRequest,
        );
      },
      loading: () => const _CompactFriendButton(
        label: '...',
        variant: _CompactButtonVariant.soft,
        isLoading: false,
        onPressed: null,
      ),
      error: (_, _) => const _CompactFriendButton(
        label: 'Error',
        variant: _CompactButtonVariant.soft,
        isLoading: false,
        onPressed: null,
      ),
    );
  }
}

enum _CompactButtonVariant {
  filled,
  soft,
}

class _CompactFriendButton extends StatelessWidget {
  const _CompactFriendButton({
    required this.label,
    required this.variant,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final _CompactButtonVariant variant;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    final background = switch (variant) {
      _CompactButtonVariant.filled => PlanrDesign.accent,
      _CompactButtonVariant.soft => PlanrDesign.accentSoft,
    };

    final foreground = switch (variant) {
      _CompactButtonVariant.filled => Colors.white,
      _CompactButtonVariant.soft => PlanrDesign.accentDark,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 74,
        maxWidth: 96,
      ),
      child: Material(
        color: disabled
            ? PlanrDesign.softMuted.withOpacity(0.22)
            : background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: disabled
                    ? Colors.black.withOpacity(0.05)
                    : background,
                width: 1.1,
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.1,
                      color: foreground,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color:
                            disabled ? PlanrDesign.softMuted : foreground,
                        fontSize: 13.5,
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