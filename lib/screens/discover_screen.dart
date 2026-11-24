import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/plan_time.dart';
import '../core/theme/planr_design.dart';
import '../core/widgets/planr_avatar.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../models/event.dart';
import '../models/event_tag.dart';
import '../models/public_page.dart';
import '../providers/event_provider.dart';
import '../providers/public_page_provider.dart';
import '../widgets/attendee_preview.dart';
import '../widgets/event_tag_chips.dart';
import '../widgets/event_cover.dart';
import '../widgets/save_event_button.dart';
import 'event_detail_screen.dart';
import 'public_page_screen.dart';
import 'profile_screen.dart';

enum _DateFilter {
  any('Any time', Icons.event_rounded),
  today('Today', Icons.today_rounded),
  tomorrow('Tomorrow', Icons.wb_sunny_rounded),
  weekend('Weekend', Icons.weekend_rounded);

  const _DateFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  bool matches(DateTime date, DateTime now) {
    switch (this) {
      case _DateFilter.any:
        return true;
      case _DateFilter.today:
        return isSameDay(date, now);
      case _DateFilter.tomorrow:
        return isSameDay(date, now.add(const Duration(days: 1)));
      case _DateFilter.weekend:
        final soon = date.difference(now).inDays < 7;
        final weekendDay = date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday ||
            (date.weekday == DateTime.friday && date.hour >= 17);
        return soon && weekendDay;
    }
  }
}

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedTagId;
  _DateFilter _dateFilter = _DateFilter.any;
    bool _filtersExpanded = false;

  bool get _hasSearch => _searchQuery.isNotEmpty;
    bool get _hasSelectedFilters =>
      _selectedTagId != null || _dateFilter != _DateFilter.any;
    bool get _hasFilter => _hasSelectedFilters || _hasSearch;

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

  void _resetFilters() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _selectedTagId = null;
      _dateFilter = _DateFilter.any;
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
    final now = DateTime.now();

    return events.where((event) {
      final matchesTag =
          selectedTagId == null || event.tags.contains(selectedTagId);

      if (!matchesTag) return false;
      if (!_dateFilter.matches(event.date, now)) return false;

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
        event.organizerDisplayName,
        event.tags.join(' '),
        tagLabels,
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();
  }

  List<PublicPage> _filteredPages(List<PublicPage> pages, List<Event> events) {
    final query = _searchQuery;
    final selectedTagId = _selectedTagId;
    final now = DateTime.now();
    final pageIdsWithEvents = events
        .where((event) => event.isOrganizedByPage)
        .where((event) => _dateFilter.matches(event.date, now))
        .map((event) => event.organizerId)
        .toSet();

    return pages.where((page) {
      final matchesTag =
          selectedTagId == null || page.tags.contains(selectedTagId);

      if (!matchesTag) return false;
      if (_dateFilter != _DateFilter.any && !pageIdsWithEvents.contains(page.id)) {
        return false;
      }

      if (query.isEmpty) return true;

      final tagLabels = page.tags
          .map(eventTagById)
          .whereType<EventTag>()
          .map((tag) => tag.label.toLowerCase())
          .join(' ');

      final searchableText = [
        page.name,
        page.handle,
        page.displayHandle,
        page.description,
        page.category,
        page.tags.join(' '),
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

  List<PublicPage> _topPages(List<PublicPage> pages) {
    final sorted = [...pages];

    sorted.sort((a, b) {
      final followerComparison = b.followerCount.compareTo(a.followerCount);
      if (followerComparison != 0) return followerComparison;

      final eventComparison = b.eventCount.compareTo(a.eventCount);
      if (eventComparison != 0) return eventComparison;

      return b.createdAt.compareTo(a.createdAt);
    });

    return _hasFilter ? sorted : sorted.take(8).toList();
  }

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: event.id),
      ),
    );
  }

  void _openPage(PublicPage page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicPageScreen(pageId: page.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final pagesAsync = ref.watch(publicPagesProvider);

    return PlanrBackground(
      variant: PlanrBackgroundVariant.events,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: eventsAsync.when(
            data: (events) {
              return pagesAsync.when(
                data: (pages) {
                  final futureEvents = _futureEvents(events);
                  final filteredEvents = _filteredEvents(futureEvents);
                  final filteredPages = _filteredPages(pages, futureEvents);
                  final hotEvents = _hotEvents(filteredEvents);
                  final topPages = _topPages(filteredPages);

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
                      Row(
                        children: [
                          Expanded(
                            child: _DiscoverSearchBar(
                              controller: _searchController,
                              onChanged: _setSearchQuery,
                              onClear: _hasSearch
                                  ? () {
                                      _searchController.clear();
                                      _setSearchQuery('');
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _DiscoverFilterToggle(
                            expanded: _filtersExpanded,
                            hasSelection: _hasSelectedFilters,
                            onTap: () => setState(
                              () => _filtersExpanded = !_filtersExpanded,
                            ),
                          ),
                        ],
                      ),
                      if (_filtersExpanded) ...[
                        const SizedBox(height: 16),
                        _DiscoverDateFilter(
                          selected: _dateFilter,
                          onSelected: (filter) =>
                              setState(() => _dateFilter = filter),
                        ),
                        const SizedBox(height: 10),
                        _DiscoverTagFilter(
                          selectedTagId: _selectedTagId,
                          onTagSelected: _toggleTag,
                        ),
                      ],
                      const SizedBox(height: 28),

                        if (topPages.isNotEmpty) ...[
                          const _SectionHeader(
                            title: 'Top Pages',
                            subtitle:
                                'Follow clubs, groups and venues around you.',
                          ),
                          const SizedBox(height: 14),
                          _PublicPagesStrip(
                            pages: topPages,
                            onPageTap: _openPage,
                          ),
                          const SizedBox(height: 30),
                        ],
                        _SectionHeader(
                          title: _eventFeedTitle(),
                          subtitle: _eventResultSubtitle(filteredEvents.length),
                        ),
                        const SizedBox(height: 14),
                        if (filteredEvents.isEmpty)
                          _DiscoverEmptyState(
                            hasFilter: _hasFilter,
                            onReset: _resetFilters,
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
                        if (hotEvents.isNotEmpty) ...[
                          const SizedBox(height: 30),
                          const _SectionHeader(
                            title: 'Hot Events',
                            subtitle: 'Popular plans people are joining.',
                          ),
                          const SizedBox(height: 14),
                          _HotEventsStrip(
                            events: hotEvents,
                            onEventTap: _openEvent,
                          ),
                        ],
                    ],
                  );
                },
                loading: () => const _DiscoverLoadingState(),
                error: (_, _) => const _DiscoverErrorState(
                  title: 'Could not load pages.',
                  subtitle: 'Please try again in a moment.',
                ),
              );
            },
            loading: () => const _DiscoverLoadingState(),
            error: (_, _) => const _DiscoverErrorState(
              title: 'Could not load events.',
              subtitle: 'Please try again in a moment.',
            ),
          ),
        ),
      ),
    );
  }

  String _eventFeedTitle() {
    final criteria = <String>[
      if (_dateFilter != _DateFilter.any) _dateFilter.label,
      if (_selectedTagId != null)
        eventTagById(_selectedTagId!)?.label ?? _selectedTagId!,
      if (_hasSearch) 'Search: ${_searchController.text.trim()}',
    ];
    return criteria.isEmpty ? 'Happening Now' : criteria.join(' · ');
  }

  String _eventResultSubtitle(int count) {
    return count == 1 ? '1 upcoming event' : '$count upcoming events';
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
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1,
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
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      radius: 24,
      color: PlanrDesign.cardLight.withValues(alpha: 0.86),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: PlanrDesign.accent,
        style: const TextStyle(
          color: PlanrDesign.ink,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          icon: const Icon(
            Icons.search_rounded,
            color: PlanrDesign.accentDark,
            size: 23,
          ),
          hintText: 'Search events, pages, tags, places...',
          hintStyle: const TextStyle(
            color: PlanrDesign.softMuted,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _DiscoverFilterToggle extends StatelessWidget {
  const _DiscoverFilterToggle({
    required this.expanded,
    required this.hasSelection,
    required this.onTap,
  });

  final bool expanded;
  final bool hasSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      expanded: expanded,
      value: hasSelection ? 'Filters active' : 'No filters selected',
      child: Stack(
        children: [
          IconButton(
            tooltip: expanded ? 'Collapse filters' : 'Expand filters',
            onPressed: onTap,
            style: IconButton.styleFrom(
              backgroundColor: PlanrDesign.backgroundButton,
              foregroundColor: PlanrDesign.accentDark,
              fixedSize: const Size(48, 48),
            ),
            icon: Icon(
              expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            ),
          ),
          if (hasSelection)
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: PlanrDesign.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiscoverDateFilter extends StatelessWidget {
  const _DiscoverDateFilter({
    required this.selected,
    required this.onSelected,
  });

  final _DateFilter selected;
  final ValueChanged<_DateFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _DateFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _DateFilter.values[index];

          return _FilterChipButton(
            label: filter.label,
            icon: filter.icon,
            selected: selected == filter,
            onTap: () => onSelected(filter),
          );
        },
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
        : PlanrDesign.cardLight.withValues(alpha: 0.86);

    final borderColor = selected
        ? PlanrDesign.accentDark.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.94);

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
                      color: PlanrDesign.accent.withValues(alpha: 0.22),
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

class _PublicPagesStrip extends StatelessWidget {
  const _PublicPagesStrip({
    required this.pages,
    required this.onPageTap,
  });

  final List<PublicPage> pages;
  final ValueChanged<PublicPage> onPageTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: pages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final page = pages[index];

          return _PublicPageStripCard(
            page: page,
            onTap: () => onPageTap(page),
          );
        },
      ),
    );
  }
}

class _PublicPageStripCard extends StatelessWidget {
  const _PublicPageStripCard({
    required this.page,
    required this.onTap,
  });

  final PublicPage page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = _categoryLabel(page.category);
    final primaryTag = primaryEventTag(page.tags);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 286,
        decoration: BoxDecoration(
          color: PlanrDesign.ink,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _PublicPageCoverImage(page: page),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: PlanrDesign.eventOverlayGradient(),
              ),
            ),

            Positioned(
              top: 14,
              left: 14,
              child: _ImagePill(
                icon: primaryTag?.icon ?? Icons.storefront_rounded,
                label: primaryTag?.label.toUpperCase() ?? category.toUpperCase(),
              ),
            ),

            if (page.isVerified)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _PublicPageLogo(
                        page: page,
                        size: 54,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                page.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  height: 1.02,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.7,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                page.displayHandle.isEmpty
                                    ? category
                                    : '${page.displayHandle} · $category',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 12.7,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (page.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    EventTagChips(
                      tagIds: page.tags,
                      maxVisible: 2,
                      dark: true,
                      compact: true,
                    ),
                  ],

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _DarkMetaLine(
                          icon: Icons.group_rounded,
                          text: _followersLabel(page.followerCount),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DarkMetaLine(
                        icon: Icons.event_rounded,
                        text: '${page.eventCount}',
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

class _PublicPageCoverImage extends StatelessWidget {
  const _PublicPageCoverImage({
    required this.page,
  });

  final PublicPage page;

  @override
  Widget build(BuildContext context) {
    final backgroundUrl = page.backgroundImageUrl?.trim();
    final photoUrl = page.photoUrl?.trim();

    final imageUrl = backgroundUrl != null && backgroundUrl.isNotEmpty
        ? backgroundUrl
        : photoUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _PublicPageCoverFallback(),
      );
    }

    return const _PublicPageCoverFallback();
  }
}

class _PublicPageCoverFallback extends StatelessWidget {
  const _PublicPageCoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: PlanrDesign.brandGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          color: Colors.white,
          size: 44,
        ),
      ),
    );
  }
}

