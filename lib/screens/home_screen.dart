import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/fade_slide_in.dart';
import '../core/widgets/planr_background.dart';
import '../providers/home_feed_provider.dart';
import '../widgets/home/home_discover_fallback.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_invitations_section.dart';
import '../widgets/home/home_next_up_section.dart';
import '../widgets/home/home_people_section.dart';
import '../widgets/home/home_saved_section.dart';
import '../widgets/home/home_stories_row.dart';
import 'notification_center_screen.dart';

/// Home is personal: my stories, my plans, my people. Sections hide when they are empty.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(aroundYourPeopleProvider);

    try {
      await ref.read(aroundYourPeopleProvider.future);
    } catch (_) {
      // The section simply stays hidden when it cannot load.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlanrBackground(
      variant: PlanrBackgroundVariant.home,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: PlanrDesign.accent,
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                PlanrDesign.pagePadding,
                10,
                PlanrDesign.pagePadding,
                124,
              ),
              children: [
                FadeSlideIn(
                  child: HomeHeader(
                    onNotificationTap: () =>
                        _push(context, const NotificationCenterScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 120),
                  child: HomeStoriesRow(),
                ),
                const SizedBox(height: 22),
                const HomeInvitationsSection(),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 180),
                  child: HomeNextUpSection(),
                ),
                const HomeSavedSection(),
                const HomePeopleSection(),
                const HomeDiscoverFallback(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
