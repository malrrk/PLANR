import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/planr_design.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../screens/edit_event_screen.dart';
import '../../screens/event_chat_screen.dart';
import '../../screens/invite_to_event_screen.dart';
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

    return EventDetailInfoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _LargeActionButton(
                  icon: Icons.chat_bubble_rounded,
                  title: event.chatEnabled ? 'Chat' : 'No chat',
                  subtitle: event.chatEnabled ? 'Open event chat' : 'Disabled',
                  enabled: event.chatEnabled,
                  onPressed: event.chatEnabled ? () => _openChat(context) : null,
                ),
              ),
              if (canInvite) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _LargeActionButton(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Invite',
                    subtitle: 'Bring friends',
                    enabled: true,
                    onPressed: () => _openInviteFriends(context),
                  ),
                ),
              ],
            ],
          ),
          if (isCreator) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CreatorUtilityButton(
                    icon: Icons.edit_rounded,
                    label: 'Edit event',
                    onPressed: () => _openEditEvent(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CreatorUtilityButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    isDanger: true,
                    onPressed: () => _confirmAndDeleteEvent(
                      context: context,
                      ref: ref,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PlanrDesign.accentSoft.withOpacity(0.72),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: PlanrDesign.accentDark,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Connect',
          style: TextStyle(
            color: PlanrDesign.ink,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _LargeActionButton extends StatelessWidget {
  const _LargeActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(enabled ? 0.52 : 0.30),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 94,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: enabled ? PlanrDesign.accentDark : PlanrDesign.softMuted,
                size: 23,
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: enabled ? PlanrDesign.ink : PlanrDesign.softMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 12,
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

class _CreatorUtilityButton extends StatelessWidget {
  const _CreatorUtilityButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.red.shade600 : PlanrDesign.accentDark;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
        color: color,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}