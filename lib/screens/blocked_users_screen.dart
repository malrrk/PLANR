import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_empty_state.dart';
import '../core/widgets/planr_scaffold.dart';
import '../core/widgets/planr_background.dart';
import '../l10n/l10n.dart';
import '../providers/moderation_provider.dart';
import '../providers/user_profile_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final blockedAsync = ref.watch(blockedUidsProvider);

    return PlanrScaffold(
      title: l10n.blockedUsersTitle,
      variant: PlanrBackgroundVariant.friends,
      child: blockedAsync.when(
        data: (blocked) {
          if (blocked.isEmpty) {
            return Center(
              child: PlanrEmptyState(
                icon: Icons.block_rounded,
                title: l10n.noBlockedUsers,
                subtitle: l10n.noBlockedUsersHint,
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
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlanrEmptyState(
                icon: Icons.error_outline_rounded,
                title: l10n.couldNotLoad,
                subtitle: l10n.tryAgainLater,
              ),
              TextButton.icon(
                onPressed: () => ref.invalidate(blockedUidsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
              ),
            ],
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
    final l10n = context.l10n;
    final profile = ref.watch(userProfileByIdProvider(uid)).value;
    final name = profile?.displayName ?? l10n.unknownUser;

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
                SnackBar(content: Text(error ?? l10n.userUnblocked(name))),
              );
            },
            child: Text(l10n.unblock),
          ),
        ],
      ),
    );
  }
}
