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

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          PlanrDesign.pagePadding,
                          18,
                          PlanrDesign.pagePadding,
                          16,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _StoriesHeader(),
                        ),
                      ),
                      if (groups.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              PlanrDesign.pagePadding,
                              18,
                              PlanrDesign.pagePadding,
                              154,
                            ),
                            child: Center(
                              child: PlanrEmptyState(
                                icon: Icons.auto_stories_rounded,
                                title: 'No stories yet',
                                subtitle:
                                    'When your friends post stories, they will show up here.',
                                actionLabel: 'Add Story',
                                onActionPressed: () =>
                                    _openCreateStory(context),
                              ),
                            ),
                          ),
                        )
                      else
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
                                final group = groups[index];
                                final latestStory = group.latestStory;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StoryViewerScreen(
                                          initialGroupId: group.groupId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final cardWidth =
                                          constraints.maxWidth * 0.94;
                                      final cardHeight =
                                          constraints.maxHeight * 0.94;

                                      return Center(
                                        child: StoryStackCard(
                                          latestStoryId: latestStory.id,
                                          latestImageUrl: latestStory.imageUrl,
                                          storyCount: group.stories.length,
                                          width: cardWidth,
                                          height: cardHeight,
                                          borderRadius: 24,
                                          showGradientOverlay: true,
                                          username: group.displayLabel,
                                          badgeTop: 10,
                                          badgeRight: 10,
                                          secondLayerOffsetX: 5,
                                          secondLayerOffsetY: 4,
                                          thirdLayerOffsetX: 9,
                                          thirdLayerOffsetY: 8,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              childCount: groups.length,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.72,
                            ),
                          ),
                        ),
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
              child: _AddStoryButton(
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
  const _StoriesHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stories',
            style: TextStyle(
              color: PlanrDesign.ink,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              height: 0.95,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Moments from your circle',
            style: TextStyle(
              color: PlanrDesign.muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStoryButton extends StatelessWidget {
  const _AddStoryButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanrDesign.backgroundButton,
      borderRadius: BorderRadius.circular(999),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.black.withOpacity(0.12),
              width: 1.2,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                color: PlanrDesign.accent,
                size: 28,
              ),
              SizedBox(width: 9),
              Text(
                'Add Story',
                style: TextStyle(
                  color: PlanrDesign.accentDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
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