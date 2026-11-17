import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../l10n/l10n.dart';
import '../providers/event_provider.dart';
import '../widgets/plans/quick_plan_sheet.dart';
import 'chats_screen.dart';
import 'discover_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _selectTab(int index) {
    setState(() {
      _index = index;
    });
  }

  void _openQuickPlan() {
    showQuickPlanSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const DiscoverScreen(),
      const ChatsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: screens[_index],
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: _PlanrBottomNav(
          selectedIndex: _index,
          onHomeTap: () => _selectTab(0),
          onEventsTap: () => _selectTab(1),
          onCreateTap: _openQuickPlan,
          onChatsTap: () => _selectTab(2),
          onProfileTap: () => _selectTab(3),
        ),
      ),
    );
  }
}

class _PlanrBottomNav extends ConsumerWidget {
  const _PlanrBottomNav({
    required this.selectedIndex,
    required this.onHomeTap,
    required this.onEventsTap,
    required this.onCreateTap,
    required this.onChatsTap,
    required this.onProfileTap,
  });

  final int selectedIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onEventsTap;
  final VoidCallback onCreateTap;
  final VoidCallback onChatsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnreadChat = ref.watch(myEventsProvider).maybeWhen(
          data: (events) => events.any((event) => event.hasUnreadMessages),
          orElse: () => false,
        );

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BottomNavItem(
              icon: Icons.home_rounded,
              label: context.l10n.navHome,
              selected: selectedIndex == 0,
              onTap: onHomeTap,
            ),
          ),
          Expanded(
            child: _BottomNavItem(
              icon: Icons.search_rounded,
              label: context.l10n.navDiscover,
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
              icon: selectedIndex == 2
                  ? Icons.forum_rounded
                  : Icons.forum_outlined,
              label: context.l10n.navChats,
              selected: selectedIndex == 2,
              showDot: hasUnreadChat && selectedIndex != 2,
              onTap: onChatsTap,
            ),
          ),
          Expanded(
            child: _BottomNavItem(
              icon: Icons.person_outline_rounded,
              label: context.l10n.navProfile,
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
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? PlanrDesign.accent : const Color(0xFF716B65);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: selected ? 29 : 27,
                ),
                if (showDot)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: PlanrDesign.storyRingStart,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.6),
                      ),
                    ),
                  ),
              ],
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
              color: PlanrDesign.accent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: PlanrDesign.accent.withValues(alpha: 0.25),
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
          Text(
            context.l10n.navCreate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlanrDesign.accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}