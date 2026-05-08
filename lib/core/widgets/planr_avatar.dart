import 'package:flutter/material.dart';

import '../theme/planr_design.dart';

class PlanrAvatar extends StatelessWidget {
  const PlanrAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24,
    this.showRing = false,
  });

  final String? imageUrl;
  final String? name;
  final double radius;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: PlanrDesign.accentSoft,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? NetworkImage(imageUrl!)
          : null,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              _initials,
              style: TextStyle(
                color: PlanrDesign.accentDark,
                fontSize: radius * 0.62,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );

    if (!showRing) return avatar;

    return Container(
      padding: const EdgeInsets.all(2.4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: PlanrDesign.storyRingGradient,
      ),
      child: avatar,
    );
  }

  String get _initials {
    final value = name?.trim();

    if (value == null || value.isEmpty) {
      return '?';
    }

    final parts = value.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}