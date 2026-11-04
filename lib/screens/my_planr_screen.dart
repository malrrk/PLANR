import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../providers/story_provider.dart';
import '../widgets/event_tag_chips.dart';
import '../widgets/home/my_event_mini_card.dart';
import 'create_story_screen.dart';
import 'event_chat_screen.dart';
import 'event_detail_screen.dart';
import 'event_invites_screen.dart';
import 'stories_screen.dart';

class MyPlanrScreen extends ConsumerStatefulWidget {
  const MyPlanrScreen({super.key});

  @override
  ConsumerState<MyPlanrScreen> createState() => _MyPlanrScreenState();
}

class _MyPlanrScreenState extends ConsumerState<MyPlanrScreen> {
  final Set<String> _processingInviteIds = {};

  void _openStories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StoriesScreen(),
      ),
    );
  }

  void _openCreateStory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateStoryScreen(),
      ),
    );
  }

  void _openInvites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EventInvitesScreen(),
      ),
    );
  }

  void _openEvent(String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: eventId),
      ),
    );
  }

  void _openEventChat(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventChatScreen(event: event),
      ),
    );
  }

  Future<void> _acceptInvite(String eventId) async {
    if (_processingInviteIds.contains(eventId)) return;

    setState(() {
      _processingInviteIds.add(eventId);
    });

    final error = await ref
        .read(eventServiceProvider)
        .acceptEventInvite(eventId: eventId);

    if (!mounted) return;

    setState(() {
      _processingInviteIds.remove(eventId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Invite accepted.'),
      ),
    );
  }

  Future<void> _declineInvite(String eventId) async {
    if (_processingInviteIds.contains(eventId)) return;

    setState(() {
      _processingInviteIds.add(eventId);
    });

    final error = await ref
        .read(eventServiceProvider)
        .declineEventInvite(eventId: eventId);

    if (!mounted) return;

    setState(() {
      _processingInviteIds.remove(eventId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Invite declined.'),
      ),
    );
  }

  List<Event> _futureEvents(List<Event> events) {
    final now = DateTime.now();

    return events.where((event) => event.date.isAfter(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(friendsStoriesProvider);
    final invitesAsync = ref.watch(myEventInvitesProvider);
    final myEventsAsync = ref.watch(myEventsProvider);

    return PlanrBackground(
      variant: PlanrBackgroundVariant.profile,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              PlanrDesign.pagePadding,
              18,
              PlanrDesign.pagePadding,
              118,
            ),
            children: [
              const _MyPlanrHeader(),
              const SizedBox(height: 20),
              storiesAsync.when(
                data: (stories) {
                  final groups = ref
                      .read(storyServiceProvider)
                      .groupStoriesByOwnerAndDay(stories);

                  return _StoriesPreviewCard(
                    groups: groups,
                    onOpenStories: _openStories,
                    onAddStory: _openCreateStory,
                  );
                },
                loading: () => const _LoadingCard(
                  title: 'Stories',
                  subtitle: 'Loading moments from your circle...',
                ),
                error: (_, _) => _SmallErrorCard(
                  title: 'Could not load stories.',
                  onTap: _openStories,
                ),
              ),
              const SizedBox(height: 24),
              invitesAsync.when(
                data: (invites) {
                  return _InvitePreviewSection(
                    invites: invites,
                    processingInviteIds: _processingInviteIds,
                    onOpenAll: _openInvites,
                    onOpenEvent: _openEvent,
                    onAccept: _acceptInvite,
                    onDecline: _declineInvite,
                  );
                },
                loading: () => const _LoadingCard(
                  title: 'Invites',
                  subtitle: 'Checking your open invitations...',
                ),
                error: (_, _) => _SmallErrorCard(
                  title: 'Could not load invites.',
                  onTap: _openInvites,
                ),
              ),
              const SizedBox(height: 26),
              myEventsAsync.when(
                data: (events) {
                  final upcomingEvents = _futureEvents(events);

                  return _PlansSection(
                    events: upcomingEvents,
                    onOpenEvent: _openEvent,
                    onOpenChat: _openEventChat,
                  );
                },
                loading: () => const _LoadingCard(
                  title: 'Your plans',
                  subtitle: 'Loading your upcoming plans...',
                ),
                error: (_, _) => const _SmallErrorCard(
                  title: 'Could not load your plans.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyPlanrHeader extends StatelessWidget {
  const _MyPlanrHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Planr',
          style: TextStyle(
            color: PlanrDesign.ink,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.15,
            height: 1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Your stories, invites and upcoming plans.',
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

class _StoriesPreviewCard extends StatelessWidget {
  const _StoriesPreviewCard({
    required this.groups,
    required this.onOpenStories,
    required this.onAddStory,
  });

  final List<StoryGroup> groups;
  final VoidCallback onOpenStories;
  final VoidCallback onAddStory;

  @override
  Widget build(BuildContext context) {
    final visibleGroups = groups.take(4).toList();

    return PlanrCard(
      onTap: onOpenStories,
      padding: const EdgeInsets.all(18),
      color: PlanrDesign.cardLight.withOpacity(0.88),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBubble(
                icon: Icons.auto_stories_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stories',
                      style: PlanrDesign.cardTitleStyle.copyWith(
                        fontSize: 21,
                        letterSpacing: -0.45,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      visibleGroups.isEmpty
                          ? 'No active stories yet.'
                          : '${groups.length} active ${groups.length == 1 ? 'moment' : 'moments'} from your circle.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _CirclePlusButton(
                onTap: onAddStory,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleGroups.isEmpty)
            const Text(
              'Tap here to open stories, or use the plus button to add your own.',
              style: PlanrDesign.mutedBodyStyle,
            )
          else
            SizedBox(
              height: 84,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < visibleGroups.length; i++)
                    Positioned(
                      left: i * 52,
                      child: _StoryPreviewThumb(
                        group: visibleGroups[i],
                      ),
                    ),
                  Positioned(
                    right: 0,
                    top: 22,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.78),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: PlanrDesign.softMuted,
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryPreviewThumb extends StatelessWidget {
  const _StoryPreviewThumb({
    required this.group,
  });

  final StoryGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 84,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: PlanrDesign.storyRingGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: PlanrDesign.cardLight,
          borderRadius: BorderRadius.circular(21),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              group.latestStory.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: PlanrDesign.accentSoft,
                child: Icon(
                  Icons.image_not_supported_rounded,
                  color: PlanrDesign.accentDark,
                  size: 24,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                group.ownerDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitePreviewSection extends StatelessWidget {
  const _InvitePreviewSection({
    required this.invites,
    required this.processingInviteIds,
    required this.onOpenAll,
    required this.onOpenEvent,
    required this.onAccept,
    required this.onDecline,
  });

  final List<Map<String, dynamic>> invites;
  final Set<String> processingInviteIds;
  final VoidCallback onOpenAll;
  final ValueChanged<String> onOpenEvent;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onDecline;

  @override
  Widget build(BuildContext context) {
    final pendingInvites = invites
        .where(
          (invite) => (invite['status'] as String? ?? 'pending') == 'pending',
        )
        .toList();

    final declinedInvites = invites
      .where(
        (invite) => (invite['status'] as String?) == 'declined',
      )
      .toList();

    if (pendingInvites.isEmpty && declinedInvites.isEmpty) {
      return const SizedBox.shrink();
    }

    final visiblePendingInvites = pendingInvites.take(2).toList();
    final visibleDeclinedInvites = declinedInvites.take(2).toList();
    final hiddenInviteCount =
        invites.length - visiblePendingInvites.length - visibleDeclinedInvites.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Invites',
          subtitle: pendingInvites.isNotEmpty
              ? '${pendingInvites.length} open ${pendingInvites.length == 1 ? 'invitation' : 'invitations'} waiting.'
              : '${declinedInvites.length} declined ${declinedInvites.length == 1 ? 'invite' : 'invites'} you can still accept.',
          actionLabel: hiddenInviteCount > 0 ? 'View all' : null,
          onActionTap: hiddenInviteCount > 0 ? onOpenAll : null,
        ),
        const SizedBox(height: 14),
        for (final invite in visiblePendingInvites)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InvitePreviewCard(
              invite: invite,
              isDeclined: false,
              isProcessing: processingInviteIds.contains(
                invite['eventId'] as String?,
              ),
              onOpenEvent: onOpenEvent,
              onAccept: onAccept,
              onDecline: onDecline,
            ),
          ),
        if (visibleDeclinedInvites.isNotEmpty) ...[
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Declined invites',
              style: TextStyle(
                color: PlanrDesign.muted,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final invite in visibleDeclinedInvites)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InvitePreviewCard(
                invite: invite,
                isDeclined: true,
                isProcessing: processingInviteIds.contains(
                  invite['eventId'] as String?,
                ),
                onOpenEvent: onOpenEvent,
                onAccept: onAccept,
                onDecline: onDecline,
              ),
            ),
        ],
      ],
    );
  }
}

class _InvitePreviewCard extends StatelessWidget {
  const _InvitePreviewCard({
    required this.invite,
    required this.isDeclined,
    required this.isProcessing,
    required this.onOpenEvent,
    required this.onAccept,
    required this.onDecline,
  });

  final Map<String, dynamic> invite;
  final bool isDeclined;
  final bool isProcessing;
  final ValueChanged<String> onOpenEvent;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onDecline;

  DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unknown';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final eventId = invite['eventId'] as String? ?? '';
    final title = invite['eventTitle'] as String? ?? 'Event invite';
    final invitedBy = invite['invitedByDisplayName'] as String? ?? 'someone';
    final address = invite['eventAddress'] as String? ?? 'No location';
    final imageUrl = (invite['eventImageUrl'] as String?)?.trim();
    final date = _dateFromValue(invite['eventDate']);
    final tagIds = List<String>.from(invite['eventTags'] as List? ?? const []);

    return PlanrCard(
      padding: const EdgeInsets.all(12),
      color: PlanrDesign.cardLight.withOpacity(
        isDeclined ? 0.74 : 0.88,
      ),
      radius: 28,
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 76,
                    height: 88,
                    decoration: BoxDecoration(
                      color: PlanrDesign.accentSoft.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const _EventPlaceholderSmall(),
                          )
                        : const _EventPlaceholderSmall(),
                  ),
                  if (isDeclined)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.38),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: SizedBox(
                  height: 88,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDeclined
                            ? 'You declined this invite'
                            : '$invitedBy invited you',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDeclined
                              ? PlanrDesign.softMuted
                              : PlanrDesign.accentDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PlanrDesign.cardTitleStyle.copyWith(
                          fontSize: 17.5,
                          height: 1.08,
                          color: isDeclined
                              ? PlanrDesign.ink.withOpacity(0.74)
                              : PlanrDesign.ink,
                        ),
                      ),
                      const Spacer(),
                      _MiniMetaLine(
                        icon: Icons.calendar_month_rounded,
                        text: _formatDate(date),
                      ),
                      const SizedBox(height: 4),
                      _MiniMetaLine(
                        icon: Icons.location_on_outlined,
                        text: address,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (tagIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: EventTagChips(
                tagIds: tagIds,
                maxVisible: 3,
                compact: true,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PlanrButton(
                  label: 'Details',
                  icon: Icons.visibility_rounded,
                  variant: PlanrButtonVariant.outlined,
                  onPressed: eventId.isEmpty
                      ? null
                      : () => onOpenEvent(eventId),
                ),
              ),
              const SizedBox(width: 8),
              if (!isDeclined) ...[
                Expanded(
                  child: PlanrButton(
                    label: 'Decline',
                    icon: Icons.close_rounded,
                    variant: PlanrButtonVariant.outlined,
                    onPressed: isProcessing || eventId.isEmpty
                        ? null
                        : () => onDecline(eventId),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: PlanrButton(
                  label: isDeclined ? 'Accept now' : 'Accept',
                  icon: Icons.check_rounded,
                  isLoading: isProcessing,
                  onPressed: isProcessing || eventId.isEmpty
                      ? null
                      : () => onAccept(eventId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlansSection extends StatelessWidget {
  const _PlansSection({
    required this.events,
    required this.onOpenEvent,
    required this.onOpenChat,
  });

  final List<Event> events;
  final ValueChanged<String> onOpenEvent;
  final ValueChanged<Event> onOpenChat;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _NoPlansCard();
    }

    final nextPlan = events.first;
    final upcomingPlans = events.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Your next plan',
          subtitle: 'The next thing on your calendar.',
        ),
        const SizedBox(height: 14),
        _NextPlanCard(
          event: nextPlan,
          onTap: () => onOpenEvent(nextPlan.id),
        ),
        if (upcomingPlans.isNotEmpty) ...[
          const SizedBox(height: 28),
          _SectionHeader(
            title: 'Upcoming plans',
            subtitle:
                '${upcomingPlans.length} more ${upcomingPlans.length == 1 ? 'plan' : 'plans'} coming up.',
          ),
          const SizedBox(height: 14),
          for (final event in upcomingPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MyEventMiniCard(
                event: event,
                onTap: () => onOpenEvent(event.id),
                onChatTap: event.chatEnabled
                    ? () => onOpenChat(event)
                    : null,
              ),
            ),
        ],
      ],
    );
  }
}

class _NextPlanCard extends StatelessWidget {
  const _NextPlanCard({
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        [date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$weekday, $day.$month · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (event.isLinkedGroup) {
      return _NextLinkedGroupCard(
        event: event,
        onTap: onTap,
        formatDate: _formatDate,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 242,
        decoration: BoxDecoration(
          color: PlanrDesign.ink,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 24,
              offset: const Offset(0, 11),
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
            const Positioned(
              top: 16,
              left: 16,
              child: _ImagePill(
                icon: Icons.event_available_rounded,
                label: 'NEXT PLAN',
              ),
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
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  EventTagChips(
                    tagIds: event.tags,
                    maxVisible: 3,
                    dark: true,
                    compact: true,
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: _DarkMetaLine(
                          icon: Icons.calendar_month_rounded,
                          text: _formatDate(event.date),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DarkMetaLine(
                          icon: Icons.location_on_outlined,
                          text: event.address.isEmpty
                              ? 'No location'
                              : event.address,
                        ),
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

class _NextLinkedGroupCard extends StatelessWidget {
  const _NextLinkedGroupCard({
    required this.event,
    required this.onTap,
    required this.formatDate,
  });

  final Event event;
  final VoidCallback onTap;
  final String Function(DateTime date) formatDate;

  @override
  Widget build(BuildContext context) {
    final publicTitle =
        event.linkedPublicEventTitle?.trim().isNotEmpty == true
            ? event.linkedPublicEventTitle!.trim()
            : event.title;

    final publicAddress =
        event.linkedPublicEventAddress?.trim().isNotEmpty == true
            ? event.linkedPublicEventAddress!.trim()
            : event.address;

    final publicDate = event.linkedPublicEventDate ?? event.date;
    final publicImageUrl = event.linkedPublicEventImageUrl?.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: PlanrDesign.ink,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 24,
              offset: const Offset(0, 11),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (publicImageUrl != null && publicImageUrl.isNotEmpty)
              Image.network(
                publicImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _EventImage(event: event),
              )
            else
              _EventImage(event: event),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.42),
                    Colors.black.withOpacity(0.86),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const Positioned(
              top: 16,
              left: 16,
              child: _ImagePill(
                icon: Icons.group_work_rounded,
                label: 'PRIVATE GROUP',
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              top: 68,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'for',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    publicTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.04,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.75,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PlanrDesign.cardLight.withOpacity(0.93),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: PlanrDesign.accentSoft.withOpacity(0.78),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: PlanrDesign.accentDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your private plan',
                            style: TextStyle(
                              color: PlanrDesign.ink,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatDate(publicDate)} · ${publicAddress.isEmpty ? 'No location' : publicAddress}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlanrDesign.eventMetaOrange,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: PlanrDesign.softMuted,
                      size: 26,
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

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
        if (actionLabel != null && onActionTap != null) ...[
          const SizedBox(width: 12),
          _TextPillButton(
            label: actionLabel!,
            onTap: onActionTap!,
          ),
        ],
      ],
    );
  }
}

class _NoPlansCard extends StatelessWidget {
  const _NoPlansCard();

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(22),
      color: PlanrDesign.cardLight.withOpacity(0.88),
      radius: 30,
      child: Column(
        children: [
          const _IconBubble(
            icon: Icons.event_busy_rounded,
          ),
          const SizedBox(height: 12),
          const Text(
            'No plans yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PlanrDesign.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Events you create, join or accept will show up here.',
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
        errorBuilder: (_, _, _) => const _EventPlaceholderSmall(),
      );
    }

    return const _EventPlaceholderSmall();
  }
}

class _EventPlaceholderSmall extends StatelessWidget {
  const _EventPlaceholderSmall();

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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
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
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetaLine extends StatelessWidget {
  const _MiniMetaLine({
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
          size: 15,
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
      children: [
        Icon(
          icon,
          color: PlanrDesign.eventMetaOrange,
          size: 17,
        ),
        const SizedBox(width: 6),
        Expanded(
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

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withOpacity(0.74),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
        ),
      ),
      child: Icon(
        icon,
        color: PlanrDesign.accentDark,
        size: 22,
      ),
    );
  }
}

class _TextPillButton extends StatelessWidget {
  const _TextPillButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanrDesign.accentSoft.withOpacity(0.68),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: PlanrDesign.accentDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
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
    this.onTap,
  });

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      color: PlanrDesign.cardLight.withOpacity(0.86),
      radius: 30,
      child: Row(
        children: [
          const _IconBubble(
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
          if (onTap != null)
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

class _CirclePlusButton extends StatelessWidget {
  const _CirclePlusButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanrDesign.backgroundButton,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: PlanrDesign.backgroundButton,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withOpacity(0.12),
              width: 2.3,
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: PlanrDesign.accent,
            size: 25,
          ),
        ),
      ),
    );
  }
}