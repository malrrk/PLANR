import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/plan_time.dart';
import '../../core/theme/planr_design.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../providers/home_feed_provider.dart';
import '../../providers/saved_events_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../screens/event_detail_screen.dart';
import '../event_cover.dart';
import '../save_event_button.dart';
import 'home_section_header.dart';

class HomeDiscoverFallback extends ConsumerWidget {
  const HomeDiscoverFallback({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(aroundYourPeopleProvider);
    final peopleReady = people.hasValue && (people.value?.isEmpty ?? true);
    final interests = ref.watch(currentUserProfileProvider).value?.interests.toSet() ?? const <String>{};
    final hiddenIds = {
      ...(ref.watch(myEventsProvider).value ?? const <Event>[]).map((event) => event.id),
      ...(ref.watch(savedEventsProvider).value ?? const <Event>[]).map((event) => event.id),
      ...(people.value ?? const []).map((item) => item.event.id),
    };

    final now = DateTime.now();
    final popular =
        [
          ...(ref.watch(eventsProvider).value ?? const <Event>[]).where(
            (event) => event.date.isAfter(now) && !hiddenIds.contains(event.id),
          ),
        ]..sort((a, b) {
          final byGoing = b.attendeeCount.compareTo(a.attendeeCount);
          return byGoing != 0 ? byGoing : a.date.compareTo(b.date);
        });

    final matching = popular
      .where((event) => event.tags.any(interests.contains))
      .toList();
    final suggestions = matching.isNotEmpty ? matching : peopleReady ? popular : <Event>[];
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (suggestions.isNotEmpty) ...[
            HomeSectionHeader(
              title: matching.isNotEmpty ? 'Picked for you' : 'Popular right now',
              subtitle: matching.isNotEmpty ? 'Based on your interests' : 'What everyone is going to',
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                itemCount: suggestions.length > 6 ? 6 : suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) =>
                    _PopularCard(event: suggestions[index]),
              ),
            ),
          ],
        ],
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
        MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
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
