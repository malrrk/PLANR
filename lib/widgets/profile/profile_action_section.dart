import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';
import '../../l10n/l10n.dart';

class ProfileActionSection extends StatelessWidget {
  const ProfileActionSection({
    super.key,
    required this.onFriends,
    required this.onFindFriends,
    required this.onFriendRequests,
    this.requestCount = 0,
  });

  final VoidCallback onFriends;
  final VoidCallback onFindFriends;
  final VoidCallback onFriendRequests;
  final int requestCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
        boxShadow: [PlanrDesign.softShadow],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: PlanrDesign.accentSoft.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: PlanrDesign.accentDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.socialTitle,
                      style: const TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.socialSubtitle,
                      style: const TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 13.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ActionRow(
            icon: Icons.people_alt_rounded,
            title: l10n.friendsTitle,
            subtitle: l10n.friendsSubtitle,
            onTap: onFriends,
          ),
          _ActionRow(
            icon: Icons.person_search_rounded,
            title: l10n.findFriendsTitle,
            subtitle: l10n.findFriendsSubtitle,
            onTap: onFindFriends,
          ),
          _ActionRow(
            icon: Icons.group_add_rounded,
            title: l10n.friendRequestsTitle,
            subtitle: l10n.friendRequestsSubtitle,
            onTap: onFriendRequests,
            badgeCount: requestCount,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: PlanrDesign.accentSoft.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: PlanrDesign.accentDark, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: PlanrDesign.ink,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: PlanrDesign.muted,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: PlanrDesign.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  color: PlanrDesign.softMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
