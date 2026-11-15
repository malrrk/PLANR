import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/plan_time.dart';
import '../../core/theme/planr_design.dart';
import '../../models/firestore_dates.dart';
import '../../providers/event_provider.dart';
import '../../screens/event_detail_screen.dart';
import '../../screens/event_invites_screen.dart';
import '../event_cover.dart';

/// Pending invitations with one-tap answers. Disappears when there is nothing to answer.
class HomeInvitationsSection extends ConsumerStatefulWidget {
  const HomeInvitationsSection({super.key});

  @override
  ConsumerState<HomeInvitationsSection> createState() =>
      _HomeInvitationsSectionState();
}

class _HomeInvitationsSectionState
    extends ConsumerState<HomeInvitationsSection> {
  static const _maxShown = 2;

  final Set<String> _busy = {};

  Future<void> _answer(String eventId, {required bool accept}) async {
    if (_busy.contains(eventId)) return;

    HapticFeedback.mediumImpact();
    setState(() => _busy.add(eventId));

    final service = ref.read(eventServiceProvider);
    final error = accept
        ? await service.acceptEventInvite(eventId: eventId)
        : await service.declineEventInvite(eventId: eventId);

    if (!mounted) return;

    setState(() => _busy.remove(eventId));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error ?? (accept ? "You're in! See you there." : 'Invite declined.'),
          ),
        ),
      );
  }

  void _openEvent(String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventId)),
    );
  }

  void _openAll() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventInvitesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invites = ref.watch(pendingEventInvitesProvider).value ?? const [];

    if (invites.isEmpty) return const SizedBox.shrink();

    final shown = invites.take(_maxShown).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Needs your answer',
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: PlanrDesign.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${invites.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final invite in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InviteCard(
                invite: invite,
                busy: _busy.contains(invite['eventId'] as String),
                onOpen: () => _openEvent(invite['eventId'] as String),
                onAccept: () =>
                    _answer(invite['eventId'] as String, accept: true),
                onDecline: () =>
                    _answer(invite['eventId'] as String, accept: false),
              ),
            ),
          if (invites.length > _maxShown)
            GestureDetector(
              onTap: _openAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'See all ${invites.length} invitations',
                  style: const TextStyle(
                    color: PlanrDesign.accentDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.busy,
    required this.onOpen,
    required this.onAccept,
    required this.onDecline,
  });

  final Map<String, dynamic> invite;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final linkedTitle = invite['linkedPublicEventTitle'] as String?;
    final title = (linkedTitle?.trim().isNotEmpty ?? false)
        ? linkedTitle!.trim()
        : (invite['eventTitle'] as String? ?? 'Plan');
    final inviter = invite['invitedByDisplayName'] as String? ?? 'A friend';
    final date = dateFromFirestore(invite['eventDate']);
    final address = (invite['eventAddress'] as String?)?.trim() ?? '';
    final tags = List<String>.from(invite['eventTags'] as List? ?? const []);
    final imageUrl = (invite['linkedPublicEventImageUrl'] as String?) ??
        invite['eventImageUrl'] as String?;

    final meta = [
      if (date != null) planTimeLabel(date),
      if (address.isNotEmpty) address,
    ].join('  ·  ');

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PlanrDesign.accentSoft.withValues(alpha: 0.75),
                PlanrDesign.cardLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: PlanrDesign.accent.withValues(alpha: 0.22),
              width: 1.3,
            ),
            boxShadow: [PlanrDesign.softShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: EventCover(
                        imageUrl: imageUrl,
                        tags: tags,
                        iconSize: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$inviter invited you',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PlanrDesign.accentDark,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PlanrDesign.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlanrDesign.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _AnswerButton(
                      label: 'Not this time',
                      filled: false,
                      busy: busy,
                      onTap: onDecline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AnswerButton(
                      label: "I'm in",
                      filled: true,
                      busy: busy,
                      onTap: onAccept,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.filled,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor:
              filled ? PlanrDesign.accent : Colors.white.withValues(alpha: 0.8),
          foregroundColor: filled ? Colors.white : PlanrDesign.ink,
          disabledBackgroundColor: PlanrDesign.softMuted.withValues(alpha: 0.2),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: filled
                ? BorderSide.none
                : BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
