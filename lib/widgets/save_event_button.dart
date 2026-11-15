import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../models/event.dart';
import '../providers/saved_events_provider.dart';

/// Round bookmark button; saved events show up under "Saved for later" on Home.
class SaveEventButton extends ConsumerWidget {
  const SaveEventButton({
    super.key,
    required this.event,
    this.size = 40,
    this.onDark = true,
  });

  final Event event;
  final double size;

  /// True when drawn on top of a photo, so it uses a translucent dark disc.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isEventSavedProvider(event.id)).value ?? false;
    final service = ref.read(savedEventsServiceProvider);
    final messenger = ScaffoldMessenger.of(context);

    Future<void> toggle() async {
      HapticFeedback.lightImpact();

      final error =
          saved ? await service.unsave(event.id) : await service.save(event);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error ?? (saved ? 'Removed from saved.' : 'Saved. Find it on Home.'),
            ),
          ),
        );
    }

    final background = onDark
        ? Colors.black.withValues(alpha: 0.32)
        : PlanrDesign.backgroundButton;
    final iconColor = saved
        ? (onDark ? PlanrDesign.storyRingEnd : PlanrDesign.accent)
        : (onDark ? Colors.white : PlanrDesign.accentDark);

    return Semantics(
      button: true,
      label: saved ? 'Remove from saved' : 'Save event',
      child: GestureDetector(
        onTap: toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              key: ValueKey(saved),
              color: iconColor,
              size: size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}
