import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/story_views.dart';
import '../../core/theme/planr_design.dart';
import '../../providers/story_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../screens/create_story_screen.dart';
import '../../screens/story_viewer_screen.dart';

const _closeRing = LinearGradient(
  colors: [Color(0xFF34C77B), Color(0xFF9BE15D)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Round story avatars: Add first, then friends, followed pages and shared moments.
class HomeStoriesRow extends ConsumerWidget {
  const HomeStoriesRow({super.key});

  void _openCreateStory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
    );
  }

  void _openViewer(BuildContext context, String groupId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(initialGroupId: groupId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(friendsStoriesProvider);
    final profile = ref.watch(currentUserProfileProvider).value;
    final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid;

    final groups = storiesAsync.maybeWhen(
      data: (stories) =>
          ref.read(storyServiceProvider).groupStoriesByOwnerAndDay(stories),
      orElse: () => const <StoryGroup>[],
    );

    return SizedBox(
      height: 104,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: StoryViews.instance.viewedIds,
        builder: (context, viewed, _) {
          final ordered = [
            ...groups.where(
              (g) => !g.stories.every((s) => viewed.contains(s.id)),
            ),
            ...groups.where(
              (g) => g.stories.every((s) => viewed.contains(s.id)),
            ),
          ];

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: ordered.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _StoryItem(
                  label: 'Add story',
                  imageUrl: profile?.photoUrl,
                  name: profile?.displayName,
                  style: _RingStyle.none,
                  showPlus: true,
                  onTap: () => _openCreateStory(context),
                );
              }

              final group = ordered[index - 1];
              final seen = group.stories.every((s) => viewed.contains(s.id));
              final isClose =
                  group.stories.any((s) => s.audience == 'close');
              final isMine = group.isUserStoryGroup && group.ownerUid == myUid;

              return _StoryItem(
                label: isMine ? 'You' : group.ownerDisplayName.split(' ').first,
                imageUrl: group.ownerPhotoUrl,
                name: group.ownerDisplayName,
                isPage: group.isPageStoryGroup,
                style: seen
                    ? _RingStyle.seen
                    : isClose
                        ? _RingStyle.close
                        : _RingStyle.unseen,
                onTap: () => _openViewer(context, group.groupId),
              );
            },
          );
        },
      ),
    );
  }
}

enum _RingStyle { none, unseen, close, seen }

class _StoryItem extends StatelessWidget {
  const _StoryItem({
    required this.label,
    required this.imageUrl,
    required this.name,
    required this.style,
    required this.onTap,
    this.isPage = false,
    this.showPlus = false,
  });

  final String label;
  final String? imageUrl;
  final String? name;
  final _RingStyle style;
  final VoidCallback onTap;
  final bool isPage;
  final bool showPlus;

  static const double _size = 70;

  @override
  Widget build(BuildContext context) {
    final radius = isPage ? 24.0 : _size;

    final ringDecoration = switch (style) {
      _RingStyle.unseen => BoxDecoration(
          gradient: PlanrDesign.storyRingGradient,
          borderRadius: BorderRadius.circular(radius),
        ),
      _RingStyle.close => BoxDecoration(
          gradient: _closeRing,
          borderRadius: BorderRadius.circular(radius),
        ),
      _RingStyle.seen => BoxDecoration(
          color: Colors.black.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(radius),
        ),
      _RingStyle.none => BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
        ),
    };

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _size,
                  height: _size,
                  padding: EdgeInsets.all(style == _RingStyle.none ? 0 : 2.6),
                  decoration: ringDecoration,
                  child: Container(
                    padding: EdgeInsets.all(style == _RingStyle.none ? 0 : 2.4),
                    decoration: BoxDecoration(
                      color: PlanrDesign.backgroundTop,
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isPage ? 20 : _size),
                      child: _Face(imageUrl: imageUrl, name: name),
                    ),
                  ),
                ),
                if (showPlus)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: PlanrDesign.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PlanrDesign.backgroundTop,
                          width: 2.4,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (isPage)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: PlanrDesign.ink,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PlanrDesign.backgroundTop,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style == _RingStyle.seen
                    ? PlanrDesign.muted
                    : PlanrDesign.ink,
                fontSize: 12.5,
                fontWeight:
                    style == _RingStyle.seen ? FontWeight.w700 : FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final initial = (name?.trim().isNotEmpty ?? false)
        ? name!.trim().characters.first.toUpperCase()
        : '?';

    final fallback = Container(
      color: PlanrDesign.accentSoft,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: PlanrDesign.accentDark,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (url == null || url.isEmpty) return fallback;

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
