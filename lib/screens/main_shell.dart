import 'package:flutter/material.dart';

import '../widgets/home/home_design.dart';
import 'create_event_screen.dart';
import 'events_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'stories_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    EventsScreen(),
    StoriesScreen(),
    ProfileScreen(),
  ];

  void _selectTab(int index) {
    setState(() {
      _index = index;
    });
  }

  void _openCreateEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateEventScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_index],
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: _PlanrBottomNav(
          selectedIndex: _index,
          onHomeTap: () => _selectTab(0),
          onEventsTap: () => _selectTab(1),
          onCreateTap: _openCreateEvent,
          onStoriesTap: () => _selectTab(2),
          onProfileTap: () => _selectTab(3),
        ),
      ),
    );
  }
}

class _PlanrBottomNav extends StatelessWidget {
  const _PlanrBottomNav({
    required this.selectedIndex,
    required this.onHomeTap,
    required this.onEventsTap,
    required this.onCreateTap,
    required this.onStoriesTap,
    required this.onProfileTap,
  });

  final int selectedIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onEventsTap;
  final VoidCallback onCreateTap;
  final VoidCallback onStoriesTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BottomNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: selectedIndex == 0,
              onTap: onHomeTap,
            ),
          ),
          Expanded(
            child: _BottomNavItem(
              icon: Icons.search_rounded,
              label: 'Discover',
              selected: selectedIndex == 1,
              onTap: onEventsTap,
            ),
          ),
          Expanded(
            child: _BottomCreateItem(
              onTap: onCreateTap,
            ),
          ),
          Expanded(
            child: _BottomNavItem(
              icon: Icons.auto_stories_rounded,
              label: 'Stories',
              selected: selectedIndex == 2,
              onTap: onStoriesTap,
            ),
          ),
          Expanded(
            child: _BottomNavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: selectedIndex == 3,
              onTap: onProfileTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? HomeDesign.accent : const Color(0xFF716B65);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: selected ? 29 : 27,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCreateItem extends StatelessWidget {
  const _BottomCreateItem({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 46,
            decoration: BoxDecoration(
              color: HomeDesign.accent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: HomeDesign.accent.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: HomeDesign.accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}