import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../models/event.dart';
import '../models/public_page.dart';
import '../providers/public_page_provider.dart';
import '../widgets/event_tag_chips.dart';
import 'event_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_event_screen.dart';
import 'edit_public_page_screen.dart';
import 'manage_page_admins_screen.dart';
import 'create_story_screen.dart';

class PublicPageScreen extends ConsumerStatefulWidget {
  const PublicPageScreen({
    super.key,
    required this.pageId,
  });

  final String pageId;

  @override
  ConsumerState<PublicPageScreen> createState() => _PublicPageScreenState();
}

class _PublicPageScreenState extends ConsumerState<PublicPageScreen> {
  bool _processingFollow = false;

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: event.id),
      ),
    );
  }

  void _openEditPage(PublicPage page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPublicPageScreen(page: page),
      ),
    );
  }

  void _openCreateEventAsPage(PublicPage page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(initialOrganizerPage: page),
      ),
    );
  }

  void _openCreateStoryAsPage(PublicPage page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateStoryScreen(page: page),
      ),
    );
  }

  void _openManageAdmins(PublicPage page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagePageAdminsScreen(pageId: page.id),
      ),
    );
  }

  Future<void> _toggleFollow({
    required PublicPage page,
    required bool isFollowing,
  }) async {
    if (_processingFollow) return;

    setState(() {
      _processingFollow = true;
    });

    final error = await ref.read(publicPageServiceProvider).toggleFollowPage(
          page: page,
          isFollowing: isFollowing,
        );

    if (!mounted) return;

    setState(() {
      _processingFollow = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (isFollowing
                  ? 'You unfollowed ${page.name}.'
                  : 'You are following ${page.name}.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(publicPageByIdProvider(widget.pageId));

    return PlanrBackground(
      variant: PlanrBackgroundVariant.events,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: pageAsync.when(
          data: (page) {
            if (page == null) {
              return const _PageNotFoundState();
            }

            final currentUid = FirebaseAuth.instance.currentUser?.uid;
            final canManage = currentUid != null &&
                (page.ownerUid == currentUid || page.adminUids.contains(currentUid));

            final isOwner = currentUid != null && page.ownerUid == currentUid;

            final followingAsync = canManage
                ? const AsyncValue.data(false)
                : ref.watch(isFollowingPageProvider(page.id));

            final eventsAsync = ref.watch(publicPageEventsProvider(page.id));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _PublicPageHeader(
                  page: page,
                  canManage: canManage,
                  followingAsync: followingAsync,
                  processingFollow: _processingFollow,
                  onBack: Navigator.of(context).canPop()
                      ? () => Navigator.pop(context)
                      : null,
                  onManage: () => _openEditPage(page),
                  onToggleFollow: (isFollowing) => _toggleFollow(
                    page: page,
                    isFollowing: isFollowing,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    PlanrDesign.pagePadding,
                    18,
                    PlanrDesign.pagePadding,
                    118,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _AboutPageCard(page: page),
                        if (canManage) ...[
                          const SizedBox(height: 16),
                          _PageManagerActionsCard(
                            page: page,
                            isOwner: isOwner,
                            onEditPage: () => _openEditPage(page),
                            onCreateEvent: () => _openCreateEventAsPage(page),
                            onCreateStory: () => _openCreateStoryAsPage(page),
                            onManageAdmins: () => _openManageAdmins(page),
                          ),
                        ],
                        const SizedBox(height: 24),
                        eventsAsync.when(
                          data: (events) {
                            return _PageEventsSection(
                              events: events,
                              onEventTap: _openEvent,
                            );
                          },
                          loading: () => const _LoadingCard(
                            title: 'Upcoming events',
                            subtitle: 'Loading events from this page...',
                          ),
                          error: (_, _) => const _SmallErrorCard(
                            title: 'Could not load page events.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const _PageLoadingState(),
          error: (_, _) => const _PageErrorState(),
        ),
      ),
    );
  }
}

class _PublicPageHeader extends StatelessWidget {
  const _PublicPageHeader({
    required this.page,
    required this.canManage,
    required this.followingAsync,
    required this.processingFollow,
    required this.onToggleFollow,
    required this.onManage,
    required this.onBack,
  });

  final PublicPage page;
  final bool canManage;
  final AsyncValue<bool> followingAsync;
  final bool processingFollow;
  final ValueChanged<bool> onToggleFollow;
  final VoidCallback onManage;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 392,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _PageHeaderBackground(page: page),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.24),
                    Colors.black.withOpacity(0.88),
                  ],
                  stops: const [0.0, 0.48, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  PlanrDesign.pagePadding,
                  12,
                  PlanrDesign.pagePadding,
                  22,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (onBack != null)
                          _CircleHeaderButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: onBack!,
                          )
                        else
                          const SizedBox(width: 46, height: 46),
                        const Spacer(),
                        if (page.isVerified)
                          const _VerifiedPill(),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _PageLogo(page: page),
                        const SizedBox(width: 15),
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
                                    fontSize: 34,
                                    height: 1.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.05,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    if (page.handle.isNotEmpty) ...[
                                      Flexible(
                                        child: Text(
                                          page.displayHandle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.78),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                    ],
                                    _DarkMiniPill(
                                      icon: Icons.group_rounded,
                                      label: _followersLabel(
                                        page.followerCount,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (canManage)
                      PlanrButton(
                        label: 'Edit Page',
                        icon: Icons.edit_rounded,
                        variant: PlanrButtonVariant.filled,
                        onPressed: onManage,
                      )
                    else
                      followingAsync.when(
                        data: (isFollowing) {
                          return PlanrButton(
                            label: isFollowing ? 'Following' : 'Follow Page',
                            icon: isFollowing
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_rounded,
                            variant: isFollowing
                                ? PlanrButtonVariant.soft
                                : PlanrButtonVariant.filled,
                            isLoading: processingFollow,
                            onPressed: processingFollow
                                ? null
                                : () => onToggleFollow(isFollowing),
                          );
                        },
                        loading: () => const PlanrButton(
                          label: 'Loading...',
                          icon: Icons.hourglass_top_rounded,
                          variant: PlanrButtonVariant.soft,
                          isLoading: true,
                          onPressed: null,
                        ),
                        error: (_, _) => PlanrButton(
                          label: 'Follow Page',
                          icon: Icons.add_circle_rounded,
                          onPressed: processingFollow
                              ? null
                              : () => onToggleFollow(false),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _followersLabel(int count) {
    if (count == 1) return '1 follower';
    return '$count followers';
  }
}

class _PageHeaderBackground extends StatelessWidget {
  const _PageHeaderBackground({
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
        errorBuilder: (_, _, _) => const _PageHeaderFallback(),
      );
    }

    return const _PageHeaderFallback();
  }
}

class _PageHeaderFallback extends StatelessWidget {
  const _PageHeaderFallback();

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
          size: 68,
        ),
      ),
    );
  }
}

class _PageLogo extends StatelessWidget {
  const _PageLogo({
    required this.page,
  });

  final PublicPage page;

  @override
  Widget build(BuildContext context) {
    final photoUrl = page.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final initial = page.name.trim().isEmpty
        ? '?'
        : page.name.trim().characters.first.toUpperCase();

    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: PlanrDesign.accentSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _LogoFallback(initial: initial),
              )
            : _LogoFallback(initial: initial),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({
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
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AboutPageCard extends StatelessWidget {
  const _AboutPageCard({
    required this.page,
  });

  final PublicPage page;

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

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(18),
      color: PlanrDesign.cardLight.withOpacity(0.86),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InfoIcon(
                icon: Icons.info_outline_rounded,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'About',
                  style: PlanrDesign.cardTitleStyle.copyWith(
                    fontSize: 21,
                    letterSpacing: -0.45,
                  ),
                ),
              ),
              _CategoryPill(
                label: _categoryLabel(page.category),
              ),
            ],
          ),
          if (page.description.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              page.description.trim(),
              style: const TextStyle(
                color: PlanrDesign.muted,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                height: 1.42,
              ),
            ),
          ],
          if (page.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            EventTagChips(
              tagIds: page.tags,
              maxVisible: 4,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _PageManagerActionsCard extends StatelessWidget {
  const _PageManagerActionsCard({
    required this.page,
    required this.isOwner,
    required this.onEditPage,
    required this.onCreateEvent,
    required this.onCreateStory,
    required this.onManageAdmins,
  });

  final PublicPage page;
  final bool isOwner;
  final VoidCallback onEditPage;
  final VoidCallback onCreateEvent;
  final VoidCallback onCreateStory;
  final VoidCallback onManageAdmins;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(18),
      color: PlanrDesign.cardLight.withOpacity(0.88),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InfoIcon(icon: Icons.admin_panel_settings_rounded),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Page management',
                  style: PlanrDesign.cardTitleStyle.copyWith(
                    fontSize: 21,
                    letterSpacing: -0.45,
                  ),
                ),
              ),
              _CategoryPill(
                label: isOwner ? 'Owner' : 'Admin',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ManagerActionTile(
                  icon: Icons.edit_rounded,
                  title: 'Edit',
                  subtitle: 'Update page',
                  onTap: onEditPage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ManagerActionTile(
                  icon: Icons.add_circle_rounded,
                  title: 'Event',
                  subtitle: 'Create event',
                  onTap: onCreateEvent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ManagerActionTile(
                  icon: Icons.auto_stories_rounded,
                  title: 'Story',
                  subtitle: 'Post as page',
                  onTap: onCreateStory,
                ),
              ),
            ],
          ),
          if (isOwner) ...[
            const SizedBox(height: 12),
            _WideManagerActionTile(
              icon: Icons.group_add_rounded,
              title: 'Manage admins',
              subtitle: 'Add or remove people who can manage this page',
              onTap: onManageAdmins,
            ),
          ],
        ],
      ),
    );
  }
}

