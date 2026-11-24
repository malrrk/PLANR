import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/plan_time.dart';
import '../../core/theme/planr_design.dart';
import '../../core/widgets/planr_background.dart';
import '../../core/widgets/planr_scaffold.dart';
import '../../models/event.dart';
import '../../providers/saved_events_provider.dart';
import '../../screens/event_detail_screen.dart';
import '../event_cover.dart';
import '../plans/plan_from_event.dart';
import '../save_event_button.dart';
import 'home_section_header.dart';

/// Events bookmarked in Discover. Saving is not attending; "Make a plan" is the next step.
class HomeSavedSection extends ConsumerWidget {
  const HomeSavedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final allSaved = ref.watch(savedEventsProvider).value ?? const <Event>[];
    final saved = allSaved
        .where((event) => event.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (allSaved.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(
            title: 'Saved for later',
            subtitle: saved.length == 1
                ? 'Turn your maybe into a plan'
                : '${saved.length} maybes. Pick one and invite someone.',
            trailing: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedEventsScreen()),
              ),
              child: const Text('See all'),
            ),
          ),
          if (saved.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
            height: 262,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: saved.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _SavedCard(event: saved[index]),
            ),
            ),
          ],
        ],
      ),
    );
  }
}

class SavedEventsScreen extends ConsumerWidget {
  const SavedEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedEventsProvider);
    return PlanrScaffold(
      title: 'Saved events',
      variant: PlanrBackgroundVariant.events,
      child: saved.when(
        data: (events) {
          if (events.isEmpty) return const Center(child: Text('No saved events.'));
          final sorted = [...events]..sort((first, second) => first.date.compareTo(second.date));
          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final event = sorted[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: EventCover(imageUrl: event.imageUrl, tags: event.tags),
                  ),
                ),
                title: Text(event.title),
                subtitle: Text(planTimeLabel(event.date)),
                trailing: SaveEventButton(event: event, onDark: false),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load saved events.')),
      ),
    );
  }
}

class _SavedCard extends ConsumerStatefulWidget {
  const _SavedCard({required this.event});

  final Event event;

  @override
  ConsumerState<_SavedCard> createState() => _SavedCardState();
}

class _SavedCardState extends ConsumerState<_SavedCard> {
  bool _starting = false;

  Future<void> _makePlan() async {
    if (_starting) return;

    setState(() => _starting = true);
    await startPlanFromEvent(context, ref, widget.event);
    if (mounted) setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(eventId: event.id),
        ),
      ),
      child: Container(
        width: 206,
        decoration: BoxDecoration(
          color: PlanrDesign.cardLight,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
          boxShadow: [PlanrDesign.softShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 118,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EventCover(imageUrl: event.imageUrl, tags: event.tags),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: SaveEventButton(event: event, size: 36),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        planTimeLabel(event.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 0),
              child: Text(
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
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton(
                  onPressed: _starting ? null : _makePlan,
                  style: FilledButton.styleFrom(
                    backgroundColor: PlanrDesign.accentSoft,
                    foregroundColor: PlanrDesign.accentDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _starting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text(
                          'Make a plan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
