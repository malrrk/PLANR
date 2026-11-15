import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/plan_time.dart';
import '../../core/theme/planr_design.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/home_feed_provider.dart';
import '../../screens/event_detail_screen.dart';
import '../../screens/user_search_screen.dart';
import '../event_cover.dart';
import '../save_event_button.dart';
import 'home_section_header.dart';

/// Keeps Home alive for new users: a nudge to find friends and a few popular events.
/// It only appears while the personal sections have nothing to show.
class HomeDiscoverFallback extends ConsumerWidget {
  const HomeDiscoverFallback({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(aroundYourPeopleProvider);
    final peopleReady = people.hasValue && (people.value?.isEmpty ?? true);
    if (!peopleReady) return const SizedBox.shrink();

    final friends = ref.watch(myFriendsProvider).value;
    final now = DateTime.now();
    final popular = [
      ...(ref.watch(eventsProvider).value ?? const <Event>[])
          .where((event) => event.date.isAfter(now)),
    ]..sort((a, b) {
        final byGoing = b.attendeeCount.compareTo(a.attendeeCount);
        return byGoing != 0 ? byGoing : a.date.compareTo(b.date);
      });

    final noFriends = friends != null && friends.isEmpty;

    if (!noFriends && popular.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (noFriends) ...[
            _FindFriendsCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSearchScreen()),
              ),
            ),
            const SizedBox(height: 26),
          ],
          if (popular.isNotEmpty) ...[
            const HomeSectionHeader(
              title: 'Popular right now',
              subtitle: 'What everyone is going to',
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                itemCount: popular.length > 6 ? 6 : popular.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) =>
                    _PopularCard(event: popular[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FindFriendsCard extends StatelessWidget {
  const _FindFriendsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: PlanrDesign.brandGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: PlanrDesign.accent.withValues(alpha: 0.25),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plans are better together',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Find your friends and see what they are up to.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: PlanrDesign.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(eventId: event.id),
        ),
      ),
      child: Container(
        width: 232,
        decoration: BoxDecoration(
          color: PlanrDesign.ink,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [PlanrDesign.softShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            EventCover(imageUrl: event.imageUrl, tags: event.tags),
            const EventScrim(),
            Positioned(
              top: 10,
              right: 10,
              child: SaveEventButton(event: event, size: 36),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 13,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${planTimeLabel(event.date)}  ·  ${event.attendeeCount} going',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
