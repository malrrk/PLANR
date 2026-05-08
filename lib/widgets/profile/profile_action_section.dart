import 'package:flutter/material.dart';

import 'profile_design.dart';

class ProfileActionSection extends StatelessWidget {
  const ProfileActionSection({
    super.key,
    required this.onEditProfile,
    required this.onFriends,
    required this.onFindFriends,
    required this.onFriendRequests,
    required this.onEventInvites,
    required this.onLogout,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onFriends;
  final VoidCallback onFindFriends;
  final VoidCallback onFriendRequests;
  final VoidCallback onEventInvites;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionCard(
          title: 'Social',
          subtitle: 'People, requests and invites',
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
            _ActionRow(
              icon: Icons.mail_rounded,
              title: 'Event invites',
              subtitle: 'Plans waiting for you',
              onTap: onEventInvites,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'Account',
          subtitle: 'Profile and session',
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
      decoration: ProfileDesign.cardDecoration(radius: 30),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ProfileDesign.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: ProfileDesign.muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
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
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? Colors.red.shade600 : ProfileDesign.primary;
    final background = danger
        ? Colors.red.shade50
        : ProfileDesign.primary.withOpacity(0.09);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF8F7FC),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
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
                          color: danger ? Colors.red.shade700 : ProfileDesign.ink,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: ProfileDesign.muted,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: danger ? Colors.red.shade300 : ProfileDesign.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}