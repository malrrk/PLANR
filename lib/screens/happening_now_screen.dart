import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/plan_time.dart';
import '../core/theme/planr_design.dart';
import '../core/widgets/planr_avatar.dart';
import '../models/event.dart';
import '../providers/public_page_provider.dart';
import '../widgets/attendee_preview.dart';
import '../widgets/event_cover.dart';
import '../widgets/plans/plan_from_event.dart';
import '../widgets/plans/quick_plan_sheet.dart';
import '../widgets/save_event_button.dart';
import 'event_detail_screen.dart';

/// A short, finite vertical feed of what is on in the next hours.
/// It ends with a "caught up" card on purpose, so it never turns into endless scrolling.
class HappeningNowScreen extends StatefulWidget {
  const HappeningNowScreen({super.key, required this.events});

  static const maxEvents = 15;

  final List<Event> events;

  @override
  State<HappeningNowScreen> createState() => _HappeningNowScreenState();
}

class _HappeningNowScreenState extends State<HappeningNowScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    final lastIndex = events.length;
    final onEndCard = _page == lastIndex;

    return Scaffold(
      backgroundColor: PlanrDesign.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            itemCount: events.length + 1,
            onPageChanged: (page) {
              HapticFeedback.selectionClick();
              setState(() => _page = page);
            },
            itemBuilder: (context, index) {
              if (index == events.length) {
                return _CaughtUpPage(count: events.length);
              }

              return _EventPage(event: events[index]);
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 16, 0),
              child: Row(
                children: [
                  _RoundIcon(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (!onEndCard)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_page + 1} of ${events.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap, this.label});

  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _EventPage extends ConsumerWidget {
  const _EventPage({required this.event});

  final Event event;

  String _sectionLabel(DateTime now) {
    if (event.date.isBefore(now.add(const Duration(hours: 3)))) {
      return 'STARTING SOON';
    }
    if (isSameDay(event.date, now)) {
      return event.date.hour >= 17 ? 'TONIGHT' : 'TODAY';
    }
    return 'TOMORROW';
  }

  Future<void> _share(BuildContext context) async {
    final address = event.address.trim();
    final text = [
      event.title,
      planTimeLabel(event.date),
      if (address.isNotEmpty) address,
      'Found on PLANR',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Details copied. Paste them into any chat.')),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final address = event.address.trim();

    return Stack(
      fit: StackFit.expand,
      children: [
        EventCover(imageUrl: event.imageUrl, tags: event.tags, iconSize: 80),
        const EventScrim(),
        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: PlanrDesign.storyRingGradient,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _sectionLabel(now),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _OrganizerRow(event: event),
                        const SizedBox(height: 10),
                        Text(
                          event.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          [
                            planTimeLabel(event.date, now: now),
                            if (address.isNotEmpty) address,
                          ].join('  ·  '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AttendeePreview(
                          eventId: event.id,
                          attendeeCount: event.attendeeCount,
                          preferFriends: true,
                          dark: true,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      startPlanFromEvent(context, ref, event),
                                  icon: const Icon(Icons.group_add_rounded),
                                  label: const Text(
                                    'Make a plan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: PlanrDesign.accent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EventDetailScreen(eventId: event.id),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    width: 1.4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text(
                                  'Details',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SaveEventButton(event: event, size: 52),
                      const SizedBox(height: 14),
                      _RoundIcon(
                        icon: Icons.ios_share_rounded,
                        label: 'Copy event details',
                        onTap: () => _share(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrganizerRow extends ConsumerWidget {
  const _OrganizerRow({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPage = event.isOrganizedByPage;
    final following = isPage
        ? (ref.watch(isFollowingPageProvider(event.organizerId)).value ?? false)
        : false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlanrAvatar(
          imageUrl: event.publicOrganizerPhotoUrl,
          name: event.publicOrganizerName,
          radius: 14,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            event.publicOrganizerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (isPage) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final service = ref.read(publicPageServiceProvider);
              final page =
                  await ref.read(publicPageByIdProvider(event.organizerId).future);
              if (page == null) return;

              HapticFeedback.lightImpact();
              final error = following
                  ? await service.unfollowPage(page)
                  : await service.followPage(page);

              if (error != null) {
                messenger.showSnackBar(SnackBar(content: Text(error)));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: following
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                following ? 'Following' : 'Follow',
                style: TextStyle(
                  color: following ? Colors.white : PlanrDesign.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CaughtUpPage extends StatelessWidget {
  const _CaughtUpPage({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: PlanrDesign.brandGradient),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: PlanrDesign.accent,
                size: 46,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "You're all caught up",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.9,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              count == 0
                  ? 'Nothing is on in the next hours.'
                  : "That's everything on in the next hours. Pick one and take a friend along.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: PlanrDesign.accentDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Back to Discover',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => showQuickPlanSheet(context),
              child: const Text(
                'Or start your own plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
