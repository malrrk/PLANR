import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../screens/create_story_screen.dart';
import '../screens/notification_center_screen.dart';
import '../widgets/home/events_near_you_section.dart';
import '../widgets/home/my_events_section.dart';
import '../widgets/home/stories_section.dart';
import '../core/widgets/planr_background.dart';
import '../providers/event_provider.dart';
import '../providers/friends_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onOpenMyPlanr,
  });

  final VoidCallback? onOpenMyPlanr;

  void _openCreateStory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateStoryScreen(),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationCenterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlanrBackground(
      variant: PlanrBackgroundVariant.home,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              PlanrDesign.pagePadding,
              14,
              PlanrDesign.pagePadding,
              118,
            ),
            children: [
              _PlanrHeaderRow(
                onNotificationTap: () => _openNotifications(context),
              ),
              const SizedBox(height: 26),
              StoriesSection(
                onCreateStory: () => _openCreateStory(context),
              ),
              const SizedBox(height: 16),
              MyEventsSection(
                onOpenMyPlanr: onOpenMyPlanr,
              ),
              const SizedBox(height: 30),
              const EventsNearYouSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BellButton extends ConsumerWidget {
  const _BellButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(pendingEventInvitesProvider);
    final friendRequestsAsync = ref.watch(incomingFriendRequestsProvider);

    final inviteCount = invitesAsync.maybeWhen(
      data: (invites) => invites.length,
      orElse: () => 0,
    );

    final friendRequestCount = friendRequestsAsync.maybeWhen(
      data: (requests) => requests.length,
      orElse: () => 0,
    );

    final hasNotifications = inviteCount + friendRequestCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: PlanrDesign.backgroundButton,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.12),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: PlanrDesign.accent,
                size: 20,
              ),
            ),
          ),
        ),
        if (hasNotifications)
          Positioned(
            right: 3,
            top: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: PlanrDesign.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: PlanrDesign.backgroundButton,
                  width: 1.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanrHeaderRow extends StatelessWidget {
  const _PlanrHeaderRow({
    required this.onNotificationTap,
  });

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PLANR',
                textAlign: TextAlign.center,
                style: PlanrDesign.brandTitleStyle,
              ),
              SizedBox(height: 8),
              Text(
                'SOCIAL PLANS. REAL CONNECTIONS.',
                textAlign: TextAlign.center,
                style: PlanrDesign.brandSubtitleStyle,
              ),
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: _BellButton(
              onTap: onNotificationTap,
            ),
          ),
        ],
      ),
    );
  }
}