import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_settings.dart';
import '../../core/theme/planr_design.dart';
import '../../providers/event_provider.dart';
import '../../providers/friends_provider.dart';

/// Compact top bar: brand on the left, calendar and notifications on the right.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onCalendarTap,
    required this.onNotificationTap,
  });

  final VoidCallback onCalendarTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [PlanrDesign.accentDark, PlanrDesign.storyRingStart],
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
          const Spacer(),
          HomeRoundButton(
            icon: Icons.calendar_month_rounded,
            tooltip: 'Calendar',
            onTap: onCalendarTap,
          ),
          const SizedBox(width: 10),
          _BellButton(onTap: onNotificationTap),
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
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: PlanrDesign.backgroundButton,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                    width: 1.1,
                  ),
                ),
                child: Icon(icon, color: PlanrDesign.accent, size: 22),
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
      listenable: Listenable.merge(
        [settings.notifyInvites, settings.notifyFriendRequests],
      ),
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
          tooltip: 'Notifications',
          showDot: inviteCount + requestCount > 0,
          onTap: onTap,
        );
      },
    );
  }
}
