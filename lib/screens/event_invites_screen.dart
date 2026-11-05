import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_empty_state.dart';
import '../core/widgets/planr_scaffold.dart';
import '../providers/event_provider.dart';
import '../widgets/event_tag_chips.dart';

class EventInvitesScreen extends ConsumerStatefulWidget {
  const EventInvitesScreen({super.key});

  @override
  ConsumerState<EventInvitesScreen> createState() => _EventInvitesScreenState();
}

class _EventInvitesScreenState extends ConsumerState<EventInvitesScreen> {
  final Set<String> _processingInviteIds = {};

  Future<void> _acceptInvite(BuildContext context, String eventId) async {
    if (_processingInviteIds.contains(eventId)) return;

    setState(() {
      _processingInviteIds.add(eventId);
    });

    final error = await ref
        .read(eventServiceProvider)
        .acceptEventInvite(eventId: eventId);

    if (!mounted || !context.mounted) return;

    setState(() {
      _processingInviteIds.remove(eventId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Invite accepted'),
      ),
    );
  }

  Future<void> _declineInvite(BuildContext context, String eventId) async {
    if (_processingInviteIds.contains(eventId)) return;

    setState(() {
      _processingInviteIds.add(eventId);
    });

    final error = await ref
        .read(eventServiceProvider)
        .declineEventInvite(eventId: eventId);

    if (!mounted || !context.mounted) return;

    setState(() {
      _processingInviteIds.remove(eventId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Invite declined'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync = ref.watch(myEventInvitesProvider);

    return PlanrScaffold(
      title: 'Event Invites',
      variant: PlanrBackgroundVariant.events,
      child: invitesAsync.when(
        data: (invites) {
          if (invites.isEmpty) {
            return const Center(
              child: PlanrEmptyState(
                icon: Icons.mark_email_unread_outlined,
                title: 'No event invites',
                subtitle:
                    'Private event and group invites will appear here.',
              ),
            );
          }

          return ListView.separated(
            itemCount: invites.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final invite = invites[index];
              final eventId = invite['eventId'] as String;
              final tagIds = List<String>.from(
                invite['eventTags'] as List? ?? const [],
              );

              final title =
                  invite['eventTitle'] as String? ?? 'Event invite';
              final description =
                  invite['eventDescription'] as String? ?? '';
              final invitedBy =
                  invite['invitedByDisplayName'] as String? ?? 'someone';
              final imageUrl = invite['eventImageUrl'] as String?;
              final status = invite['status'] as String? ?? 'pending';

              final eventKind = invite['eventKind'] as String? ?? 'private';
              final linkedPublicEventTitle =
                  invite['linkedPublicEventTitle'] as String?;
              final linkedPublicEventImageUrl =
                  invite['linkedPublicEventImageUrl'] as String?;

              final isLinkedGroup = eventKind == 'linkedGroup';
              final displayTitle = isLinkedGroup &&
                      linkedPublicEventTitle != null &&
                      linkedPublicEventTitle.trim().isNotEmpty
                  ? linkedPublicEventTitle.trim()
                  : title;

              final displayImageUrl = isLinkedGroup &&
                      linkedPublicEventImageUrl != null &&
                      linkedPublicEventImageUrl.trim().isNotEmpty
                  ? linkedPublicEventImageUrl
                  : imageUrl;

              final isProcessing = _processingInviteIds.contains(eventId);

              return _InviteCard(
                title: displayTitle,
                groupTitle: isLinkedGroup ? title : null,
                description: description,
                invitedBy: invitedBy,
                imageUrl: displayImageUrl,
                tagIds: tagIds,
                isProcessing: isProcessing,
                status: status,
                inviteKind: isLinkedGroup
                    ? _InviteKind.linkedGroup
                    : _InviteKind.privateEvent,
                onAccept: () => _acceptInvite(context, eventId),
                onDecline: () => _declineInvite(context, eventId),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => const Center(
          child: PlanrEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Invites could not load',
            subtitle: 'Something went wrong while loading your event invites.',
          ),
        ),
      ),
    );
  }
}

enum _InviteKind {
  privateEvent,
  linkedGroup,
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.title,
    required this.groupTitle,
    required this.description,
    required this.invitedBy,
    required this.imageUrl,
    required this.tagIds,
    required this.isProcessing,
    required this.status,
    required this.inviteKind,
    required this.onAccept,
    required this.onDecline,
  });

  final String title;
  final String? groupTitle;
  final String description;
  final String invitedBy;
  final String? imageUrl;
  final List<String> tagIds;
  final bool isProcessing;
  final String status;
  final _InviteKind inviteKind;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  bool get _isDeclined => status == 'declined';

  String get _kindLabel {
    return switch (inviteKind) {
      _InviteKind.privateEvent => 'Private invite',
      _InviteKind.linkedGroup => 'Group invite',
    };
  }

  IconData get _kindIcon {
    return switch (inviteKind) {
      _InviteKind.privateEvent => Icons.lock_outline_rounded,
      _InviteKind.linkedGroup => Icons.group_work_rounded,
    };
  }

  String get _statusText {
    if (_isDeclined) return 'You declined this invite';
    return 'Invited by $invitedBy';
  }

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: EdgeInsets.zero,
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InviteImageHeader(
            imageUrl: imageUrl,
            title: title,
            groupTitle: groupTitle,
            inviteKind: inviteKind,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: PlanrDesign.accentSoft.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      child: Icon(
                        _kindIcon,
                        color: PlanrDesign.accentDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _kindLabel,
                            style: const TextStyle(
                              color: PlanrDesign.eventMetaOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _isDeclined
                                  ? PlanrDesign.softMuted
                                  : PlanrDesign.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 13),
                  Text(
                    description.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PlanrDesign.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],

                if (tagIds.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  EventTagChips(
                    tagIds: tagIds,
                    maxVisible: 3,
                    compact: true,
                  ),
                ],

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: PlanrButton(
                        label: _isDeclined ? 'Declined' : 'Decline',
                        icon: Icons.close_rounded,
                        variant: PlanrButtonVariant.outlined,
                        isLoading: false,
                        onPressed:
                            isProcessing || _isDeclined ? null : onDecline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PlanrButton(
                        label: _isDeclined ? 'Accept again' : 'Accept',
                        icon: Icons.check_rounded,
                        isLoading: isProcessing,
                        onPressed: isProcessing ? null : onAccept,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteImageHeader extends StatelessWidget {
  const _InviteImageHeader({
    required this.imageUrl,
    required this.title,
    required this.groupTitle,
    required this.inviteKind,
  });

  final String? imageUrl;
  final String title;
  final String? groupTitle;
  final _InviteKind inviteKind;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    final eyebrow = switch (inviteKind) {
      _InviteKind.privateEvent => 'Private event',
      _InviteKind.linkedGroup => 'Private group for',
    };

    return Container(
      height: 168,
      width: double.infinity,
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withValues(alpha: 0.45),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PlanrDesign.cardLight.withValues(alpha: 0.95),
                    PlanrDesign.accentSoft.withValues(alpha: 0.58),
                    const Color(0xFFFFE3CC).withValues(alpha: 0.78),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  inviteKind == _InviteKind.linkedGroup
                      ? Icons.group_work_rounded
                      : Icons.event_available_rounded,
                  color: PlanrDesign.accent,
                  size: 42,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: PlanrDesign.eventOverlayGradient(),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.55,
                    height: 1.05,
                  ),
                ),
                if (groupTitle != null &&
                    groupTitle!.trim().isNotEmpty &&
                    groupTitle!.trim() != title.trim()) ...[
                  const SizedBox(height: 5),
                  Text(
                    groupTitle!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}