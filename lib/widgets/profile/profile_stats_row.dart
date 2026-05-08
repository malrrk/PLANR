import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import 'profile_design.dart';

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ProfileDesign.cardDecoration(radius: 30),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              label: 'Score',
              value: profile.score.toString(),
              icon: Icons.bolt_rounded,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFB86B),
                  Color(0xFFFF8A65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              label: 'Hosted',
              value: profile.hostedEventCount.toString(),
              icon: Icons.celebration_rounded,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B9A),
                  Color(0xFF7C5CFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              label: 'Joined',
              value: profile.joinedEventCount.toString(),
              icon: Icons.groups_rounded,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7C5CFF),
                  Color(0xFF5B8DEF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ProfileDesign.softBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              color: ProfileDesign.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: ProfileDesign.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}