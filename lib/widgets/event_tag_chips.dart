import 'package:flutter/material.dart';

import '../models/event_tag.dart';

class EventTagChips extends StatelessWidget {
  const EventTagChips({
    super.key,
    required this.tagIds,
    this.maxVisible = 3,
    this.dark = false,
    this.compact = false,
  });

  final List<String> tagIds;
  final int maxVisible;
  final bool dark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tags = <EventTag>[];

    for (final id in tagIds) {
      final tag = eventTagById(id);
      if (tag != null) tags.add(tag);
      if (tags.length >= maxVisible) break;
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: [
        for (final tag in tags)
          _EventTagChip(
            tag: tag,
            dark: dark,
            compact: compact,
          ),
      ],
    );
  }
}

class _EventTagChip extends StatelessWidget {
  const _EventTagChip({
    required this.tag,
    required this.dark,
    required this.compact,
  });

  final EventTag tag;
  final bool dark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = dark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.deepOrange.withValues(alpha: 0.10);

    final borderColor = dark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.deepOrange.withValues(alpha: 0.18);

    final foregroundColor = dark ? Colors.white : Colors.deepOrange.shade700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tag.icon,
            size: compact ? 13 : 15,
            color: foregroundColor,
          ),
          const SizedBox(width: 5),
          Text(
            tag.label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: compact ? 11 : 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}