class _PublicPageLogo extends StatelessWidget {
  const _PublicPageLogo({
    required this.page,
    required this.size,
  });

  final PublicPage page;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photoUrl = page.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final initial = page.name.trim().isEmpty
        ? '?'
        : page.name.trim().characters.first.toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(size * 0.36),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _PageInitial(initial: initial),
            )
          : _PageInitial(initial: initial),
    );
  }
}

class _PageInitial extends StatelessWidget {
  const _PageInitial({
    required this.initial,
  });

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: PlanrDesign.accentDark,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
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
              color: Colors.black.withValues(alpha: 0.16),
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
                icon: primaryTag?.icon ?? Icons.local_fire_department_rounded,
                label: primaryTag?.label.toUpperCase() ?? 'HOT',
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: SaveEventButton(event: event),
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
    final pageOrganizer = event.isOrganizedByPage;
    final organizerName = pageOrganizer
        ? event.organizerDisplayName
        : event.creatorDisplayName;
    final organizerPhoto = pageOrganizer
        ? event.organizerPhotoUrl
        : event.creatorPhotoUrl;

    return Material(
      color: PlanrDesign.ink,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 286,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'event-image-${event.id}',
              child: EventCover(imageUrl: event.imageUrl, tags: event.tags, iconSize: 58),
            ),
            const EventScrim(),
            Positioned(
              top: 14,
              left: 14,
              child: Tooltip(
                message: 'View organizer',
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => pageOrganizer
                            ? PublicPageScreen(pageId: event.organizerId)
                            : ProfileScreen(userId: event.creatorUid),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: PlanrAvatar(
                        imageUrl: organizerPhoto,
                        name: organizerName,
                        radius: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: SaveEventButton(event: event),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.04,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (event.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 29,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: EventTagChips(
                          tagIds: event.tags,
                          maxVisible: 2,
                          dark: true,
                          compact: true,
                        ),
                      ),
                    ),
                  ],
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
                      Expanded(
                        child: _DarkMetaLine(
                          icon: Icons.location_on_outlined,
                          text: event.address.isEmpty ? 'No location' : event.address,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AttendeePreview(
                    eventId: event.id,
                    attendeeCount: event.attendeeCount,
                    maxVisible: 3,
                    dark: true,
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
        color: PlanrDesign.accent.withValues(alpha: 0.94),
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
            hasFilter ? Icons.manage_search_rounded : Icons.event_busy_rounded,
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
  const _DiscoverErrorState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlanrDesign.pagePadding),
        child: PlanrCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: PlanrDesign.accentDark,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
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

String _categoryLabel(String category) {
  final normalized = category.trim().toLowerCase();

  return switch (normalized) {
    'club' => 'Club',
    'bar' => 'Bar',
    'venue' => 'Venue',
    'organization' => 'Organization',
    'collective' => 'Collective',
    'student_group' => 'Student Group',
    _ => 'Page',
  };
}

String _followersLabel(int count) {
  if (count == 1) return '1 follower';
  return '$count followers';
}