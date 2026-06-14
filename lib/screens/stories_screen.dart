import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_empty_state.dart';
import '../providers/story_provider.dart';
import '../widgets/story_stack_card.dart';
import 'create_story_screen.dart';
import 'story_viewer_screen.dart';

class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  void _openCreateStory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateStoryScreen(),
      ),
    );
  }

  void _openStoryViewer(BuildContext context, String groupId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          initialGroupId: groupId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(friendsStoriesProvider);

    return PlanrBackground(
      variant: PlanrBackgroundVariant.home,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: storiesAsync.when(
                data: (stories) {
                  final groups = ref
                      .read(storyServiceProvider)
                      .groupStoriesByOwnerAndDay(stories);

                  final featuredGroup =
                      groups.isNotEmpty ? groups.first : null;
                  final gridGroups = groups.length > 1
                      ? groups.skip(1).toList()
                      : <StoryGroup>[];

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          PlanrDesign.pagePadding,
                          18,
                          PlanrDesign.pagePadding,
                          18,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _StoriesHeader(
                            storyCount: groups.length,
                            onCreateStory: () => _openCreateStory(context),
                          ),
                        ),
                      ),

                      if (groups.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              PlanrDesign.pagePadding,
                              10,
                              PlanrDesign.pagePadding,
                              154,
                            ),
                            child: Center(
                              child: PlanrEmptyState(
                                icon: Icons.auto_stories_rounded,
                                title: 'No stories yet',
                                subtitle:
                                  'When friends or followed pages post stories, they will show up here.',
                                actionLabel: 'Add Story',
                                onActionPressed: () =>
                                    _openCreateStory(context),
                              ),
                            ),
                          ),
                        )
                      else ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            PlanrDesign.pagePadding,
                            0,
                            PlanrDesign.pagePadding,
                            24,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _FeaturedStoryCard(
                              group: featuredGroup!,
                              onTap: () => _openStoryViewer(
                                context,
                                featuredGroup.groupId,
                              ),
                            ),
                          ),
                        ),

                        if (gridGroups.isNotEmpty) ...[
                          const SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              PlanrDesign.pagePadding,
                              0,
                              PlanrDesign.pagePadding,
                              14,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _SectionHeader(
                                title: 'More stories',
                                subtitle: 'Catch up with friends and pages',
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              PlanrDesign.pagePadding,
                              0,
                              PlanrDesign.pagePadding,
                              170,
                            ),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final group = gridGroups[index];
                                  final latestStory = group.latestStory;

                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _openStoryViewer(
                                      context,
                                      group.groupId,
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final cardWidth =
                                            constraints.maxWidth * 0.96;
                                        final cardHeight =
                                            constraints.maxHeight * 0.96;

                                        return Center(
                                          child: StoryStackCard(
                                            latestStoryId: latestStory.id,
                                            latestImageUrl:
                                                latestStory.imageUrl,
                                            storyCount: group.stories.length,
                                            width: cardWidth,
                                            height: cardHeight,
                                            borderRadius: 26,
                                            showGradientOverlay: true,
                                            username: group.displayLabel,
                                            badgeTop: 11,
                                            badgeRight: 11,
                                            secondLayerOffsetX: 5,
                                            secondLayerOffsetY: 4,
                                            thirdLayerOffsetX: 10,
                                            thirdLayerOffsetY: 8,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                                childCount: gridGroups.length,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.70,
                              ),
                            ),
                          ),
                        ] else
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 170),
                          ),
                      ],
                    ],
                  );
                },
                loading: () => const _StoriesLoadingState(),
                error: (_, _) => const _StoriesErrorState(),
              ),
            ),

            Positioned(
              right: PlanrDesign.pagePadding,
              bottom: 122,
              child: _FloatingAddStoryButton(
                onPressed: () => _openCreateStory(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoriesHeader extends StatelessWidget {
  const _StoriesHeader({
    required this.storyCount,
    required this.onCreateStory,
  });

  final int storyCount;
  final VoidCallback onCreateStory;

  @override
  Widget build(BuildContext context) {
    final subtitle = storyCount == 0
      ? 'Moments from friends and followed pages'
      : '$storyCount active ${storyCount == 1 ? 'moment' : 'moments'} from friends and pages';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stories',
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.25,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                subtitle,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        _AddStoryIconButton(
          onPressed: onCreateStory,
        ),
      ],
    );
  }
}

class _FeaturedStoryCard extends StatelessWidget {
  const _FeaturedStoryCard({
    required this.group,
    required this.onTap,
  });

  final StoryGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latestStory = group.latestStory;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 254,
        decoration: BoxDecoration(
          color: PlanrDesign.ink,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              latestStory.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _StoryImageFallback(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.02),
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.86),
                  ],
                  stops: const [0.0, 0.48, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _StoryPill(
                icon: Icons.bolt_rounded,
                label: 'LATEST MOMENT',
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _StoryCountBadge(
                count: group.stories.length,
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          group.ownerDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.9,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          group.dayLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.26),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: PlanrDesign.cardLight.withOpacity(0.74),
      radius: 24,
      shadow: false,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withOpacity(0.72),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.92),
              ),
            ),
            child: const Icon(
              Icons.collections_rounded,
              color: PlanrDesign.accentDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PlanrDesign.cardTitleStyle.copyWith(
                    fontSize: 18,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryPill extends StatelessWidget {
  const _StoryPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: PlanrDesign.accent.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCountBadge extends StatelessWidget {
  const _StoryCountBadge({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryImageFallback extends StatelessWidget {
  const _StoryImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: PlanrDesign.brandGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.auto_stories_rounded,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }
}

class _AddStoryIconButton extends StatelessWidget {
  const _AddStoryIconButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanrDesign.backgroundButton,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: PlanrDesign.backgroundButton,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withOpacity(0.12),
              width: 2.3,
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: PlanrDesign.accent,
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _FloatingAddStoryButton extends StatelessWidget {
  const _FloatingAddStoryButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanrDesign.backgroundButton,
      borderRadius: BorderRadius.circular(999),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 54,
          padding: const EdgeInsets.fromLTRB(16, 0, 19, 0),
          decoration: BoxDecoration(
            color: PlanrDesign.backgroundButton,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.black.withOpacity(0.12),
              width: 1.4,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                color: PlanrDesign.accent,
                size: 25,
              ),
              SizedBox(width: 7),
              Text(
                'Add Story',
                style: TextStyle(
                  color: PlanrDesign.accentDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoriesLoadingState extends StatelessWidget {
  const _StoriesLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.6),
    );
  }
}

class _StoriesErrorState extends StatelessWidget {
  const _StoriesErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlanrDesign.pagePadding),
        child: PlanrCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.error_outline_rounded,
                color: PlanrDesign.accentDark,
                size: 36,
              ),
              SizedBox(height: 12),
              Text(
                'Could not load stories.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Please try again in a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}