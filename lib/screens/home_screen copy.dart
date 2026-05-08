/*import 'package:flutter/material.dart';

import '../widgets/home/events_near_you_section.dart';
import '../widgets/home/home_design.dart';
import '../widgets/home/my_events_section.dart';
import '../widgets/home/stories_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: HomeDesign.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: HomeDesign.pagePadding,
          title: const _HomeTitle(),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _RoundIconButton(
                icon: Icons.notifications_none_rounded,
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            HomeDesign.pagePadding,
            4,
            HomeDesign.pagePadding,
            28,
          ),
          children: const [
            _WelcomeHero(),
            SizedBox(height: 22),
            StoriesSection(),
            SizedBox(height: 24),
            MyEventsSection(),
            SizedBox(height: 24),
            EventsNearYouSection(),
          ],
        ),
      ),
    );
  }
}

class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'PLANR',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
        color: HomeDesign.ink,
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.78),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: HomeDesign.ink,
          ),
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: HomeDesign.cardDecoration(radius: 30),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: HomeDesign.brandGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: HomeDesign.primary.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find your next plan',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: HomeDesign.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Stories, invites and events picked for your social circle.',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.3,
                    color: HomeDesign.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/