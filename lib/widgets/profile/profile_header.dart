import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import 'profile_design.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEditPressed,
  });

  final UserProfile profile;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final hasBio = profile.bio != null && profile.bio!.trim().isNotEmpty;

    return Container(
      decoration: ProfileDesign.cardDecoration(radius: 36),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CoverImage(profile: profile),
                const _CoverOverlay(),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _FloatingEditButton(onTap: onEditPressed),
                ),
                Positioned(
                  left: -26,
                  top: -22,
                  child: _SoftOrb(
                    size: 96,
                    color: Colors.white.withOpacity(0.20),
                  ),
                ),
                Positioned(
                  right: -36,
                  bottom: 12,
                  child: _SoftOrb(
                    size: 118,
                    color: Colors.white.withOpacity(0.14),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  _Avatar(profile: profile),
                  const SizedBox(height: 12),
                  Text(
                    profile.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.9,
                      height: 1.05,
                      color: ProfileDesign.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: ProfileDesign.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '@${profile.username}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: ProfileDesign.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (hasBio) ...[
                    const SizedBox(height: 16),
                    Text(
                      profile.bio!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ProfileDesign.muted,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    const Text(
                      'No bio yet. Add a few words about yourself.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ProfileDesign.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 0),
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
    if (profile.backgroundImageUrl != null) {
      return Image.network(
        profile.backgroundImageUrl!,
        fit: BoxFit.cover,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: ProfileDesign.warmGradient,
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
                color: Colors.white.withOpacity(0.34),
              ),
            ),
          ),
          Positioned(
            right: 36,
            bottom: 34,
            child: Icon(
              Icons.favorite_rounded,
              size: 54,
              color: Colors.white.withOpacity(0.24),
            ),
          ),
          Center(
            child: Icon(
              Icons.waving_hand_rounded,
              size: 58,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverOverlay extends StatelessWidget {
  const _CoverOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x11000000),
            Color(0x66000000),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _FloatingEditButton extends StatelessWidget {
  const _FloatingEditButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.edit_rounded,
            color: ProfileDesign.ink,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.profile,
  });

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [ProfileDesign.glowShadow],
      ),
      child: CircleAvatar(
        radius: 59,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 53,
          backgroundColor: const Color(0xFFF1F2FA),
          backgroundImage:
              profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
          child: profile.photoUrl == null
              ? Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: ProfileDesign.ink,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}