import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/planr_design.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../screens/edit_event_screen.dart';
import '../../screens/event_chat_screen.dart';
import '../../screens/event_detail_screen.dart';
import '../../screens/invite_to_event_screen.dart';
import 'event_detail_info_card.dart';

class EventDetailActionPanel extends ConsumerWidget {
  const EventDetailActionPanel({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser?.uid == event.creatorUid;

    return EventDetailInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect',
            style: TextStyle(
              color: PlanrDesign.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          if (event.isPublicEvent)
            _PublicEventActions(event: event)
          else if (event.isLinkedGroup)
            _LinkedGroupActions(
              event: event,
              canInvite: isCreator || event.guestsCanInvite,
            )
          else
            _PrivateEventActions(
              event: event,
              canInvite: isCreator || event.guestsCanInvite,
            ),
          if (isCreator) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CreatorUtilityButton(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditEventScreen(event: event),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CreatorUtilityButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    isDestructive: true,
                    onTap: () => _confirmAndDeleteEvent(
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

  Future<void> _confirmAndDeleteEvent({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete event?'),
          content: const Text(
            'This will remove the event for everyone. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final error = await ref.read(eventServiceProvider).deleteEvent(event);

    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.pop(context);
  }
}

class _PublicEventActions extends ConsumerWidget {
  const _PublicEventActions({
    required this.event,
  });

  final Event event;

  Future<void> _createGroupAndInvite({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final service = ref.read(eventServiceProvider);

    final result = await service.createLinkedGroupFromPublicEventAndReturn(
      publicEvent: event,
    );

    if (!context.mounted) return;

    if (result.error != null || result.group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not create group.')),
      );
      return;
    }

    ref.invalidate(linkedGroupForPublicEventProvider(event.id));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InviteToEventScreen(
          event: result.group!,
          openEventDetailOnFinish: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedGroupAsync =
        ref.watch(linkedGroupForPublicEventProvider(event.id));

    return linkedGroupAsync.when(
      data: (linkedGroup) {
        final hasGroup = linkedGroup != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PublicEventNotice(),
            const SizedBox(height: 14),
            if (!hasGroup)
              Row(
                children: [
                  Expanded(
                    child: _LargeActionButton(
                      icon: Icons.group_add_rounded,
                      title: 'Make Group',
                      subtitle: 'Plan with friends',
                      enabled: true,
                      onTap: () => _createGroupAndInvite(
                        context: context,
                        ref: ref,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LargeActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No chat',
                      subtitle: 'Public chat disabled',
                      enabled: false,
                      onTap: () {},
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _LargeActionButton(
                      icon: Icons.open_in_new_rounded,
                      title: 'Open Group',
                      subtitle: 'Private plan',
                      enabled: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(
                              eventId: linkedGroup.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LargeActionButton(
                      icon: Icons.group_add_rounded,
                      title: 'Invite',
                      subtitle: 'Add friends',
                      enabled: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InviteToEventScreen(
                              event: linkedGroup,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(
            child: _LargeActionButton(
              icon: Icons.group_add_rounded,
              title: 'Make Group',
              subtitle: 'Loading...',
              enabled: false,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _LargeActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No chat',
              subtitle: 'Public chat disabled',
              enabled: false,
              onTap: () {},
            ),
          ),
        ],
      ),
      error: (_, _) => Row(
        children: [
          Expanded(
            child: _LargeActionButton(
              icon: Icons.group_add_rounded,
              title: 'Make Group',
              subtitle: 'Try again',
              enabled: true,
              onTap: () => _createGroupAndInvite(
                context: context,
                ref: ref,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _LargeActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No chat',
              subtitle: 'Public chat disabled',
              enabled: false,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateEventActions extends StatelessWidget {
  const _PrivateEventActions({
    required this.event,
    required this.canInvite,
  });

  final Event event;
  final bool canInvite;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LargeActionButton(
            icon: event.chatEnabled
                ? Icons.chat_bubble_rounded
                : Icons.chat_bubble_outline_rounded,
            title: event.chatEnabled ? 'Chat' : 'No chat',
            subtitle: event.chatEnabled ? 'Talk with guests' : 'Disabled',
            enabled: event.chatEnabled,
            onTap: event.chatEnabled
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventChatScreen(event: event),
                      ),
                    );
                  }
                : () {},
          ),
        ),
        if (canInvite) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _LargeActionButton(
              icon: Icons.group_add_rounded,
              title: 'Invite',
              subtitle: 'Bring friends',
              enabled: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InviteToEventScreen(event: event),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _LinkedGroupActions extends StatelessWidget {
  const _LinkedGroupActions({
    required this.event,
    required this.canInvite,
  });

  final Event event;
  final bool canInvite;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event.linkedPublicEventTitle != null) ...[
          _LinkedPublicEventNotice(event: event),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: _LargeActionButton(
                icon: Icons.chat_bubble_rounded,
                title: 'Group Chat',
                subtitle: 'Plan privately',
                enabled: event.chatEnabled,
                onTap: event.chatEnabled
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventChatScreen(event: event),
                          ),
                        );
                      }
                    : () {},
              ),
            ),
            if (canInvite) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _LargeActionButton(
                  icon: Icons.group_add_rounded,
                  title: 'Invite',
                  subtitle: 'Add friends',
                  enabled: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InviteToEventScreen(event: event),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PublicEventNotice extends StatelessWidget {
  const _PublicEventNotice();

  @override
  Widget build(BuildContext context) {
    return _InfoNotice(
      icon: Icons.public_rounded,
      title: 'Public event',
      text:
          'This event is discoverable. There is no public chat. Use a private group to plan with friends.',
    );
  }
}

class _LinkedPublicEventNotice extends StatelessWidget {
  const _LinkedPublicEventNotice({
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return _InfoNotice(
      icon: Icons.link_rounded,
      title: 'Linked to public event',
      text: event.linkedPublicEventTitle ?? 'Public event',
    );
  }
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: PlanrDesign.accentDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
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

class _LargeActionButton extends StatelessWidget {
  const _LargeActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = enabled
        ? PlanrDesign.accentSoft.withValues(alpha: 0.72)
        : PlanrDesign.cardLight.withValues(alpha: 0.7);

    final foreground = enabled ? PlanrDesign.accentDark : PlanrDesign.softMuted;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 92,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: foreground,
                size: 24,
              ),
              const SizedBox(height: 18),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: enabled ? PlanrDesign.ink : PlanrDesign.softMuted,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
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
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : PlanrDesign.accentDark;

    return Material(
      color: PlanrDesign.cardLight.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}