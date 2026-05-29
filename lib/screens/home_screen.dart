import 'package:flutter/material.dart';

import '../core/theme/planr_design.dart';
import '../screens/create_story_screen.dart';
import '../widgets/home/events_near_you_section.dart';
import '../widgets/home/my_events_section.dart';
import '../widgets/home/stories_section.dart';
import '../core/widgets/planr_background.dart';

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
              const _PlanrHeaderRow(),
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

class _BellButton extends StatelessWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PlanrDesign.backgroundButton,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withOpacity(0.12),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: PlanrDesign.accent,
            size: 20,
          ),
        ),
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
  const _PlanrHeaderRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Column(
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
            child: _BellButton(),
          ),
        ],
      ),
    );
  }
}