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

    if (!mounted) return;

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

    if (!mounted) return;

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
                    'When friends invite you to private events, they will appear here.',
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

              final isProcessing = _processingInviteIds.contains(eventId);

              return _InviteCard(
                title: title,
                description: description,
                invitedBy: invitedBy,
                imageUrl: imageUrl,
                tagIds: tagIds,
                isProcessing: isProcessing,
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

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.title,
    required this.description,
    required this.invitedBy,
    required this.imageUrl,
    required this.tagIds,
    required this.isProcessing,
    required this.onAccept,
    required this.onDecline,
  });

  final String title;
  final String description;
  final String invitedBy;
  final String? imageUrl;
  final List<String> tagIds;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

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
                        color: PlanrDesign.accentSoft.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      child: const Icon(
                        Icons.mail_outline_rounded,
                        color: PlanrDesign.accentDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Private invite',
                            style: TextStyle(
                              color: PlanrDesign.eventMetaOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Invited by $invitedBy',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlanrDesign.muted,
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
                        label: 'Decline',
                        icon: Icons.close_rounded,
                        variant: PlanrButtonVariant.outlined,
                        isLoading: false,
                        onPressed: isProcessing ? null : onDecline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PlanrButton(
                        label: 'Accept',
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
  });

  final String? imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      height: 158,
      width: double.infinity,
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withOpacity(0.45),
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
                    PlanrDesign.cardLight.withOpacity(0.95),
                    PlanrDesign.accentSoft.withOpacity(0.58),
                    const Color(0xFFFFE3CC).withOpacity(0.78),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.event_available_rounded,
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
            child: Text(
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
          ),
        ],
      ),
    );
  }
}