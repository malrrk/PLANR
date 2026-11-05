import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../providers/firebase_providers.dart';
import '../providers/moderation_provider.dart';
import '../widgets/moderation/moderation_actions.dart';
import '../widgets/event_detail/event_detail_action_panel.dart';
import '../widgets/event_detail/event_detail_fact_card.dart';
import '../widgets/event_detail/event_detail_header_image.dart';
import '../widgets/event_detail/event_detail_info_card.dart';
import 'profile_screen.dart';
import 'public_page_screen.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$weekday, $day.$month · $hour:$minute';
  }

  void _openProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: userId),
      ),
    );
  }

  void _openPublicPage(BuildContext context, String pageId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicPageScreen(pageId: pageId),
      ),
    );
  }

  void _openOrganizer(BuildContext context, Event event) {
    if (event.isOrganizedByPage) {
      _openPublicPage(context, event.organizerId);
      return;
    }

    _openProfile(context, event.organizerId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(eventId));

    return PlanrBackground(
      variant: PlanrBackgroundVariant.events,
      child: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Scaffold(
              backgroundColor: Colors.transparent,
              body: _EventNotFoundState(),
            );
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton:
                event.isLinkedGroup ? null : _FloatingGoingButton(event: event),
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                EventDetailHeaderImage(
                  event: event,
                  onReport: event.creatorUid ==
                          ref.read(firebaseAuthProvider).currentUser?.uid
                      ? null
                      : () => showReportDialog(
                            context,
                            ref,
                            target: ReportTarget.event,
                            targetId: event.id,
                            title: 'Report this event',
                          ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      PlanrDesign.pagePadding,
                      18,
                      PlanrDesign.pagePadding,
                      event.isLinkedGroup ? 34 : 118,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.isLinkedGroup) ...[
                          _LinkedPublicEventCard(
                            event: event,
                            formatDate: _formatDate,
                          ),
                          const SizedBox(height: 16),
                        ],
                        EventDetailInfoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(
                                title: event.isLinkedGroup
                                    ? 'Private group'
                                    : 'About',
                                icon: event.isLinkedGroup
                                    ? Icons.group_work_rounded
                                    : Icons.notes_rounded,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                event.description.trim().isEmpty
                                    ? 'No description yet.'
                                    : event.description,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  height: 1.56,
                                  color: PlanrDesign.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (event.isPublicEvent) ...[
                          const SizedBox(height: 16),
                          _OrganizerUpdatesSection(event: event),
                        ],
                        const SizedBox(height: 16),
                        EventDetailActionPanel(event: event),
                        const SizedBox(height: 16),
                        EventDetailInfoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                title: 'Details',
                                icon: Icons.info_outline_rounded,
                              ),
                              const SizedBox(height: 14),
                              EventDetailFactCard(
                                icon: Icons.schedule_rounded,
                                label: 'Date & Time',
                                value: _formatDate(event.date),
                              ),
                              const SizedBox(height: 10),
                              EventDetailFactCard(
                                icon: Icons.place_rounded,
                                label: 'Location',
                                value: event.address,
                              ),
                              const SizedBox(height: 10),
                              _TappableHostFactCard(
                                hostName: event.publicOrganizerName,
                                isPage: event.isOrganizedByPage,
                                verified: event.organizerVerified,
                                onTap: () => _openOrganizer(context, event),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Scaffold(
          backgroundColor: Colors.transparent,
          body: _EventLoadingState(),
        ),
        error: (_, _) => const Scaffold(
          backgroundColor: Colors.transparent,
          body: _EventErrorState(),
        ),
      ),
    );
  }
}

class _OrganizerUpdatesSection extends ConsumerStatefulWidget {
  const _OrganizerUpdatesSection({
    required this.event,
  });

  final Event event;

  @override
  ConsumerState<_OrganizerUpdatesSection> createState() =>
      _OrganizerUpdatesSectionState();
}

