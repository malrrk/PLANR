import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';
import '../../models/user_profile.dart';

class ProfilePinnedMoments extends StatelessWidget {
  const ProfilePinnedMoments({
    super.key,
    required this.profile,
    this.isOwnProfile = true,
    this.onManage,
  });

  final UserProfile profile;
  final bool isOwnProfile;
  final VoidCallback? onManage;

  void _openViewer(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.88),
      builder: (_) {
        return _PinnedMomentViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinned = profile.pinnedStoryImageUrls.take(3).toList();
    final canManage = isOwnProfile && onManage != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: canManage ? onManage : null,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: PlanrDesign.cardLight.withOpacity(0.86),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
            ),
            boxShadow: [PlanrDesign.softShadow],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(canManage: canManage),
              const SizedBox(height: 5),
              Text(
                isOwnProfile
                    ? 'Your favorite memories, right on your profile.'
                    : '${profile.displayName}’s favorite memories.',
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (!isOwnProfile && pinned.isEmpty)
                const _NoPinnedMoments()
              else
                Row(
                  children: List.generate(
                    isOwnProfile ? 3 : pinned.length,
                    (index) {
                      final hasImage = index < pinned.length;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index ==
                                    (isOwnProfile ? 2 : pinned.length - 1)
                                ? 0
                                : 10,
                          ),
                          child: AspectRatio(
                            aspectRatio: 0.76,
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                onTap: hasImage
                                    ? () => _openViewer(context, pinned, index)
                                    : canManage
                                        ? onManage
                                        : null,
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.95),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.055),
                                        blurRadius: 14,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: hasImage
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              pinned[index],
                                              fit: BoxFit.cover,
                                            ),
                                            const _MomentTapGradient(),
                                          ],
                                        )
                                      : _MomentPlaceholder(index: index),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.canManage,
  });

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PlanrDesign.accentSoft.withOpacity(0.72),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: PlanrDesign.accentDark,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Pinned moments',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: PlanrDesign.ink,
            ),
          ),
        ),
        if (canManage)
          const Icon(
            Icons.chevron_right_rounded,
            color: PlanrDesign.softMuted,
            size: 25,
          ),
      ],
    );
  }
}

class _PinnedMomentViewer extends StatefulWidget {
  const _PinnedMomentViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_PinnedMomentViewer> createState() => _PinnedMomentViewerState();
}

class _PinnedMomentViewerState extends State<_PinnedMomentViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (value) {
              setState(() {
                _index = value;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Material(
              color: Colors.white.withOpacity(0.16),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_index + 1}/${widget.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
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

class _MomentTapGradient extends StatelessWidget {
  const _MomentTapGradient();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.20),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _NoPinnedMoments extends StatelessWidget {
  const _NoPinnedMoments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.46),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            color: PlanrDesign.softMuted,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No pinned moments yet.',
              style: TextStyle(
                color: PlanrDesign.muted,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
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
        colors: [
          Color(0xFFFFD6A5),
          PlanrDesign.eventMetaOrange,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      PlanrDesign.storyRingGradient,
      const LinearGradient(
        colors: [
          PlanrDesign.accentSoft,
          PlanrDesign.accent,
        ],
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Colors.white.withOpacity(0.88),
                  size: 31,
                ),
                const SizedBox(height: 6),
                Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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