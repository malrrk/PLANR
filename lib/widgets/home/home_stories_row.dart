import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/story_views.dart';
import '../../core/theme/planr_design.dart';
import '../../providers/firebase_providers.dart';
import '../../providers/story_provider.dart';
import '../../screens/create_story_screen.dart';
import '../../screens/story_viewer_screen.dart';
import '../story_stack_card.dart';
import 'home_error_state_card.dart';
import 'home_header.dart';
import 'home_loading_card.dart';

class HomeStoriesRow extends ConsumerWidget {
  const HomeStoriesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(friendsStoriesProvider);
    final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final groups = storiesAsync.maybeWhen(
      data: (stories) =>
          ref.read(storyServiceProvider).groupStoriesByOwnerAndDay(stories),
      orElse: () => const <StoryGroup>[],
    );

    void openCreateStory() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            HomeRoundButton(
              icon: Icons.add_rounded,
              tooltip: 'Add story',
              onTap: openCreateStory,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (groups.isNotEmpty) ...[
          SizedBox(
            height: 164,
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: StoryViews.instance.viewedIds,
              builder: (context, viewed, _) {
                final ordered = [
                  ...groups.where(
                    (group) => !group.stories.every(
                      (story) => viewed.contains(story.id),
                    ),
                  ),
                  ...groups.where(
                    (group) => group.stories.every(
                      (story) => viewed.contains(story.id),
                    ),
                  ),
                ];

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  physics: const BouncingScrollPhysics(),
                  itemCount: ordered.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final group = ordered[index];
                    final seen = group.stories.every(
                      (story) => viewed.contains(story.id),
                    );
                    final isClose = group.stories.any(
                      (story) => story.audience == 'close',
                    );
                    final isMine =
                        group.isUserStoryGroup && group.ownerUid == myUid;
                    final latest = group.latestStory;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StoryViewerScreen(initialGroupId: group.groupId),
                        ),
                      ),
                      child: Stack(
                        children: [
                          StoryStackCard(
                            latestStoryId: latest.id,
                            latestImageUrl: latest.imageUrl,
                            storyCount: group.stories.length,
                            width: 124,
                            height: 154,
                            borderRadius: 26,
                            showGradientOverlay: true,
                            username: isMine ? 'You' : group.displayLabel,
                            thirdLayerOffsetX: 11,
                            thirdLayerOffsetY: 9,
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            child: IgnorePointer(
                              child: Container(
                                width: 124,
                                height: 154,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: seen
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : isClose
                                        ? const Color(0xFF34C77B)
                                        : PlanrDesign.storyRingStart,
                                    width: seen ? 1.5 : 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ] else if (storiesAsync.hasValue) ...[
          _EmptyStoriesBanner(onTap: openCreateStory),
        ] else if (storiesAsync.hasError) ...[
          const HomeErrorStateCard(message: 'Could not load stories.'),
        ] else ...[
          const HomeLoadingCard(height: 100),
        ],
      ],
    );
  }
}

class _EmptyStoriesBanner extends StatelessWidget {
  const _EmptyStoriesBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: PlanrDesign.cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: PlanrDesign.brandGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'No stories yet. Be the first to share a moment.',
                  style: TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: PlanrDesign.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
