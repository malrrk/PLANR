import 'package:flutter/material.dart';

import '../core/theme/planr_design.dart';
import '../models/event_tag.dart';

class EventTagSelector extends StatefulWidget {
  const EventTagSelector({
    super.key,
    required this.selectedTagIds,
    required this.onChanged,
    this.maxSelected = 3,
    this.requireAtLeastOne = false,
    this.initiallyExpanded,
  });

  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onChanged;
  final int maxSelected;
  final bool requireAtLeastOne;

  /// If null, the selector starts expanded when no tag is selected.
  final bool? initiallyExpanded;

  @override
  State<EventTagSelector> createState() => _EventTagSelectorState();
}

class _EventTagSelectorState extends State<EventTagSelector> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded ?? false;
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  void _toggleTag(BuildContext context, String tagId) {
    final current = List<String>.from(widget.selectedTagIds);
    final isSelected = current.contains(tagId);

    if (isSelected) {
      current.remove(tagId);
      widget.onChanged(current);
      return;
    }

    if (current.length >= widget.maxSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can select up to ${widget.maxSelected} tags.'),
        ),
      );
      return;
    }

    current.add(tagId);
    widget.onChanged(current);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.selectedTagIds.length;
    final selectedTags = widget.selectedTagIds
        .map(eventTagById)
        .whereType<EventTag>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tags',
                      style: TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selectedCount > 0
                          ? PlanrDesign.accentSoft.withValues(alpha: 0.78)
                          : PlanrDesign.cardLight.withValues(alpha: 0.80),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    child: Text(
                      '$selectedCount/${widget.maxSelected}',
                      style: TextStyle(
                        color: selectedCount > 0
                            ? PlanrDesign.accentDark
                            : PlanrDesign.softMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: PlanrDesign.accentDark,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          widget.requireAtLeastOne
              ? 'Choose at least one tag so people can discover your event.'
              : 'Choose up to ${widget.maxSelected} tags.',
          style: const TextStyle(
            color: PlanrDesign.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: selectedTags.isEmpty || _expanded
              ? const SizedBox.shrink()
              : Padding(
                  key: const ValueKey('selected-tags-preview'),
                  padding: const EdgeInsets.only(top: 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 9,
                    children: [
                      for (final tag in selectedTags)
                        _TagChoiceChip(
                          tag: tag,
                          selected: true,
                          compact: true,
                          onTap: () => _toggleTag(context, tag.id),
                        ),
                    ],
                  ),
                ),
        ),

        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 9,
              children: [
                for (final tag in eventTags)
                  _TagChoiceChip(
                    tag: tag,
                    selected: widget.selectedTagIds.contains(tag.id),
                    onTap: () => _toggleTag(context, tag.id),
                  ),
              ],
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeOutCubic,
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
    this.compact = false,
  });

  final EventTag tag;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? PlanrDesign.accent
        : PlanrDesign.cardLight.withValues(alpha: 0.82);

    final borderColor = selected
        ? PlanrDesign.accentDark.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.95);

    final foregroundColor = selected ? Colors.white : PlanrDesign.ink;
    final iconColor = selected ? Colors.white : PlanrDesign.accentDark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 8 : 9,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected && !compact
                ? [
                    BoxShadow(
                      color: PlanrDesign.accent.withValues(alpha: 0.23),
                      blurRadius: 13,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tag.icon,
                size: compact ? 15 : 16,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                tag.label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: compact ? 12.5 : 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}