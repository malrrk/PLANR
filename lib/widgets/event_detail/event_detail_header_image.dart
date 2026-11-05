import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';
import '../../models/event.dart';
import '../event_tag_chips.dart';

class EventDetailHeaderImage extends StatelessWidget {
  const EventDetailHeaderImage({
    super.key,
    required this.event,
    this.onReport,
  });

  final Event event;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 420,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: PlanrDesign.backgroundBase,
      foregroundColor: PlanrDesign.ink,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leadingWidth: 66,
      actions: [
        if (onReport != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Tooltip(
                message: 'Report event',
                child: _HeaderIconButton(
                  icon: Icons.flag_outlined,
                  onTap: onReport!,
                ),
              ),
            ),
          ),
      ],
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: _HeaderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Hero(
          tag: 'event-image-${event.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                Image.network(
                  event.imageUrl!,
                  fit: BoxFit.cover,
                )
              else
                const _EventImagePlaceholder(),

              // Top shade for readable back button.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x66000000),
                      Color(0x00000000),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                  ),
                ),
              ),

              // Image fades into actual app background.
              // Image fades into the page background, not pure white.
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 230,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x00FFFBF4),
                        Color(0xBFFFF4E8),
                        Color(0xFFFFF4E8),
                      ],
                      stops: [0.0, 0.56, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: PlanrDesign.pagePadding,
                right: PlanrDesign.pagePadding,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _VisibilityBadge(visibility: event.visibility),
                        EventTagChips(
                          tagIds: event.tags,
                          maxVisible: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlanrDesign.ink,
                              fontSize: 34,
                              height: 1.02,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _GoingCountPill(
                          attendeeCount: event.attendeeCount,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.96),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: PlanrDesign.ink,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _GoingCountPill extends StatelessWidget {
  const _GoingCountPill({
    required this.attendeeCount,
  });

  final int attendeeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.96),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_alt_rounded,
            color: PlanrDesign.accentDark,
            size: 20,
          ),
          const SizedBox(height: 3),
          Text(
            attendeeCount.toString(),
            style: const TextStyle(
              color: PlanrDesign.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            'going',
            style: TextStyle(
              color: PlanrDesign.softMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({
    required this.visibility,
  });

  final String visibility;

  @override
  Widget build(BuildContext context) {
    final isPrivate = visibility == 'private';

    final backgroundColor = isPrivate
        ? Colors.orange.withValues(alpha: 0.15)
        : PlanrDesign.accentSoft.withValues(alpha: 0.78);

    final foregroundColor =
        isPrivate ? Colors.orange.shade800 : PlanrDesign.accentDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrivate ? Icons.lock_rounded : Icons.public_rounded,
            size: 15,
            color: foregroundColor,
          ),
          const SizedBox(width: 6),
          Text(
            isPrivate ? 'Private' : 'Public',
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventImagePlaceholder extends StatelessWidget {
  const _EventImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: PlanrDesign.brandGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.celebration_rounded,
          color: Colors.white,
          size: 82,
        ),
      ),
    );
  }
}