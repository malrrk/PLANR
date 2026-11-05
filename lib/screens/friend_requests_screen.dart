import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_avatar.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_empty_state.dart';
import '../core/widgets/planr_scaffold.dart';
import '../providers/friends_provider.dart';
import 'profile_screen.dart';

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  final Set<String> _processingRequestIds = {};

  void _openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: userId),
      ),
    );
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    final requestId = request['docId'] as String?;

    if (requestId == null || requestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request not found.')),
      );
      return;
    }

    if (_processingRequestIds.contains(requestId)) return;

    setState(() {
      _processingRequestIds.add(requestId);
    });

    final error = await ref.read(friendsServiceProvider).acceptFriendRequest(
          requestId: requestId,
          request: request,
        );

    if (!mounted) return;

    setState(() {
      _processingRequestIds.remove(requestId);
    });

    ref.invalidate(incomingFriendRequestsProvider);
    ref.invalidate(myFriendsProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Friend request accepted.'),
      ),
    );
  }

  Future<void> _declineRequest(String requestId) async {
    if (requestId.isEmpty || _processingRequestIds.contains(requestId)) return;
    setState(() => _processingRequestIds.add(requestId));

    String? error;
    try {
      error = await ref.read(friendsServiceProvider).declineFriendRequest(
            requestId: requestId,
          );
    } catch (_) {
      error = 'Could not decline request.';
    }

    if (!mounted) return;
    setState(() => _processingRequestIds.remove(requestId));
    if (error == null) ref.invalidate(incomingFriendRequestsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Friend request declined.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(incomingFriendRequestsProvider);

    return PlanrScaffold(
      title: 'Friend Requests',
      variant: PlanrBackgroundVariant.friends,
      child: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: PlanrEmptyState(
                icon: Icons.group_add_outlined,
                title: 'No requests right now',
                subtitle: 'New friend requests will appear here.',
              ),
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];

              final requestId = request['docId'] as String? ?? '';
              final fromUid = request['fromUid'] as String? ?? '';
              final fromDisplayName =
                  request['fromDisplayName'] as String? ?? 'User';
              final fromPhotoUrl = request['fromPhotoUrl'] as String?;

              final isProcessing = _processingRequestIds.contains(requestId);

              return _FriendRequestCard(
                displayName: fromDisplayName,
                photoUrl: fromPhotoUrl,
                isProcessing: isProcessing,
                onProfileTap: fromUid.isEmpty
                    ? null
                    : () => _openProfile(fromUid),
                onAccept: () => _acceptRequest(request),
                onDecline: () => _declineRequest(requestId),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
        error: (error, stack) => const Center(
          child: PlanrEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Requests could not load',
            subtitle:
                'Something went wrong while loading your friend requests.',
          ),
        ),
      ),
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  const _FriendRequestCard({
    required this.displayName,
    required this.photoUrl,
    required this.isProcessing,
    required this.onProfileTap,
    required this.onAccept,
    required this.onDecline,
  });

  final String displayName;
  final String? photoUrl;
  final bool isProcessing;
  final VoidCallback? onProfileTap;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: EdgeInsets.zero,
      radius: 28,
      shadow: false,
      color: PlanrDesign.cardLight.withValues(alpha: 0.76),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _TappableRequestProfile(
              displayName: displayName,
              photoUrl: photoUrl,
              onTap: onProfileTap,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
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
                        const Text(
                          'sent you a friend request',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: PlanrDesign.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Decline request',
              onPressed: isProcessing ? null : onDecline,
              icon: const Icon(Icons.close_rounded),
            ),
            _AcceptRequestButton(
              isLoading: isProcessing,
              onPressed: isProcessing ? null : onAccept,
            ),
          ],
        ),
      ),
    );
  }
}

class _TappableRequestProfile extends StatelessWidget {
  const _TappableRequestProfile({
    required this.displayName,
    required this.photoUrl,
    required this.onTap,
  });

  final String displayName;
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: PlanrAvatar(
            imageUrl: photoUrl,
            name: displayName,
            radius: 25,
          ),
        ),
      ),
    );
  }
}

class _AcceptRequestButton extends StatelessWidget {
  const _AcceptRequestButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 82,
        maxWidth: 96,
      ),
      child: Material(
        color: disabled
            ? PlanrDesign.softMuted.withValues(alpha: 0.24)
            : PlanrDesign.accent,
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
                    : PlanrDesign.accent,
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.1,
                      color: Colors.white,
                    ),
                  )
                : const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Accept',
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
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