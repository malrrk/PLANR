import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';
import '../../models/user_profile.dart';

class ProfilePinnedMoments extends StatelessWidget {
  const ProfilePinnedMoments({
    super.key,
    required this.profile,
    this.isOwnProfile = true,
  });

  final UserProfile profile;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final pinned = profile.pinnedStoryImageUrls.take(3).toList();

    return Container(
      width: double.infinity,
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
          const _SectionTitle(),
          const SizedBox(height: 5),
          Text(
            isOwnProfile
                ? 'Your favorite memories, right on your profile.'
                : '${profile.displayName}’s favorite memories.',
            style: const TextStyle(
              color: PlanrDesign.muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (!isOwnProfile && pinned.isEmpty)
            const _NoPinnedMoments()
          else
            Row(
              children: List.generate(isOwnProfile ? 3 : pinned.length, (index) {
                final hasImage = index < pinned.length;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == (isOwnProfile ? 2 : pinned.length - 1)
                          ? 0
                          : 10,
                    ),
                    child: AspectRatio(
                      aspectRatio: 0.76,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.95),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.055),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasImage
                            ? Image.network(
                                pinned[index],
                                fit: BoxFit.cover,
                              )
                            : _MomentPlaceholder(index: index),
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PlanrDesign.accentSoft.withOpacity(0.72),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: PlanrDesign.accentDark,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Pinned moments',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: PlanrDesign.ink,
          ),
        ),
      ],
    );
  }
}

class _NoPinnedMoments extends StatelessWidget {
  const _NoPinnedMoments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.46),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            color: PlanrDesign.softMuted,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No pinned moments yet.',
              style: TextStyle(
                color: PlanrDesign.muted,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentPlaceholder extends StatelessWidget {
  const _MomentPlaceholder({
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    final gradients = [
      const LinearGradient(
        colors: [
          Color(0xFFFFD6A5),
          PlanrDesign.eventMetaOrange,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      PlanrDesign.storyRingGradient,
      const LinearGradient(
        colors: [
          PlanrDesign.accentSoft,
          PlanrDesign.accent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: gradients[index],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -10,
            child: Icon(
              Icons.favorite_rounded,
              size: 58,
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          Center(
            child: Icon(
              Icons.add_photo_alternate_rounded,
              color: Colors.white.withOpacity(0.88),
              size: 31,
            ),
          ),
        ],
      ),
    );
  }
}