class _ManagerActionTile extends StatelessWidget {
  const _ManagerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanrDesign.accentSoft.withOpacity(0.72),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: PlanrDesign.accentDark,
                size: 23,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlanrDesign.accentDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideManagerActionTile extends StatelessWidget {
  const _WideManagerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanrDesign.accentSoft.withOpacity(0.72),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: PlanrDesign.accentDark,
                size: 23,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlanrDesign.accentDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: PlanrDesign.accentDark,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageEventsSection extends StatelessWidget {
  const _PageEventsSection({
    required this.events,
    required this.onEventTap,
  });

  final List<Event> events;
  final ValueChanged<Event> onEventTap;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _NoPageEventsCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Upcoming events',
          subtitle:
              '${events.length} public ${events.length == 1 ? 'event' : 'events'} from this page.',
        ),
        const SizedBox(height: 14),
        for (final event in events)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PageEventCard(
              event: event,
              onTap: () => onEventTap(event),
            ),
          ),
      ],
    );
  }
}

class _PageEventCard extends StatelessWidget {
  const _PageEventCard({
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
      color: PlanrDesign.cardLight.withOpacity(0.86),
      radius: 28,
      child: Row(
        children: [
          Container(
            width: 88,
            height: 102,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withOpacity(0.72),
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: _EventImage(event: event),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: SizedBox(
              height: 102,
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
                  _MetaLine(
                    icon: Icons.calendar_month_rounded,
                    text: _formatDate(event.date),
                  ),
                  const SizedBox(height: 5),
                  _MetaLine(
                    icon: Icons.location_on_outlined,
                    text: event.address.isEmpty
                        ? 'No location'
                        : event.address,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            color: PlanrDesign.softMuted,
            size: 26,
          ),
        ],
      ),
    );
  }
}

class _NoPageEventsCard extends StatelessWidget {
  const _NoPageEventsCard();

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(22),
      color: PlanrDesign.cardLight.withOpacity(0.86),
      radius: 30,
      child: Column(
        children: [
          _InfoIcon(
            icon: Icons.event_busy_rounded,
            size: 46,
            iconSize: 23,
          ),
          const SizedBox(height: 12),
          const Text(
            'No upcoming events',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PlanrDesign.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'New public events from this page will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PlanrDesign.muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
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
          size: 30,
        ),
      ),
    );
  }
}

class _CircleHeaderButton extends StatelessWidget {
  const _CircleHeaderButton({
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
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_rounded,
            color: Colors.white,
            size: 17,
          ),
          SizedBox(width: 6),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkMiniPill extends StatelessWidget {
  const _DarkMiniPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 29,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.92),
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon({
    required this.icon,
    this.size = 42,
    this.iconSize = 21,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withOpacity(0.72),
        borderRadius: BorderRadius.circular(size * 0.38),
        border: Border.all(
          color: Colors.white.withOpacity(0.88),
        ),
      ),
      child: Icon(
        icon,
        color: PlanrDesign.accentDark,
        size: iconSize,
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withOpacity(0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: PlanrDesign.accentDark,
          fontSize: 12,
          fontWeight: FontWeight.w900,
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

class _MetaLine extends StatelessWidget {
  const _MetaLine({
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
          size: 15.5,
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(18),
      color: PlanrDesign.cardLight.withOpacity(0.86),
      radius: 30,
      child: Row(
        children: [
          const SizedBox(
            width: 23,
            height: 23,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PlanrDesign.cardTitleStyle,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: PlanrDesign.mutedBodyStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallErrorCard extends StatelessWidget {
  const _SmallErrorCard({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(18),
      color: PlanrDesign.cardLight.withOpacity(0.86),
      radius: 30,
      child: Row(
        children: [
          _InfoIcon(
            icon: Icons.error_outline_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: PlanrDesign.cardTitleStyle.copyWith(
                fontSize: 16.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageLoadingState extends StatelessWidget {
  const _PageLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.6),
    );
  }
}

class _PageErrorState extends StatelessWidget {
  const _PageErrorState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessageCard(
      icon: Icons.error_outline_rounded,
      title: 'Could not load page.',
      subtitle: 'Please try again in a moment.',
    );
  }
}

class _PageNotFoundState extends StatelessWidget {
  const _PageNotFoundState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessageCard(
      icon: Icons.search_off_rounded,
      title: 'Page not found.',
      subtitle: 'This public page may no longer be available.',
    );
  }
}

class _CenteredMessageCard extends StatelessWidget {
  const _CenteredMessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(PlanrDesign.pagePadding),
          child: PlanrCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InfoIcon(
                  icon: icon,
                  size: 58,
                  iconSize: 29,
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 20,
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
                    height: 1.35,
                  ),
                ),
                if (canGoBack) ...[
                  const SizedBox(height: 18),
                  PlanrButton(
                    label: 'Go back',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}