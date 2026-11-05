import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_empty_state.dart';
import '../core/widgets/planr_scaffold.dart';
import '../core/widgets/planr_background.dart';
import '../providers/moderation_provider.dart';
import '../providers/user_profile_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUidsProvider);

    return PlanrScaffold(
      title: 'Blocked users',
      variant: PlanrBackgroundVariant.friends,
      child: blockedAsync.when(
        data: (blocked) {
          if (blocked.isEmpty) {
            return const Center(
              child: PlanrEmptyState(
                icon: Icons.block_rounded,
                title: 'No blocked users',
                subtitle: 'People you block will show up here.',
              ),
            );
          }

          final uids = blocked.toList();

          return ListView.separated(
            itemCount: uids.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _BlockedTile(uid: uids[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: PlanrEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load',
            subtitle: 'Please try again later.',
          ),
        ),
      ),
    );
  }
}

class _BlockedTile extends ConsumerWidget {
  const _BlockedTile({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileByIdProvider(uid)).value;
    final name = profile?.displayName ?? 'Unknown user';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PlanrDesign.ink,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final error =
                  await ref.read(moderationServiceProvider).unblockUser(uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error ?? '$name is unblocked.')),
              );
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
