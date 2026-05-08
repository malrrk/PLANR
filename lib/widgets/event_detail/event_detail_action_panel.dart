import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../screens/edit_event_screen.dart';
import '../../screens/event_chat_screen.dart';
import '../../screens/invite_to_event_screen.dart';
import 'event_detail_design.dart';
import 'event_detail_info_card.dart';

class EventDetailActionPanel extends ConsumerWidget {
  const EventDetailActionPanel({
    super.key,
    required this.event,
  });

  final Event event;

  void _openEditEvent(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditEventScreen(event: event),
      ),
    );
  }

  void _openInviteFriends(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InviteToEventScreen(event: event),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventChatScreen(event: event),
      ),
    );
  }

  Future<void> _toggleGoing({
    required BuildContext context,
    required WidgetRef ref,
    required bool isGoing,
  }) async {
    final service = ref.read(eventServiceProvider);

    final error = isGoing
        ? await service.leaveEvent(event)
        : await service.joinEvent(event);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? (isGoing ? 'You left the event.' : 'You are going.'),
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteEvent({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete event?'),
          content: Text(
            'This will permanently delete "${event.title}" for everyone. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final service = ref.read(eventServiceProvider);
    final error = await service.deleteEvent(event);

    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event deleted.'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser?.uid == event.creatorUid;
    final canInvite = isCreator || event.guestsCanInvite;
    final isGoingAsync = ref.watch(isGoingProvider(event.id));

    return EventDetailInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: EventDetailDesign.ink,
            ),
          ),
          const SizedBox(height: 14),
          if (isCreator) ...[
            _SecondaryActionButton(
              icon: Icons.edit_rounded,
              label: 'Edit event',
              onPressed: () => _openEditEvent(context),
            ),
            const SizedBox(height: 10),
          ],
          if (canInvite) ...[
            _SecondaryActionButton(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Invite friends',
              onPressed: () => _openInviteFriends(context),
            ),
            const SizedBox(height: 10),
          ],
          _SecondaryActionButton(
            icon: Icons.chat_bubble_rounded,
            label: event.chatEnabled ? 'Open chat' : 'Chat disabled',
            onPressed: event.chatEnabled ? () => _openChat(context) : null,
          ),
          const SizedBox(height: 14),
          isGoingAsync.when(
            data: (isGoing) {
              return SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => _toggleGoing(
                    context: context,
                    ref: ref,
                    isGoing: isGoing,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isGoing
                        ? const Color(0xFFF3F4F6)
                        : EventDetailDesign.ink,
                    foregroundColor:
                        isGoing ? EventDetailDesign.ink : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: Icon(
                    isGoing
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_rounded,
                  ),
                  label: Text(
                    isGoing ? 'You are going' : 'I am going',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 56,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
            ),
            error: (_, _) => const Text(
              'Could not load attendance status.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isCreator) ...[
            const SizedBox(height: 14),
            _DangerActionButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete event',
              onPressed: () => _confirmAndDeleteEvent(
                context: context,
                ref: ref,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              enabled ? EventDetailDesign.ink : EventDetailDesign.muted,
          side: const BorderSide(color: EventDetailDesign.softBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DangerActionButton extends StatelessWidget {
  const _DangerActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade600,
          side: BorderSide(color: Colors.red.shade100),
          backgroundColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}