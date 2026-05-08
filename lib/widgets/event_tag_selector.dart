import 'package:flutter/material.dart';

import '../models/event_tag.dart';

class EventTagSelector extends StatelessWidget {
  const EventTagSelector({
    super.key,
    required this.selectedTagIds,
    required this.onChanged,
    this.maxSelected = 3,
    this.requireAtLeastOne = false,
  });

  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onChanged;
  final int maxSelected;
  final bool requireAtLeastOne;

  void _toggleTag(BuildContext context, String tagId) {
    final current = List<String>.from(selectedTagIds);
    final isSelected = current.contains(tagId);

    if (isSelected) {
      current.remove(tagId);
      onChanged(current);
      return;
    }

    if (current.length >= maxSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can select up to $maxSelected tags.'),
        ),
      );
      return;
    }

    current.add(tagId);
    onChanged(current);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedTagIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$selectedCount/$maxSelected',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          requireAtLeastOne
              ? 'Choose at least one tag so people can discover your event.'
              : 'Choose up to $maxSelected tags.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in eventTags)
              _TagChoiceChip(
                tag: tag,
                selected: selectedTagIds.contains(tag.id),
                onTap: () => _toggleTag(context, tag.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _TagChoiceChip extends StatelessWidget {
  const _TagChoiceChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final EventTag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = Colors.deepOrange.shade600;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade300,
            width: 1.3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tag.icon,
              size: 16,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              tag.label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade800,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}