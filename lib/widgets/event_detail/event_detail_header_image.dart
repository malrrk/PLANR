import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';
import '../../models/event.dart';

class EventDetailHeaderImage extends StatelessWidget {
  const EventDetailHeaderImage({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: PlanrDesign.ink,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leadingWidth: 66,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _GlassIconButton(
            icon: Icons.ios_share_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing is not implemented yet.'),
                ),
              );
            },
          ),
        ),
      ],
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

              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x11000000),
                      Color(0x55000000),
                      Color(0xE6000000),
                    ],
                    stops: [0.0, 0.52, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              Positioned(
                left: 18,
                right: 18,
                bottom: 56,
                child: Row(
                  children: [
                    _HeaderBadge(
                      icon: Icons.local_fire_department_rounded,
                      label: '${event.attendeeCount} going',
                    ),
                    const SizedBox(width: 10),
                    if (event.chatEnabled)
                      const _HeaderBadge(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chat open',
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

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
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
              color: Colors.white.withOpacity(0.26),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: PlanrDesign.accentDark,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: PlanrDesign.ink,
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