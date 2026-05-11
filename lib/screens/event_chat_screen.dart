import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_avatar.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_empty_state.dart';
import '../core/widgets/planr_scaffold.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import 'profile_screen.dart';

class EventChatScreen extends ConsumerStatefulWidget {
  const EventChatScreen({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  ConsumerState<EventChatScreen> createState() => _EventChatScreenState();
}

class _EventChatScreenState extends ConsumerState<EventChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || !widget.event.chatEnabled) return;

    setState(() {
      _sending = true;
    });

    final error = await ref.read(eventServiceProvider).sendEventMessage(
          event: widget.event,
          text: text,
        );

    if (!mounted) return;

    setState(() {
      _sending = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    _controller.clear();
  }

  void _openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(eventMessagesProvider(widget.event.id));

    return PlanrScaffold(
      title: 'Event Chat',
      variant: PlanrBackgroundVariant.events,
      padding: EdgeInsets.zero,
      resizeToAvoidBottomInset: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PlanrDesign.pagePadding,
              6,
              PlanrDesign.pagePadding,
              12,
            ),
            child: _ChatHeaderCard(event: widget.event),
          ),

          if (!widget.event.chatEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PlanrDesign.pagePadding,
                0,
                PlanrDesign.pagePadding,
                12,
              ),
              child: const _ChatDisabledBanner(),
            ),

          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PlanrDesign.pagePadding,
                      10,
                      PlanrDesign.pagePadding,
                      10,
                    ),
                    child: PlanrEmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No messages yet',
                      subtitle:
                          'Start the conversation and coordinate the plan with everyone going.',
                      actionLabel:
                          widget.event.chatEnabled ? 'Write first message' : null,
                      onActionPressed:
                          widget.event.chatEnabled ? () {} : null,
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(
                    PlanrDesign.pagePadding,
                    8,
                    PlanrDesign.pagePadding,
                    14,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    final senderUid = message['senderUid'] as String?;
                    final senderName =
                        message['senderDisplayName'] as String? ?? 'User';
                    final senderPhotoUrl =
                        message['senderPhotoUrl'] as String?;
                    final text = message['text'] as String? ?? '';

                    final currentUid = FirebaseAuth.instance.currentUser?.uid;
                    final isMe =
                        currentUid != null && senderUid != null && currentUid == senderUid;

                    return _MessageBubble(
                      senderUid: senderUid,
                      senderName: senderName,
                      senderPhotoUrl: senderPhotoUrl,
                      text: text,
                      isMe: isMe,
                      onProfileTap: senderUid == null
                          ? null
                          : () => _openProfile(senderUid),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(PlanrDesign.pagePadding),
                child: PlanrEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Chat could not load',
                  subtitle: 'Something went wrong while loading the messages.',
                ),
              ),
            ),
          ),

          _MessageComposer(
            controller: _controller,
            enabled: widget.event.chatEnabled && !_sending,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ChatHeaderCard extends StatelessWidget {
  const _ChatHeaderCard({
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(14),
      radius: 24,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withOpacity(0.74),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: PlanrDesign.accentDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.chatEnabled
                      ? 'Coordinate with everyone going'
                      : 'Chat is currently disabled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

class _ChatDisabledBanner extends StatelessWidget {
  const _ChatDisabledBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withOpacity(0.76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: PlanrDesign.accentDark,
            size: 21,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chat is disabled for this event.',
              style: TextStyle(
                color: PlanrDesign.accentDark,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.senderUid,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.text,
    required this.isMe,
    required this.onProfileTap,
  });

  final String? senderUid;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final bool isMe;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? PlanrDesign.accent
        : PlanrDesign.cardLight.withOpacity(0.92);

    final textColor = isMe ? Colors.white : PlanrDesign.ink;
    final metaColor = isMe ? Colors.white.withOpacity(0.82) : PlanrDesign.muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _TappableSenderAvatar(
              senderName: senderName,
              senderPhotoUrl: senderPhotoUrl,
              onTap: onProfileTap,
            ),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 20),
              ),
              child: InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 310),
                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 20),
                    ),
                    border: Border.all(
                      color: isMe
                          ? PlanrDesign.accentDark.withOpacity(0.18)
                          : Colors.white.withOpacity(0.95),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isMe ? 0.075 : 0.045),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        Text(
                          senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: metaColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TappableSenderAvatar extends StatelessWidget {
  const _TappableSenderAvatar({
    required this.senderName,
    required this.senderPhotoUrl,
    required this.onTap,
  });

  final String senderName;
  final String? senderPhotoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: PlanrAvatar(
            imageUrl: senderPhotoUrl,
            name: senderName,
            radius: 18,
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PlanrDesign.pagePadding,
          8,
          PlanrDesign.pagePadding,
          12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: PlanrDesign.cardLight.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.95),
                  ),
                  boxShadow: [PlanrDesign.softShadow],
                ),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  cursorColor: PlanrDesign.accent,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  decoration: InputDecoration(
                    hintText: enabled ? 'Write a message...' : 'Chat is disabled',
                    hintStyle: const TextStyle(
                      color: PlanrDesign.softMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 9),
            _SendButton(
              enabled: enabled,
              sending: sending,
              onTap: onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.sending,
    required this.onTap,
  });

  final bool enabled;
  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || sending;

    return Material(
      color: disabled
          ? PlanrDesign.softMuted.withOpacity(0.22)
          : PlanrDesign.accent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: disabled ? null : onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Center(
            child: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    color: disabled ? PlanrDesign.softMuted : Colors.white,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}