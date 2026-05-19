import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../models/event.dart';
import '../models/event_tag.dart';
import '../providers/event_provider.dart';
import '../widgets/event_tag_chips.dart';
import 'event_detail_screen.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedTagId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setSearchQuery(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  void _toggleTag(String? tagId) {
    setState(() {
      if (_selectedTagId == tagId) {
        _selectedTagId = null;
      } else {
        _selectedTagId = tagId;
      }
    });
  }

  List<Event> _futureEvents(List<Event> events) {
    final now = DateTime.now();

    return events.where((event) {
      return event.date.isAfter(now);
    }).toList();
  }

  List<Event> _filteredEvents(List<Event> events) {
    final query = _searchQuery;
    final selectedTagId = _selectedTagId;

    return events.where((event) {
      final matchesTag = selectedTagId == null ||
          event.tags.contains(selectedTagId);

      if (!matchesTag) return false;

      if (query.isEmpty) return true;

      final tagLabels = event.tags
          .map(eventTagById)
          .whereType<EventTag>()
          .map((tag) => tag.label.toLowerCase())
          .join(' ');

      final searchableText = [
        event.title,
        event.description,
        event.address,
        event.creatorDisplayName,
        event.tags.join(' '),
        tagLabels,
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();
  }

  List<Event> _hotEvents(List<Event> events) {
    final sorted = [...events];

    sorted.sort((a, b) {
      final attendeeComparison = b.attendeeCount.compareTo(a.attendeeCount);
      if (attendeeComparison != 0) return attendeeComparison;

      return a.date.compareTo(b.date);
    });

    return sorted.take(5).toList();
  }

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: event.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return PlanrBackground(
      variant: PlanrBackgroundVariant.events,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: eventsAsync.when(
            data: (events) {
              final futureEvents = _futureEvents(events);
              final filteredEvents = _filteredEvents(futureEvents);
              final hotEvents = _hotEvents(futureEvents);

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  PlanrDesign.pagePadding,
                  18,
                  PlanrDesign.pagePadding,
                  118,
                ),
                children: [
                  const _DiscoverHeader(),
                  const SizedBox(height: 18),
                  _DiscoverSearchBar(
                    controller: _searchController,
                    onChanged: _setSearchQuery,
                  ),
                  const SizedBox(height: 16),
                  _DiscoverTagFilter(
                    selectedTagId: _selectedTagId,
                    onTagSelected: _toggleTag,
                  ),
                  const SizedBox(height: 28),
                  if (hotEvents.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Hot Events',
                      subtitle: 'Popular plans people are joining.',
                    ),
                    const SizedBox(height: 14),
                    _HotEventsStrip(
                      events: hotEvents,
                      onEventTap: _openEvent,
                    ),
                    const SizedBox(height: 30),
                  ],
                  _SectionHeader(
                    title: _selectedTagId == null && _searchQuery.isEmpty
                        ? 'Explore Events'
                        : 'Results',
                    subtitle: _resultSubtitle(filteredEvents.length),
                  ),
                  const SizedBox(height: 14),
                  if (filteredEvents.isEmpty)
                    _DiscoverEmptyState(
                      hasFilter:
                          _selectedTagId != null || _searchQuery.isNotEmpty,
                      onReset: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _selectedTagId = null;
                        });
                      },
                    )
                  else
                    ...filteredEvents.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _DiscoverEventCard(
                          event: event,
                          onTap: () => _openEvent(event),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const _DiscoverLoadingState(),
            error: (_, _) => const _DiscoverErrorState(),
          ),
        ),
      ),
    );
  }

  String _resultSubtitle(int count) {
    if (count == 0) return 'No public events found.';
    if (count == 1) return '1 public event found.';
    return '$count public events found.';
  }
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover',
          style: TextStyle(
            color: PlanrDesign.ink,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
            height: 1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Find public events, new plans and places to join.',
          style: TextStyle(
            color: PlanrDesign.muted,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _DiscoverSearchBar extends StatelessWidget {
  const _DiscoverSearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      radius: 24,
      color: PlanrDesign.cardLight.withOpacity(0.86),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: PlanrDesign.accent,
        style: const TextStyle(
          color: PlanrDesign.ink,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        decoration: const InputDecoration(
          icon: Icon(
            Icons.search_rounded,
            color: PlanrDesign.accentDark,
            size: 23,
          ),
          hintText: 'Search events, tags, places...',
          hintStyle: TextStyle(
            color: PlanrDesign.softMuted,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _DiscoverTagFilter extends StatelessWidget {
  const _DiscoverTagFilter({
    required this.selectedTagId,
    required this.onTagSelected,
  });

  final String? selectedTagId;
  final ValueChanged<String?> onTagSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: eventTags.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FilterChipButton(
              label: 'All',
              icon: Icons.explore_rounded,
              selected: selectedTagId == null,
              onTap: () => onTagSelected(null),
            );
          }

          final tag = eventTags[index - 1];

          return _FilterChipButton(
            label: tag.label,
            icon: tag.icon,
            selected: selectedTagId == tag.id,
            onTap: () => onTagSelected(tag.id),
          );
        },
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? PlanrDesign.accent
        : PlanrDesign.cardLight.withOpacity(0.86);

    final borderColor = selected
        ? PlanrDesign.accentDark.withOpacity(0.28)
        : Colors.white.withOpacity(0.94);

    final foregroundColor = selected ? Colors.white : PlanrDesign.ink;
    final iconColor = selected ? Colors.white : PlanrDesign.accentDark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: PlanrDesign.accent.withOpacity(0.22),
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
                icon,
                color: iconColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 13,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: PlanrDesign.sectionTitleStyle.copyWith(
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotEventsStrip extends StatelessWidget {
  const _HotEventsStrip({
    required this.events,
    required this.onEventTap,
  });

  final List<Event> events;
  final ValueChanged<Event> onEventTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final event = events[index];

          return _HotEventCard(
            event: event,
            onTap: () => onEventTap(event),
          );
        },
      ),
    );
  }
}

class _HotEventCard extends StatelessWidget {
  const _HotEventCard({
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final primaryTag = primaryEventTag(event.tags);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 286,
        decoration: BoxDecoration(
          color: PlanrDesign.ink,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _EventImage(event: event),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: PlanrDesign.eventOverlayGradient(),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _ImagePill(
                icon: primaryTag?.icon ??
                    Icons.local_fire_department_rounded,
                label: primaryTag?.label.toUpperCase() ?? 'HOT',
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.04,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  EventTagChips(
                    tagIds: event.tags,
                    maxVisible: 2,
                    dark: true,
                    compact: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DarkMetaLine(
                          icon: Icons.calendar_month_rounded,
                          text: _formatDate(event.date),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DarkMetaLine(
                        icon: Icons.group_rounded,
                        text: '${event.attendeeCount}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverEventCard extends StatelessWidget {
  const _DiscoverEventCard({
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      color: PlanrDesign.cardLight.withOpacity(0.84),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 108,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withOpacity(0.7),
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: _EventImage(event: event),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: SizedBox(
              height: 108,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EventTagChips(
                    tagIds: event.tags,
                    maxVisible: 2,
                    compact: true,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PlanrDesign.cardTitleStyle.copyWith(
                      fontSize: 17,
                      height: 1.08,
                    ),
                  ),
                  const Spacer(),
                  _LightMetaLine(
                    icon: Icons.calendar_month_rounded,
                    text: _formatDate(event.date),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: _LightMetaLine(
                          icon: Icons.location_on_outlined,
                          text: event.address.isEmpty
                              ? 'No location'
                              : event.address,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _GoingBadge(count: event.attendeeCount),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl?.trim();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _EventPlaceholderImage(),
      );
    }

    return const _EventPlaceholderImage();
  }
}

class _EventPlaceholderImage extends StatelessWidget {
  const _EventPlaceholderImage();

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
          size: 34,
        ),
      ),
    );
  }
}

class _ImagePill extends StatelessWidget {
  const _ImagePill({
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
        color: PlanrDesign.accent.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkMetaLine extends StatelessWidget {
  const _DarkMetaLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: PlanrDesign.eventMetaOrange,
          size: 17,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlanrDesign.eventMetaOrange,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _LightMetaLine extends StatelessWidget {
  const _LightMetaLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: PlanrDesign.eventMetaOrange,
          size: 16,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlanrDesign.eventMetaOrange,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoingBadge extends StatelessWidget {
  const _GoingBadge({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.group_rounded,
            color: PlanrDesign.accentDark,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: PlanrDesign.accentDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverEmptyState extends StatelessWidget {
  const _DiscoverEmptyState({
    required this.hasFilter,
    required this.onReset,
  });

  final bool hasFilter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(
            hasFilter
                ? Icons.manage_search_rounded
                : Icons.event_busy_rounded,
            color: PlanrDesign.accentDark,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter ? 'No matching events.' : 'No public events yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PlanrDesign.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Try another search or reset your filters.'
                : 'Public events will appear here once people start creating them.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PlanrDesign.muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset filters'),
              style: TextButton.styleFrom(
                foregroundColor: PlanrDesign.accentDark,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiscoverLoadingState extends StatelessWidget {
  const _DiscoverLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.6),
    );
  }
}

class _DiscoverErrorState extends StatelessWidget {
  const _DiscoverErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlanrDesign.pagePadding),
        child: PlanrCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.error_outline_rounded,
                color: PlanrDesign.accentDark,
                size: 34,
              ),
              SizedBox(height: 12),
              Text(
                'Could not load events.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Please try again in a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}