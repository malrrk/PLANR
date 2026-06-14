import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_avatar.dart';
import '../models/story.dart';
import '../providers/story_provider.dart';
import '../providers/user_profile_provider.dart';
import 'profile_screen.dart';
import 'public_page_screen.dart';

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
            return _DeleteStoryDialog(
              onCancel: () => Navigator.pop(dialogContext, false),
              onDelete: () => Navigator.pop(dialogContext, true),
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

  void _openStoryOwner(Story story) {
    if (story.isPageStory && story.pageId != null && story.pageId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicPageScreen(pageId: story.pageId!),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: story.ownerUid),
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
        return _ReplacePinnedDialog(
          pinnedUrls: pinnedUrls,
          onCancel: () => Navigator.pop(dialogContext),
          onReplace: (index) => Navigator.pop(dialogContext, index),
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (sheetContext) {
        return _StoryActionSheet(
          isPinned: isPinned,
          pinnedIsFull: pinnedUrls.length >= 3,
          onAction: (action) => Navigator.pop(sheetContext, action),
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
        profileAsync.whenOrNull(data: (profile) => profile?.pinnedStoryImageUrls) ??
            const <String>[];

    return storiesAsync.when(
      data: (stories) {
        final groups =
            ref.read(storyServiceProvider).groupStoriesByOwnerAndDay(stories);

        final currentGroup = _resolveCurrentGroup(
          stories: stories,
          groups: groups,
        );

        if (currentGroup == null || currentGroup.stories.isEmpty) {
          return const _StoryFallbackScaffold(
            icon: Icons.auto_stories_outlined,
            title: 'No stories found',
            subtitle: 'There are no active stories to show right now.',
          );
        }

        if (storyIndex >= currentGroup.stories.length) {
          storyIndex = currentGroup.stories.length - 1;
        }

        final currentStory = currentGroup.stories[storyIndex];
        final isOwnStory =
            currentStory.isUserStory && currentStory.ownerUid == currentUserUid;
        final isPinned =
            currentStory.isUserStory && pinnedUrls.contains(currentStory.imageUrl);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              _StoryImageLayer(story: currentStory),

              _StoryTapZones(
                onPrevious: () => _previousStory(groups, currentGroup),
                onNext: () => _nextStory(groups, currentGroup),
                onPreviousGroup: () => _previousGroup(groups, currentGroup),
                onNextGroup: () => _nextGroup(groups, currentGroup),
              ),

              _StoryTopOverlay(
                currentGroup: currentGroup,
                currentStory: currentStory,
                storyIndex: storyIndex,
                isOwnStory: isOwnStory,
                isPinned: isPinned,
                onProfilePressed: () => _openStoryOwner(currentStory),
                onMenuPressed: () => _showStoryMenu(
                  story: currentStory,
                  pinnedUrls: pinnedUrls,
                ),
                onClosePressed: () => Navigator.pop(context),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),

              if (isOwnStory)
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: MediaQuery.of(context).padding.bottom + 18,
                  child: _OwnStoryHint(
                    isPinned: isPinned,
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      ),
      error: (_, _) => const _StoryFallbackScaffold(
        icon: Icons.error_outline_rounded,
        title: 'Could not load stories',
        subtitle: 'Something went wrong while loading stories.',
      ),
    );
  }
}

class _StoryImageLayer extends StatelessWidget {
  const _StoryImageLayer({
    required this.story,
  });

  final Story story;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'story-image-${story.id}',
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              story.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 42,
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.40),
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.38),
                  ],
                  stops: const [0, 0.42, 1],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Center(
              child: Image.network(
                story.imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryTapZones extends StatelessWidget {
  const _StoryTapZones({
    required this.onPrevious,
    required this.onNext,
    required this.onPreviousGroup,
    required this.onNextGroup,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPreviousGroup;
  final VoidCallback onNextGroup;

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity > 150) {
      onPreviousGroup();
    } else if (velocity < -150) {
      onNextGroup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPrevious,
            onHorizontalDragEnd: _handleDragEnd,
            child: const SizedBox.expand(),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onNext,
            onHorizontalDragEnd: _handleDragEnd,
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _StoryTopOverlay extends StatelessWidget {
  const _StoryTopOverlay({
    required this.currentGroup,
    required this.currentStory,
    required this.storyIndex,
    required this.isOwnStory,
    required this.isPinned,
    required this.onProfilePressed,
    required this.onMenuPressed,
    required this.onClosePressed,
  });

  final StoryGroup currentGroup;
  final Story currentStory;
  final int storyIndex;
  final bool isOwnStory;
  final bool isPinned;
  final VoidCallback onMenuPressed;
  final VoidCallback onClosePressed;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(
          children: [
            _StoryProgressBars(
              count: currentGroup.stories.length,
              activeIndex: storyIndex,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
  child: Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      onTap: onProfilePressed,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          children: [
            PlanrAvatar(
              imageUrl: currentStory.ownerPhotoUrl,
              name: currentStory.ownerDisplayName,
              radius: 20,
              showRing: true,
            ),
            const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStory.ownerDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentGroup.dayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
                if (isPinned)
                  Container(
                    margin: const EdgeInsets.only(right: 7),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.20),
                      ),
                    ),
                    child: const Icon(
                      Icons.push_pin_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                if (isOwnStory)
                  _StoryTopButton(
                    icon: Icons.more_horiz_rounded,
                    onPressed: onMenuPressed,
                  ),
                const SizedBox(width: 6),
                _StoryTopButton(
                  icon: Icons.close_rounded,
                  onPressed: onClosePressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryProgressBars extends StatelessWidget {
  const _StoryProgressBars({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (index) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 3.5,
            margin: EdgeInsets.only(
              right: index == count - 1 ? 0 : 4,
            ),
            decoration: BoxDecoration(
              color: index <= activeIndex
                  ? Colors.white
                  : Colors.white.withOpacity(0.28),
              borderRadius: BorderRadius.circular(999),
              boxShadow: index <= activeIndex
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.20),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryTopButton extends StatelessWidget {
  const _StoryTopButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: Colors.white,
            size: 23,
          ),
        ),
      ),
    );
  }
}

class _OwnStoryHint extends StatelessWidget {
  const _OwnStoryHint({
    required this.isPinned,
  });

  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: Colors.white,
              size: 21,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                isPinned
                    ? 'Pinned to your profile'
                    : 'Open the menu to pin this moment',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryActionSheet extends StatelessWidget {
  const _StoryActionSheet({
    required this.isPinned,
    required this.pinnedIsFull,
    required this.onAction,
  });

  final bool isPinned;
  final bool pinnedIsFull;
  final ValueChanged<_StoryAction?> onAction;

  @override
  Widget build(BuildContext context) {
    final pinTitle = isPinned
        ? 'Unpin from profile'
        : pinnedIsFull
            ? 'Replace pinned moment'
            : 'Pin to profile';

    final pinSubtitle = isPinned
        ? 'Remove this story from pinned moments.'
        : pinnedIsFull
            ? 'Choose which pinned moment should be replaced.'
            : 'Show this story on your profile.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: PlanrDesign.cardLight.withOpacity(0.98),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
            ),
            boxShadow: [PlanrDesign.cardShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: PlanrDesign.softMuted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Story Options',
                  style: TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.45,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _StorySheetOption(
                icon: isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                title: pinTitle,
                subtitle: pinSubtitle,
                onTap: () => onAction(_StoryAction.pin),
              ),
              const SizedBox(height: 10),
              _StorySheetOption(
                icon: Icons.delete_outline_rounded,
                title: 'Delete story',
                subtitle: 'Remove this story permanently.',
                destructive: true,
                onTap: () => onAction(_StoryAction.delete),
              ),
              const SizedBox(height: 10),
              _StorySheetOption(
                icon: Icons.close_rounded,
                title: 'Cancel',
                subtitle: 'Go back to the story.',
                muted: true,
                onTap: () => onAction(null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorySheetOption extends StatelessWidget {
  const _StorySheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final mainColor = destructive
        ? const Color(0xFFD32F2F)
        : muted
            ? PlanrDesign.softMuted
            : PlanrDesign.accentDark;

    return Material(
      color: PlanrDesign.card.withOpacity(0.62),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.92),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: destructive
                      ? const Color(0xFFFFEBEE)
                      : PlanrDesign.accentSoft.withOpacity(muted ? 0.30 : 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
                child: Icon(
                  icon,
                  color: mainColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: destructive
                            ? const Color(0xFFD32F2F)
                            : muted
                                ? PlanrDesign.muted
                                : PlanrDesign.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: PlanrDesign.softMuted.withOpacity(0.85),
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteStoryDialog extends StatelessWidget {
  const _DeleteStoryDialog({
    required this.onCancel,
    required this.onDelete,
  });

  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: PlanrDesign.cardLight.withOpacity(0.98),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.95),
          ),
          boxShadow: [PlanrDesign.cardShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFD32F2F),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete story?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PlanrDesign.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This story will be removed from stories and from your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PlanrDesign.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Cancel',
                    onPressed: onCancel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: 'Delete',
                    destructive: true,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplacePinnedDialog extends StatelessWidget {
  const _ReplacePinnedDialog({
    required this.pinnedUrls,
    required this.onCancel,
    required this.onReplace,
  });

  final List<String> pinnedUrls;
  final VoidCallback onCancel;
  final ValueChanged<int> onReplace;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: PlanrDesign.cardLight.withOpacity(0.98),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.95),
          ),
          boxShadow: [PlanrDesign.cardShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Replace pinned moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PlanrDesign.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You already have 3 pinned moments. Choose one to replace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PlanrDesign.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(3, (index) {
                final imageUrl = pinnedUrls[index];

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => onReplace(index),
                      child: AspectRatio(
                        aspectRatio: 0.75,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.95),
                              width: 2,
                            ),
                            boxShadow: [PlanrDesign.softShadow],
                          ),
                          clipBehavior: Clip.antiAlias,
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
            const SizedBox(height: 18),
            _DialogButton(
              label: 'Cancel',
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        destructive ? const Color(0xFFD32F2F) : PlanrDesign.accentSoft;
    final foregroundColor =
        destructive ? Colors.white : PlanrDesign.accentDark;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryFallbackScaffold extends StatelessWidget {
  const _StoryFallbackScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white70,
                  size: 44,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.45,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Material(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      alignment: Alignment.center,
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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