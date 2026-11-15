import 'package:flutter/material.dart';

import '../core/theme/planr_design.dart';
import '../models/event_tag.dart';

/// Event photo, or a warm gradient with the category icon when there is none.
class EventCover extends StatelessWidget {
  const EventCover({
    super.key,
    required this.imageUrl,
    this.tags = const [],
    this.iconSize = 34,
  });

  final String? imageUrl;
  final List<String> tags;
  final double iconSize;

  static const _palettes = [
    [Color(0xFFFF8A65), Color(0xFFFF6B9A)],
    [Color(0xFFFFB15E), Color(0xFFE95F75)],
    [Color(0xFFD95B28), Color(0xFF7C5CFF)],
    [Color(0xFFFF6B9A), Color(0xFF7C5CFF)],
  ];

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    final seed = tags.isEmpty ? 0 : tags.first.hashCode.abs();
    final colors = _palettes[seed % _palettes.length];
    final icon = primaryEventTag(tags)?.icon ?? Icons.celebration_rounded;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.92),
          size: iconSize,
        ),
      ),
    );
  }
}

/// Soft dark gradient so white text stays readable on any photo.
class EventScrim extends StatelessWidget {
  const EventScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: PlanrDesign.eventOverlayGradient(),
      ),
    );
  }
}
