import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/plan_time.dart';
import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../models/event.dart';
import '../models/event_schedule.dart';
import '../providers/event_provider.dart';
import '../widgets/home/my_event_mini_card.dart';
import '../widgets/plans/quick_plan_sheet.dart';
import 'event_chat_screen.dart';
import 'event_detail_screen.dart';

/// Every plan on a month calendar, with the plans of the selected day and past plans below.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  late DateTime _month;
  late DateTime _selected;
  bool _showPast = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  void _goToday() {
    final now = DateTime.now();

    setState(() {
      _selected = DateTime(now.year, now.month, now.day);
      _month = DateTime(now.year, now.month);
    });
  }

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
    );
  }

  void _openChat(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventChatScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final events = ref.watch(myEventsProvider).value ?? const <Event>[];
    final now = DateTime.now();

    final daysWithPlans = <DateTime>{
      for (final event in events)
        DateTime(event.date.year, event.date.month, event.date.day),
    };

    final selectedEvents = events
        .where((event) => isSameDay(event.date, _selected))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final past = pastEvents(events, now: now).take(12).toList();

    return PlanrBackground(
      variant: PlanrBackgroundVariant.events,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              PlanrDesign.pagePadding,
              8,
              PlanrDesign.pagePadding,
              40,
            ),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: PlanrDesign.ink,
                  ),
                  const Expanded(
                    child: Text(
                      'Your calendar',
                      style: TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _goToday,
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        color: PlanrDesign.accentDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                decoration: PlanrDesign.cardDecoration(radius: 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _shiftMonth(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: PlanrDesign.ink,
                        ),
                        Expanded(
                          child: Text(
                            DateFormat.yMMMM(locale).format(_month),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: PlanrDesign.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _shiftMonth(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: PlanrDesign.ink,
                        ),
                      ],
                    ),
                    _MonthGrid(
                      month: _month,
                      selected: _selected,
                      today: now,
                      daysWithPlans: daysWithPlans,
                      onSelect: (day) => setState(() => _selected = day),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                DateFormat.MMMMEEEEd(locale).format(_selected),
                style: const TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              if (selectedEvents.isEmpty)
                _EmptyDay(
                  isPast: _selected.isBefore(DateTime(now.year, now.month, now.day)),
                  onPlan: () => showQuickPlanSheet(context),
                )
              else
                for (final event in selectedEvents)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MyEventMiniCard(
                      event: event,
                      onTap: () => _openEvent(event),
                      onChatTap:
                          event.chatEnabled ? () => _openChat(event) : null,
                    ),
                  ),
              if (past.isNotEmpty) ...[
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => setState(() => _showPast = !_showPast),
                  child: Row(
                    children: [
                      Text(
                        _showPast ? 'Hide past plans' : 'Past plans (${past.length})',
                        style: const TextStyle(
                          color: PlanrDesign.accentDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Icon(
                        _showPast
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: PlanrDesign.accentDark,
                      ),
                    ],
                  ),
                ),
                if (_showPast) ...[
                  const SizedBox(height: 10),
                  for (final event in past)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MyEventMiniCard(
                        event: event,
                        onTap: () => _openEvent(event),
                        onChatTap:
                            event.chatEnabled ? () => _openChat(event) : null,
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.today,
    required this.daysWithPlans,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final Set<DateTime> daysWithPlans;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final leading = first.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cellCount = ((leading + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: [
        Row(
          children: [
            for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: PlanrDesign.softMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < cellCount / 7; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _buildCell(row * 7 + col - leading + 1, daysInMonth),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(int dayNumber, int daysInMonth) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 46);
    }

    final day = DateTime(month.year, month.month, dayNumber);
    final isSelected = day == selected;
    final isToday = isSameDay(day, today);
    final hasPlans = daysWithPlans.contains(day);

    return GestureDetector(
      onTap: () => onSelect(day),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 46,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? PlanrDesign.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: PlanrDesign.accent, width: 1.6)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: isSelected ? Colors.white : PlanrDesign.ink,
                    fontSize: 15,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w900
                        : FontWeight.w700,
                  ),
                ),
                if (hasPlans)
                  Positioned(
                    bottom: 5,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : PlanrDesign.storyRingStart,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.isPast, required this.onPlan});

  final bool isPast;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: PlanrDesign.cardDecoration(radius: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isPast ? 'No plans on this day.' : 'Nothing planned. Fancy something?',
              style: const TextStyle(
                color: PlanrDesign.muted,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!isPast)
            FilledButton(
              onPressed: onPlan,
              style: FilledButton.styleFrom(
                backgroundColor: PlanrDesign.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Make a plan',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
    );
  }
}
