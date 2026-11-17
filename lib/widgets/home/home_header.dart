import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_settings.dart';
import '../../core/theme/planr_design.dart';
import '../../providers/event_provider.dart';
import '../../providers/friends_provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      PlanrDesign.accentDark,
                      PlanrDesign.storyRingStart,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'PLANR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'SOCIAL PLANS. REAL CONNECTIONS.',
                    style: PlanrDesign.brandSubtitleStyle,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _BellButton(onTap: onNotificationTap),
          ),
        ],
      ),
    );
  }
}

class HomeRoundButton extends StatelessWidget {
  const HomeRoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.showDot = false,
    this.iconSize = 22,
    this.circleSize = 42,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool showDot;
  final double iconSize;
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: PlanrDesign.backgroundButton,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                        width: 1.1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: PlanrDesign.accent,
                      size: iconSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showDot)
            Positioned(
              right: 4,
              top: 3,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: PlanrDesign.storyRingStart,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PlanrDesign.backgroundButton,
                    width: 1.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BellButton extends ConsumerWidget {
  const _BellButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(pendingEventInvitesProvider);
    final friendRequestsAsync = ref.watch(incomingFriendRequestsProvider);
    final settings = AppSettings.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([
        settings.notifyInvites,
        settings.notifyFriendRequests,
      ]),
      builder: (context, _) {
        final inviteCount = !settings.notifyInvites.value
            ? 0
            : invitesAsync.maybeWhen(
                data: (invites) => invites.length,
                orElse: () => 0,
              );

        final requestCount = !settings.notifyFriendRequests.value
            ? 0
            : friendRequestsAsync.maybeWhen(
                data: (requests) => requests.length,
                orElse: () => 0,
              );

        return HomeRoundButton(
          icon: Icons.notifications_none_rounded,
          iconSize: 19,
          circleSize: 36,
          tooltip: 'Notifications',
          showDot: inviteCount + requestCount > 0,
          onTap: onTap,
        );
      },
    );
  }
}
