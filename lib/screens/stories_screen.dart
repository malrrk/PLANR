import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/story_provider.dart';
import '../widgets/story_stack_card.dart';
import 'create_story_screen.dart';
import 'story_viewer_screen.dart';

class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(friendsStoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateStoryScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Story'),
      ),
      body: storiesAsync.when(
        data: (stories) {
          final groups =
              ref.read(storyServiceProvider).groupStoriesByOwnerAndDay(stories);

          if (groups.isEmpty) {
            return const Center(
              child: Text('No stories yet'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
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
                child: StoryStackCard(
                  latestStoryId: latestStory.id,
                  latestImageUrl: latestStory.imageUrl,
                  storyCount: group.stories.length,
                  width: 160,
                  height: 210,
                  borderRadius: 22,
                  showGradientOverlay: true,
                  username: group.displayLabel,
                  badgeTop: 10,
                  badgeRight: 10,
                  secondLayerOffsetX: 6,
                  secondLayerOffsetY: 5,
                  thirdLayerOffsetX: 12,
                  thirdLayerOffsetY: 10,
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (_, _) => const Center(
          child: Text('Could not load stories.'),
        ),
      ),
    );
  }
}