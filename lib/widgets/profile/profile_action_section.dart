import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';

class ProfileActionSection extends StatelessWidget {
  const ProfileActionSection({
    super.key,
    required this.onEditProfile,
    required this.onFriends,
    required this.onFindFriends,
    required this.onFriendRequests,
    required this.onLogout,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onFriends;
  final VoidCallback onFindFriends;
  final VoidCallback onFriendRequests;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionCard(
          title: 'Social',
          subtitle: 'People and requests',
          children: [
            _ActionRow(
              icon: Icons.people_alt_rounded,
              title: 'Friends',
              subtitle: 'See your circle',
              onTap: onFriends,
            ),
            _ActionRow(
              icon: Icons.person_search_rounded,
              title: 'Find friends',
              subtitle: 'Search by username',
              onTap: onFindFriends,
            ),
            _ActionRow(
              icon: Icons.group_add_rounded,
              title: 'Friend requests',
              subtitle: 'Accept new connections',
              onTap: onFriendRequests,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'Account',
          subtitle: 'Profile, session and safety',
          children: [
            _ActionRow(
              icon: Icons.edit_rounded,
              title: 'Edit profile',
              subtitle: 'Photo, background and bio',
              onTap: onEditProfile,
            ),
            _ActionRow(
              icon: Icons.logout_rounded,
              title: 'Log out',
              subtitle: 'Leave this device',
              danger: true,
              onTap: onLogout,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withOpacity(0.86),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
        ),
        boxShadow: [PlanrDesign.softShadow],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionCardHeader(
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ActionCardHeader extends StatelessWidget {
  const _ActionCardHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isSocial = title == 'Social';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PlanrDesign.accentSoft.withOpacity(0.72),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            isSocial
                ? Icons.groups_rounded
                : Icons.manage_accounts_rounded,
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
                title,
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
                subtitle,
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
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? Colors.red.shade600 : PlanrDesign.accentDark;
    final background = danger
        ? Colors.red.shade50
        : PlanrDesign.accentSoft.withOpacity(0.62);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withOpacity(0.46),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.92),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: danger
                              ? Colors.red.shade700
                              : PlanrDesign.ink,
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
                Icon(
                  Icons.chevron_right_rounded,
                  color: danger ? Colors.red.shade300 : PlanrDesign.softMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}