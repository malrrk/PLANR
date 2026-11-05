import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/story_provider.dart';
import '../../screens/create_story_screen.dart';
import '../../screens/story_viewer_screen.dart';
import '../story_stack_card.dart';
import '../../core/theme/planr_design.dart';
import 'home_empty_state_card.dart';
import 'home_error_state_card.dart';
import 'home_loading_card.dart';

class StoriesSection extends ConsumerWidget {
  const StoriesSection({
    super.key,
    this.onCreateStory,
  });

  final VoidCallback? onCreateStory;

  void _openCreateStory(BuildContext context) {
    if (onCreateStory != null) {
      onCreateStory!();
      return;
    }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Friends & Stories',
                    style: TextStyle(
                      color: PlanrDesign.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Little moments from your people',
                    style: TextStyle(
                      color: PlanrDesign.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PlanrDesign.backgroundButton,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.12), // changeable
                  width: 2.3, // changeable
                ),
              ),
              child: IconButton(
                onPressed: () => _openCreateStory(context),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.add_rounded,
                  color: PlanrDesign.accent,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        storiesAsync.when(
          data: (stories) {
            final groups =
                ref.read(storyServiceProvider).groupStoriesByOwnerAndDay(stories);

            if (groups.isEmpty) {
              return HomeEmptyStateCard(
                height: 138,
                message: 'No stories yet. Post the first one.',
                actionLabel: 'Add',
                icon: Icons.photo_camera_rounded,
                onActionPressed: () => _openCreateStory(context),
              );
            }

            return SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final latestStory = group.latestStory;

                  return GestureDetector(
                    onTap: () => _openStoryViewer(context, group.groupId),
                    child: StoryStackCard(
                      latestStoryId: latestStory.id,
                      latestImageUrl: latestStory.imageUrl,
                      storyCount: group.stories.length,
                      width: 124,
                      height: 154,
                      borderRadius: 26,
                      showGradientOverlay: true,
                      username: group.displayLabel,
                      secondLayerOffsetX: 6,
                      secondLayerOffsetY: 5,
                      thirdLayerOffsetX: 11,
                      thirdLayerOffsetY: 9,
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const HomeLoadingCard(height: 180),
          error: (_, _) => const HomeErrorStateCard(
            height: 150,
            message: 'Could not load stories.',
          ),
        ),
      ],
    );
  }
}