class _OrganizerUpdatesSectionState
    extends ConsumerState<_OrganizerUpdatesSection> {
  final TextEditingController _controller = TextEditingController();

  bool _posting = false;
  bool _canManage = false;
  bool _checkingPermission = true;
  String? _deletingUpdateId;

  @override
  void initState() {
    super.initState();
    _loadPermission();
  }

  @override
  void didUpdateWidget(covariant _OrganizerUpdatesSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.event.id != widget.event.id ||
        oldWidget.event.organizerId != widget.event.organizerId ||
        oldWidget.event.creatorUid != widget.event.creatorUid) {
      _loadPermission();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPermission() async {
    setState(() {
      _checkingPermission = true;
    });

    final canManage = await ref
        .read(eventServiceProvider)
        .canManageEventUpdates(widget.event);

    if (!mounted) return;

    setState(() {
      _canManage = canManage;
      _checkingPermission = false;
    });
  }

  Future<void> _postUpdate() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      _showSnackBar('Write an update first.');
      return;
    }

    setState(() {
      _posting = true;
    });

    final error = await ref.read(eventServiceProvider).createEventUpdate(
          event: widget.event,
          text: text,
        );

    if (!mounted) return;

    setState(() {
      _posting = false;
    });

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    _controller.clear();
    _showSnackBar('Update posted.');
  }

  Future<void> _deleteUpdate(EventUpdate update) async {
    setState(() {
      _deletingUpdateId = update.id;
    });

    final error = await ref.read(eventServiceProvider).deleteEventUpdate(
          event: widget.event,
          updateId: update.id,
        );

    if (!mounted) return;

    setState(() {
      _deletingUpdateId = null;
    });

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    _showSnackBar('Update deleted.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updatesAsync = ref.watch(eventUpdatesProvider(widget.event.id));

    return EventDetailInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Organizer Updates',
            icon: Icons.campaign_rounded,
          ),
          const SizedBox(height: 10),
          Text(
            widget.event.isOrganizedByPage
                ? 'Official updates from ${widget.event.publicOrganizerName}.'
                : 'Official updates from the event host.',
            style: const TextStyle(
              color: PlanrDesign.muted,
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_canManage) ...[
            const SizedBox(height: 16),
            _UpdateComposer(
              controller: _controller,
              posting: _posting,
              onPost: _postUpdate,
            ),
          ] else if (_checkingPermission) ...[
            const SizedBox(height: 14),
            const _UpdatesPermissionLoading(),
          ],
          const SizedBox(height: 16),
          updatesAsync.when(
            data: (updates) {
              if (updates.isEmpty) {
                return const _NoUpdatesState();
              }

              return Column(
                children: [
                  for (final update in updates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OrganizerUpdateCard(
                        update: update,
                        canManage: _canManage,
                        isDeleting: _deletingUpdateId == update.id,
                        onDelete: () => _deleteUpdate(update),
                      ),
                    ),
                ],
              );
            },
            loading: () => const _UpdatesLoadingState(),
            error: (_, _) => const _UpdatesErrorState(),
          ),
        ],
      ),
    );
  }
}

class _UpdateComposer extends StatelessWidget {
  const _UpdateComposer({
    required this.controller,
    required this.posting,
    required this.onPost,
  });

