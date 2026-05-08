import 'package:flutter/material.dart';

import '../screens/create_story_screen.dart';
import '../widgets/home/events_near_you_section.dart';
import '../widgets/home/home_design.dart';
import '../widgets/home/my_events_section.dart';
import '../widgets/home/stories_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
    return Container(
      decoration: const BoxDecoration(
        gradient: HomeDesign.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  HomeDesign.pagePadding,
                  14,
                  HomeDesign.pagePadding,
                  118,
                ),
                children: [
                  const _PlanrHeaderRow(),
                  const SizedBox(height: 26),
                  StoriesSection(
                    onCreateStory: () => _openCreateStory(context),
                  ),
                  const SizedBox(height: 16), // changeable
                  const MyEventsSection(),
                  const SizedBox(height: 30),
                  const EventsNearYouSection(),
                ],
              ),
            ),
          ],
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
            color: HomeDesign.backgroundButton,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withOpacity(0.12),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: HomeDesign.accent,
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
              color: HomeDesign.accent,
              shape: BoxShape.circle,
              border: Border.all(
                color: HomeDesign.backgroundButton,
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
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'PLANR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HomeDesign.accentDark,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  height: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'SOCIAL PLANS. REAL CONNECTIONS.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                  color: HomeDesign.muted,
                  height: 1,
                ),
              ),
            ],
          ),
          const Align(
            alignment: Alignment.topRight,
            child: _BellButton(),
          ),
        ],
      ),
    );
  }
}