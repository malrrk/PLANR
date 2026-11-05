import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';
import '../../core/widgets/planr_avatar.dart';
import '../../models/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    this.isOwnProfile = true,
  });

  final UserProfile profile;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final hasBio = profile.bio != null && profile.bio!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.95),
          width: 1.1,
        ),
        boxShadow: [PlanrDesign.softShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 185,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CoverImage(profile: profile),
                const _CoverFade(),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  _ProfileAvatar(profile: profile),
                  const SizedBox(height: 13),
                  Text(
                    profile.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1.04,
                      color: PlanrDesign.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _UsernamePill(username: profile.username),
                  const SizedBox(height: 16),
                  Text(
                    hasBio
                        ? profile.bio!.trim()
                        : isOwnProfile
                            ? 'No bio yet. Add a few words about yourself.'
                            : 'No bio yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: hasBio
                          ? PlanrDesign.muted
                          : PlanrDesign.softMuted,
                      fontSize: hasBio ? 15.5 : 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.42,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.profile,
  });

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    if (profile.backgroundImageUrl != null &&
        profile.backgroundImageUrl!.isNotEmpty) {
      return Image.network(
        profile.backgroundImageUrl!,
        fit: BoxFit.cover,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: PlanrDesign.brandGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 30,
            child: Transform.rotate(
              angle: -math.pi / 12,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 62,
                color: Colors.white.withValues(alpha: 0.34),
              ),
            ),
          ),
          Positioned(
            right: 32,
            bottom: 32,
            child: Icon(
              Icons.favorite_rounded,
              size: 56,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Center(
            child: Icon(
              Icons.waving_hand_rounded,
              size: 58,
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverFade extends StatelessWidget {
  const _CoverFade();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x22000000),
            Color(0x22000000),
            Color(0x55FFFAF3),
          ],
          stops: [0.0, 0.52, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
  });

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3.2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PlanrDesign.storyRingGradient,
        boxShadow: [
          BoxShadow(
            color: PlanrDesign.accent.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: PlanrAvatar(
          imageUrl: profile.photoUrl,
          name: profile.displayName,
          radius: 53,
        ),
      ),
    );
  }
}

class _UsernamePill extends StatelessWidget {
  const _UsernamePill({
    required this.username,
  });

  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
      child: Text(
        '@$username',
        style: const TextStyle(
          fontSize: 14,
          color: PlanrDesign.accentDark,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}