import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import 'profile_design.dart';

class ProfilePinnedMoments extends StatelessWidget {
  const ProfilePinnedMoments({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final pinned = profile.pinnedStoryImageUrls.take(3).toList();

    return Container(
      width: double.infinity,
      decoration: ProfileDesign.cardDecoration(radius: 30),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: ProfileDesign.secondary,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Pinned moments',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: ProfileDesign.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Your favorite memories, right on your profile.',
            style: TextStyle(
              color: ProfileDesign.muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (index) {
              final hasImage = index < pinned.length;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
                  child: AspectRatio(
                    aspectRatio: 0.75,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
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

class _MomentPlaceholder extends StatelessWidget {
  const _MomentPlaceholder({
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    final gradients = [
      const LinearGradient(
        colors: [Color(0xFFFFD6A5), Color(0xFFFF8A65)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFFFAFCC), Color(0xFF7C5CFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFA0C4FF), Color(0xFF5B8DEF)],
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