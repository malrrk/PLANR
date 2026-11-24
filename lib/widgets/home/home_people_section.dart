import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/plan_time.dart';
import '../../core/theme/planr_design.dart';
import '../../core/widgets/planr_avatar.dart';
import '../../providers/home_feed_provider.dart';
import '../../providers/public_page_provider.dart';
import '../../screens/event_detail_screen.dart';
import '../../screens/public_page_screen.dart';
import '../event_cover.dart';
import '../save_event_button.dart';
import 'home_section_header.dart';

/// Events that matter because friends are going or a followed page hosts them.
class HomePeopleSection extends ConsumerWidget {
  const HomePeopleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(aroundYourPeopleProvider).value ?? const [];
    final pages = ref.watch(followedPagesProvider).value ?? const [];

    if (items.isEmpty && pages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pages.isNotEmpty) ...[
            const HomeSectionHeader(title: 'Following'),
            const SizedBox(height: 14),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pages.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return SizedBox(
                    width: 76,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PublicPageScreen(pageId: page.id),
                        ),
                      ),
                      child: Column(
                        children: [
                          PlanrAvatar(imageUrl: page.photoUrl, name: page.name, radius: 28),
                          const SizedBox(height: 6),
                          Text(
                            page.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: PlanrDesign.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (items.isNotEmpty) const SizedBox(height: 24),
          ],
          if (items.isNotEmpty) ...[
            const HomeSectionHeader(
              title: 'Your people are into',
              subtitle: 'Friends going and pages you follow',
            ),
            const SizedBox(height: 14),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PeopleRow(item: item),
              ),
          ],
        ],
      ),
    );
  }
}

class _PeopleRow extends StatelessWidget {
  const _PeopleRow({required this.item});

  final PeopleFeedItem item;

  String _reason() {
    final friends = item.friends;

    if (item.reason == PeopleFeedReason.followedPage) {
      return 'From ${item.event.publicOrganizerName}';
    }

    final first = friends.first.displayName.split(' ').first;
    if (friends.length == 1) return '$first is going';
    if (friends.length == 2) {
      return '$first and ${friends[1].displayName.split(' ').first} are going';
    }

    return '$first and ${friends.length - 1} others are going';
  }

  @override
  Widget build(BuildContext context) {
    final event = item.event;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: event.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: PlanrDesign.cardLight.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
            boxShadow: [PlanrDesign.softShadow],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: EventCover(
                    imageUrl: event.imageUrl,
                    tags: event.tags,
                    iconSize: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.reason == PeopleFeedReason.friendsGoing)
                          _FaceStack(friends: item.friends)
                        else
                          PlanrAvatar(
                            imageUrl: event.publicOrganizerPhotoUrl,
                            name: event.publicOrganizerName,
                            radius: 10,
                          ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _reason(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlanrDesign.accentDark,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 16.5,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      planTimeLabel(event.date),
                      style: const TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SaveEventButton(event: event, size: 38, onDark: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaceStack extends StatelessWidget {
  const _FaceStack({required this.friends});

  final List<GoingFriend> friends;

  @override
  Widget build(BuildContext context) {
    final shown = friends.take(3).toList();

    return SizedBox(
      width: 20.0 + (shown.length - 1) * 13,
      height: 20,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * 13.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: PlanrDesign.cardLight, width: 1.6),
                ),
                child: PlanrAvatar(
                  imageUrl: shown[i].photoUrl,
                  name: shown[i].displayName,
                  radius: 9,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
