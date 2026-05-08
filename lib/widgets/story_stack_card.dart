import 'package:flutter/material.dart';

class StoryStackCard extends StatelessWidget {
  const StoryStackCard({
    super.key,
    required this.latestStoryId,
    required this.latestImageUrl,
    required this.storyCount,
    required this.width,
    required this.height,
    this.borderRadius = 20,
    this.showGradientOverlay = false,
    this.username,
    this.badgeTop = 8,
    this.badgeRight = 8,
    this.secondLayerOffsetX = 6,
    this.secondLayerOffsetY = 4,
    this.thirdLayerOffsetX = 12,
    this.thirdLayerOffsetY = 8,
  });

  final String latestStoryId;
  final String latestImageUrl;
  final int storyCount;
  final double width;
  final double height;
  final double borderRadius;
  final bool showGradientOverlay;
  final String? username;
  final double badgeTop;
  final double badgeRight;
  final double secondLayerOffsetX;
  final double secondLayerOffsetY;
  final double thirdLayerOffsetX;
  final double thirdLayerOffsetY;

  @override
  Widget build(BuildContext context) {
    final hasSecondLayer = storyCount > 1;
    final hasThirdLayer = storyCount > 2;

    return SizedBox(
      width: width + thirdLayerOffsetX,
      height: height + thirdLayerOffsetY,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (hasThirdLayer)
            Positioned(
              left: thirdLayerOffsetX,
              top: thirdLayerOffsetY,
              child: _StoryStackBackgroundCard(
                width: width - 8,
                height: height - 8,
                borderRadius: borderRadius - 2,
                color: const Color(0xFFD9DDF6),
              ),
            ),
          if (hasSecondLayer)
            Positioned(
              left: secondLayerOffsetX,
              top: secondLayerOffsetY,
              child: _StoryStackBackgroundCard(
                width: width - 4,
                height: height - 4,
                borderRadius: borderRadius - 1,
                color: const Color(0xFFE8EBFA),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            child: Hero(
              tag: 'story-image-$latestStoryId',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        latestImageUrl,
                        fit: BoxFit.cover,
                      ),
                      if (showGradientOverlay || username != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                            child: username != null
                                ? Text(
                                    username!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      if (storyCount > 1)
                        Positioned(
                          top: badgeTop,
                          right: badgeRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$storyCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryStackBackgroundCard extends StatelessWidget {
  const _StoryStackBackgroundCard({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.color,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: color,
      ),
    );
  }
}