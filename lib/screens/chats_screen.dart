import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/plan_time.dart';
import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../widgets/event_cover.dart';
import '../widgets/plans/quick_plan_sheet.dart';
import 'event_chat_screen.dart';

/// Plan chats in one place: unread first, then newest activity.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  static List<Event> chatsFrom(List<Event> events, DateTime now) {
    final chats = events.where((event) => event.chatEnabled).toList();

    int rank(Event event) {
      if (event.hasUnreadMessages) return 0;
      if (event.date.isAfter(now.subtract(const Duration(hours: 12)))) return 1;
      return 2;
    }

    chats.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;

      final aActivity = a.lastMessageAt ?? a.createdAt;
      final bActivity = b.lastMessageAt ?? b.createdAt;
      return bActivity.compareTo(aActivity);
    });

    return chats;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(myEventsProvider);
    final now = DateTime.now();

    return PlanrBackground(
      variant: PlanrBackgroundVariant.events,
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
              124,
            ),
            children: [
              const Text(
                'Chats',
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Every plan has a place to talk.',
                style: TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              eventsAsync.when(
                data: (events) {
                  final chats = chatsFrom(events, now);

                  if (chats.isEmpty) {
                    return _EmptyChats(
                      onStart: () => showQuickPlanSheet(context),
                    );
                  }

                  return Column(
                    children: [
                      for (final event in chats)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ChatRow(event: event, now: now),
                        ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'Could not load your chats.',
                    style: TextStyle(color: PlanrDesign.muted),
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

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.event, required this.now});

  final Event event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final linked = event.isLinkedGroup;
    final title =
        linked ? (event.linkedPublicEventTitle ?? event.title) : event.title;
    final imageUrl = linked
        ? (event.linkedPublicEventImageUrl ?? event.imageUrl)
        : event.imageUrl;

    final hasMessage = (event.lastMessageText?.trim().isNotEmpty ?? false);
    final sender = event.lastMessageSenderName?.split(' ').first;
    final preview = hasMessage
        ? '${sender == null || sender.isEmpty ? '' : '$sender: '}${event.lastMessageText!.trim()}'
        : 'No messages yet. Say hi!';

    final unread = event.hasUnreadMessages;
    final past = event.date.isBefore(now);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventChatScreen(event: event)),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: unread
                ? PlanrDesign.accentSoft.withValues(alpha: 0.55)
                : PlanrDesign.cardLight.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: unread
                  ? PlanrDesign.accent.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.95),
            ),
            boxShadow: [PlanrDesign.softShadow],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: EventCover(
                    imageUrl: imageUrl,
                    tags: event.tags,
                    iconSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlanrDesign.ink,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          past
                              ? 'Done'
                              : planTimeLabel(event.date, now: now).split(' · ').first,
                          style: TextStyle(
                            color: past
                                ? PlanrDesign.softMuted
                                : PlanrDesign.accentDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread ? PlanrDesign.ink : PlanrDesign.muted,
                        fontSize: 13.5,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 10),
                Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: PlanrDesign.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: PlanrDesign.cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: PlanrDesign.brandGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No chats yet',
            style: TextStyle(
              color: PlanrDesign.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Make a plan with a friend and its chat shows up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PlanrDesign.muted,
              fontSize: 14.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: PlanrDesign.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Make a plan',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
