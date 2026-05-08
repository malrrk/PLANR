import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story.dart';
import '../providers/story_provider.dart';
import '../providers/user_profile_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    super.key,
    this.initialGroupId,
    this.initialOwnerUid,
  }) : assert(
          initialGroupId != null || initialOwnerUid != null,
          'Either initialGroupId or initialOwnerUid must be provided.',
        );

  final String? initialGroupId;
  final String? initialOwnerUid;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  String? groupId;
  int storyIndex = 0;

  @override
  void initState() {
    super.initState();
    groupId = widget.initialGroupId;
  }

  void _nextStory(List<StoryGroup> groups, StoryGroup currentGroup) {
    if (storyIndex < currentGroup.stories.length - 1) {
      setState(() {
        storyIndex++;
      });
      return;
    }

    _nextGroup(groups, currentGroup);
  }

  void _previousStory(List<StoryGroup> groups, StoryGroup currentGroup) {
    if (storyIndex > 0) {
      setState(() {
        storyIndex--;
      });
      return;
    }

    _previousGroup(groups, currentGroup);
  }

  void _nextGroup(List<StoryGroup> groups, StoryGroup currentGroup) {
    final currentIndex =
        groups.indexWhere((group) => group.groupId == currentGroup.groupId);

    if (currentIndex < groups.length - 1) {
      setState(() {
        groupId = groups[currentIndex + 1].groupId;
        storyIndex = 0;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _previousGroup(List<StoryGroup> groups, StoryGroup currentGroup) {
    final currentIndex =
        groups.indexWhere((group) => group.groupId == currentGroup.groupId);

    if (currentIndex > 0) {
      setState(() {
        groupId = groups[currentIndex - 1].groupId;
        storyIndex = 0;
      });
    }
  }

  Future<void> _deleteStory(Story story) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete story?'),
              content: const Text(
                'This story will be removed from your profile and from stories.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    final error = await ref.read(storyServiceProvider).deleteStory(story);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Story deleted.'),
      ),
    );
  }

  Future<void> _pinStory({
    required Story story,
    required List<String> pinnedUrls,
  }) async {
    final service = ref.read(storyServiceProvider);

    if (pinnedUrls.contains(story.imageUrl)) {
      final error = await service.unpinStoryFromProfile(story);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Removed from pinned moments.'),
        ),
      );
      return;
    }

    if (pinnedUrls.length < 3) {
      final error = await service.pinStoryToProfile(story);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Pinned to your profile.'),
        ),
      );
      return;
    }

    await _showReplacePinnedDialog(
      story: story,
      pinnedUrls: pinnedUrls,
    );
  }

  Future<void> _showReplacePinnedDialog({
    required Story story,
    required List<String> pinnedUrls,
  }) async {
    final replaceIndex = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Replace pinned moment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You already have 3 pinned moments. Choose one to replace.',
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(3, (index) {
                  final imageUrl = pinnedUrls[index];

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext, index),
                        child: AspectRatio(
                          aspectRatio: 0.75,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (replaceIndex == null) return;

    final error = await ref.read(storyServiceProvider).replacePinnedStory(
          story: story,
          replaceIndex: replaceIndex,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Pinned moment replaced.'),
      ),
    );
  }

  Future<void> _showStoryMenu({
    required Story story,
    required List<String> pinnedUrls,
  }) async {
    final isPinned = pinnedUrls.contains(story.imageUrl);

    final action = await showModalBottomSheet<_StoryAction>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                ),
                title: Text(
                  isPinned
                      ? 'Unpin from profile'
                      : pinnedUrls.length >= 3
                          ? 'Replace pinned moment'
                          : 'Pin to profile',
                ),
                onTap: () {
                  Navigator.pop(sheetContext, _StoryAction.pin);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete story',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext, _StoryAction.delete);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );

    if (action == null) return;

    switch (action) {
      case _StoryAction.pin:
        await _pinStory(
          story: story,
          pinnedUrls: pinnedUrls,
        );
        break;
      case _StoryAction.delete:
        await _deleteStory(story);
        break;
    }
  }

  StoryGroup? _resolveCurrentGroup({
    required List<Story> stories,
    required List<StoryGroup> groups,
  }) {
    final service = ref.read(storyServiceProvider);

    if (groupId != null) {
      final group = service.storyGroupById(stories, groupId!);
      if (group != null) return group;
    }

    if (widget.initialOwnerUid != null) {
      final group = service.firstStoryGroupForOwner(
        stories,
        widget.initialOwnerUid!,
      );

      if (group != null) {
        groupId = group.groupId;
        return group;
      }
    }

    if (groups.isNotEmpty) {
      groupId = groups.first.groupId;
      return groups.first;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(friendsStoriesProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    final pinnedUrls =
        profileAsync.value?.pinnedStoryImageUrls ?? const <String>[];

    return storiesAsync.when(
      data: (stories) {
        final groups =
            ref.read(storyServiceProvider).groupStoriesByOwnerAndDay(stories);

        final currentGroup = _resolveCurrentGroup(
          stories: stories,
          groups: groups,
        );

        if (currentGroup == null || currentGroup.stories.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'No stories found',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        if (storyIndex >= currentGroup.stories.length) {
          storyIndex = currentGroup.stories.length - 1;
        }

        final currentStory = currentGroup.stories[storyIndex];
        final isOwnStory = currentStory.ownerUid == currentUserUid;
        final isPinned = pinnedUrls.contains(currentStory.imageUrl);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'story-image-${currentStory.id}',
                child: ColoredBox(
                  color: Colors.black,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        currentStory.imageUrl,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        color: Colors.black.withOpacity(0.35),
                      ),
                      Center(
                        child: Image.network(
                          currentStory.imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _previousStory(groups, currentGroup),
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        if (velocity > 150) {
                          _previousGroup(groups, currentGroup);
                        } else if (velocity < -150) {
                          _nextGroup(groups, currentGroup);
                        }
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _nextStory(groups, currentGroup),
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        if (velocity > 150) {
                          _previousGroup(groups, currentGroup);
                        } else if (velocity < -150) {
                          _nextGroup(groups, currentGroup);
                        }
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(
                          currentGroup.stories.length,
                          (index) => Expanded(
                            child: Container(
                              height: 3,
                              margin: EdgeInsets.only(
                                right: index == currentGroup.stories.length - 1
                                    ? 0
                                    : 4,
                              ),
                              decoration: BoxDecoration(
                                color: index <= storyIndex
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: currentStory.ownerPhotoUrl != null
                                ? NetworkImage(currentStory.ownerPhotoUrl!)
                                : null,
                            child: currentStory.ownerPhotoUrl == null
                                ? Text(
                                    currentStory.ownerDisplayName.isNotEmpty
                                        ? currentStory.ownerDisplayName.characters
                                            .first
                                            .toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentStory.ownerDisplayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  currentGroup.dayLabel,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.78),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isPinned)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.push_pin_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          if (isOwnStory)
                            IconButton(
                              onPressed: () => _showStoryMenu(
                                story: currentStory,
                                pinnedUrls: pinnedUrls,
                              ),
                              icon: const Icon(
                                Icons.more_horiz_rounded,
                                color: Colors.white,
                              ),
                            ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Could not load stories.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

enum _StoryAction {
  pin,
  delete,
}