  final TextEditingController controller;
  final bool posting;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            maxLength: 600,
            cursorColor: PlanrDesign.accent,
            style: const TextStyle(
              color: PlanrDesign.ink,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
            decoration: const InputDecoration(
              hintText: 'Post an update for everyone...',
              hintStyle: TextStyle(
                color: PlanrDesign.softMuted,
                fontWeight: FontWeight.w700,
              ),
              counterStyle: TextStyle(
                color: PlanrDesign.softMuted,
                fontWeight: FontWeight.w700,
              ),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Visible to everyone who opens this public event.',
                  style: TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: posting ? null : onPost,
                icon: posting
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 17),
                label: Text(posting ? 'Posting' : 'Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PlanrDesign.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      PlanrDesign.accentSoft.withValues(alpha: 0.8),
                  disabledForegroundColor: PlanrDesign.accentDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrganizerUpdateCard extends StatelessWidget {
  const _OrganizerUpdateCard({
    required this.update,
    required this.canManage,
    required this.isDeleting,
    required this.onDelete,
  });

  final EventUpdate update;
  final bool canManage;
  final bool isDeleting;
  final VoidCallback onDelete;

  String _formatUpdateDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final authorPhoto = update.authorPhotoUrl?.trim();
    final hasPhoto = authorPhoto != null && authorPhoto.isNotEmpty;
    final initial = update.authorName.trim().isEmpty
        ? 'O'
        : update.authorName.trim().characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(
                    authorPhoto,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _UpdateAuthorInitial(
                      initial: initial,
                    ),
                  )
                : _UpdateAuthorInitial(initial: initial),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        update.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PlanrDesign.ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatUpdateDate(update.createdAt),
                      style: const TextStyle(
                        color: PlanrDesign.softMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  update.text,
                  style: const TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 14.3,
                    height: 1.42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (canManage) ...[
            const SizedBox(width: 6),
            Material(
              color: PlanrDesign.accentSoft.withValues(alpha: 0.58),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isDeleting ? null : onDelete,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Center(
                    child: isDeleting
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.delete_outline_rounded,
                            color: PlanrDesign.accentDark,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpdateAuthorInitial extends StatelessWidget {
  const _UpdateAuthorInitial({
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
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
      ),
    );
  }
}

class _NoUpdatesState extends StatelessWidget {
  const _NoUpdatesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: const Text(
        'No organizer updates yet.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: PlanrDesign.muted,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UpdatesLoadingState extends StatelessWidget {
  const _UpdatesLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
    );
  }
}

class _UpdatesPermissionLoading extends StatelessWidget {
  const _UpdatesPermissionLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Text(
          'Checking organizer permissions...',
          style: TextStyle(
            color: PlanrDesign.softMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _UpdatesErrorState extends StatelessWidget {
  const _UpdatesErrorState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: const Text(
        'Could not load organizer updates.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: PlanrDesign.muted,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LinkedPublicEventCard extends StatelessWidget {
  const _LinkedPublicEventCard({
    required this.event,
    required this.formatDate,
  });

  final Event event;
  final String Function(DateTime date) formatDate;

  @override
  Widget build(BuildContext context) {
    final publicEventId = event.linkedPublicEventId;
    final title = event.linkedPublicEventTitle?.trim().isNotEmpty == true
        ? event.linkedPublicEventTitle!.trim()
        : 'Public event';

    final address = event.linkedPublicEventAddress?.trim().isNotEmpty == true
        ? event.linkedPublicEventAddress!.trim()
        : event.address;

    final date = event.linkedPublicEventDate ?? event.date;
    final imageUrl = event.linkedPublicEventImageUrl?.trim();

    return PlanrCard(
      padding: EdgeInsets.zero,
      radius: 26,
      color: PlanrDesign.cardLight.withValues(alpha: 0.88),
      onTap: publicEventId == null || publicEventId.isEmpty
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(eventId: publicEventId),
                ),
              );
            },
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            Container(
              width: 78,
              height: 88,
              decoration: BoxDecoration(
                color: PlanrDesign.accentSoft.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const _LinkedEventPlaceholder(),
                    )
                  else
                    const _LinkedEventPlaceholder(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.35),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.link_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: SizedBox(
                height: 88,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.public_rounded,
                          color: PlanrDesign.accentDark,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Linked public event',
                          style: TextStyle(
                            color: PlanrDesign.accentDark,
                            fontSize: 12.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        if (publicEventId != null && publicEventId.isNotEmpty)
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: PlanrDesign.softMuted,
                            size: 22,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 17,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const Spacer(),
                    _LinkedMetaLine(
                      icon: Icons.schedule_rounded,
                      text: formatDate(date),
                    ),
                    const SizedBox(height: 4),
                    _LinkedMetaLine(
                      icon: Icons.place_rounded,
                      text: address.isEmpty ? 'No location' : address,
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

class _LinkedEventPlaceholder extends StatelessWidget {
  const _LinkedEventPlaceholder();

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
          size: 42,
        ),
      ),
    );
  }
}

class _LinkedMetaLine extends StatelessWidget {
  const _LinkedMetaLine({
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
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlanrDesign.eventMetaOrange,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingGoingButton extends ConsumerWidget {
  const _FloatingGoingButton({
    required this.event,
  });

  final Event event;

  Future<void> _toggleGoing({
    required BuildContext context,
    required WidgetRef ref,
    required bool isGoing,
  }) async {
    final service = ref.read(eventServiceProvider);

    final error =
        isGoing ? await service.leaveEvent(event) : await service.joinEvent(event);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? (isGoing ? 'You left the event.' : 'You are going.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGoingAsync = ref.watch(isGoingProvider(event.id));

    return isGoingAsync.when(
      data: (isGoing) {
        return FloatingActionButton.extended(
          heroTag: 'event-going-${event.id}',
          onPressed: () => _toggleGoing(
            context: context,
            ref: ref,
            isGoing: isGoing,
          ),
          backgroundColor:
              isGoing ? PlanrDesign.accentSoft : PlanrDesign.accent,
          foregroundColor:
              isGoing ? PlanrDesign.accentDark : Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          icon: Icon(
            isGoing ? Icons.check_circle_rounded : Icons.add_circle_rounded,
          ),
          label: Text(
            isGoing ? 'Going' : 'I am going',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        );
      },
      loading: () {
        return FloatingActionButton(
          heroTag: 'event-going-loading-${event.id}',
          onPressed: null,
          backgroundColor: PlanrDesign.accentSoft,
          foregroundColor: PlanrDesign.accentDark,
          elevation: 4,
          child: const SizedBox(
            width: 21,
            height: 21,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        );
      },
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PlanrDesign.accentSoft.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: PlanrDesign.accentDark,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: PlanrDesign.ink,
          ),
        ),
      ],
    );
  }
}

class _TappableHostFactCard extends StatelessWidget {
  const _TappableHostFactCard({
    required this.hostName,
    required this.isPage,
    required this.verified,
    required this.onTap,
  });

  final String hostName;
  final bool isPage;
  final bool verified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanrDesign.cardLight.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: PlanrDesign.accentSoft.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                child: Icon(
                  isPage ? Icons.storefront_rounded : Icons.person_rounded,
                  color: PlanrDesign.accentDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPage ? 'Organizer page' : 'Host',
                      style: const TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hostName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlanrDesign.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            color: PlanrDesign.accentDark,
                            size: 17,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: PlanrDesign.softMuted,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventLoadingState extends StatelessWidget {
  const _EventLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.6),
    );
  }
}

class _EventErrorState extends StatelessWidget {
  const _EventErrorState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessageCard(
      icon: Icons.error_outline_rounded,
      title: 'Could not load event.',
      subtitle: 'Please try again in a moment.',
    );
  }
}

class _EventNotFoundState extends StatelessWidget {
  const _EventNotFoundState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessageCard(
      icon: Icons.search_off_rounded,
      title: 'Event not found.',
      subtitle: 'This event may have been deleted.',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlanrDesign.pagePadding),
        child: PlanrCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: PlanrDesign.accentDark,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PlanrDesign.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}