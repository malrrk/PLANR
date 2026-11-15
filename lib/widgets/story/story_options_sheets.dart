import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/plan_time.dart';
import '../../core/theme/planr_design.dart';
import '../../core/widgets/planr_avatar.dart';
import '../../models/event.dart';
import '../../models/story_audience.dart';
import '../../models/user_profile.dart';
import '../../providers/event_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/relationships_provider.dart';
import '../../providers/saved_events_provider.dart';
import '../event_cover.dart';

class StoryAudienceChoice {
  const StoryAudienceChoice(this.audience, this.selectedUids);

  final StoryAudience audience;
  final Set<String> selectedUids;
}

Future<StoryAudienceChoice?> showStoryAudienceSheet(
  BuildContext context, {
  required StoryAudienceChoice initial,
}) {
  return showModalBottomSheet<StoryAudienceChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) => _SheetFrame(child: _AudienceSheet(initial: initial)),
  );
}

Future<Event?> showStoryEventPicker(BuildContext context) {
  return showModalBottomSheet<Event>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) => const _SheetFrame(child: _EventPickerSheet()),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: PlanrDesign.cardLight,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
          boxShadow: [PlanrDesign.cardShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: PlanrDesign.softMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

class _AudienceSheet extends ConsumerStatefulWidget {
  const _AudienceSheet({required this.initial});

  final StoryAudienceChoice initial;

  @override
  ConsumerState<_AudienceSheet> createState() => _AudienceSheetState();
}

class _AudienceSheetState extends ConsumerState<_AudienceSheet> {
  late StoryAudience _audience = widget.initial.audience;
  late final Set<String> _selected = {...widget.initial.selectedUids};
  bool _pickingPeople = false;

  void _done() {
    Navigator.pop(context, StoryAudienceChoice(_audience, _selected));
  }

  @override
  Widget build(BuildContext context) {
    if (_pickingPeople) return _buildPeoplePicker();

    final closeCount = ref.watch(closeFriendUidsProvider).value?.length ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Who can see this?',
            style: TextStyle(
              color: PlanrDesign.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Only you know who is on your lists. Nobody gets a notification.',
          style: TextStyle(
            color: PlanrDesign.muted,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (final audience in StoryAudience.values)
          _AudienceTile(
            audience: audience,
            selected: _audience == audience,
            detail: switch (audience) {
              StoryAudience.close => closeCount == 0
                  ? 'Your close list is empty. Add people in Friends.'
                  : '$closeCount ${closeCount == 1 ? 'person' : 'people'} on your close list',
              StoryAudience.selected => _selected.isEmpty
                  ? audience.description
                  : '${_selected.length} chosen',
              _ => audience.description,
            },
            onTap: () => setState(() {
              _audience = audience;
              if (audience == StoryAudience.selected) _pickingPeople = true;
            }),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _audience == StoryAudience.selected && _selected.isEmpty
                ? null
                : _done,
            style: FilledButton.styleFrom(
              backgroundColor: PlanrDesign.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeoplePicker() {
    final friends = ref.watch(myFriendsProvider).value ?? const <UserProfile>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _pickingPeople = false),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const Expanded(
              child: Text(
                'Choose people',
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${_selected.length} chosen',
              style: const TextStyle(
                color: PlanrDesign.accentDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Flexible(
          child: friends.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Add friends first, then you can pick who sees your stories.',
                    style: TextStyle(color: PlanrDesign.muted),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    final checked = _selected.contains(friend.uid);

                    return CheckboxListTile(
                      value: checked,
                      activeColor: PlanrDesign.accent,
                      controlAffinity: ListTileControlAffinity.trailing,
                      contentPadding: EdgeInsets.zero,
                      secondary: PlanrAvatar(
                        imageUrl: friend.photoUrl,
                        name: friend.displayName,
                        radius: 20,
                      ),
                      title: Text(
                        friend.displayName,
                        style: const TextStyle(
                          color: PlanrDesign.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '@${friend.username}',
                        style: const TextStyle(color: PlanrDesign.muted),
                      ),
                      onChanged: (value) => setState(() {
                        if (value ?? false) {
                          _selected.add(friend.uid);
                        } else {
                          _selected.remove(friend.uid);
                        }
                      }),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _selected.isEmpty ? null : _done,
            style: FilledButton.styleFrom(
              backgroundColor: PlanrDesign.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _AudienceTile extends StatelessWidget {
  const _AudienceTile({
    required this.audience,
    required this.selected,
    required this.detail,
    required this.onTap,
  });

  final StoryAudience audience;
  final bool selected;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? PlanrDesign.accentSoft.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? PlanrDesign.accent.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.06),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? PlanrDesign.accent : PlanrDesign.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    audience.icon,
                    size: 21,
                    color: selected ? Colors.white : PlanrDesign.accentDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audience.label,
                        style: const TextStyle(
                          color: PlanrDesign.ink,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: const TextStyle(
                          color: PlanrDesign.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: PlanrDesign.accent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventPickerSheet extends ConsumerWidget {
  const _EventPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final byId = <String, Event>{};

    for (final event in [
      ...(ref.watch(savedEventsProvider).value ?? const <Event>[]),
      ...(ref.watch(myEventsProvider).value ?? const <Event>[])
          .where((event) => event.isPublicEvent),
    ]) {
      if (event.date.isAfter(now)) byId[event.id] = event;
    }

    final events = byId.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add an event',
          style: TextStyle(
            color: PlanrDesign.ink,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Friends can tap it to save the event or make a plan.',
          style: TextStyle(
            color: PlanrDesign.muted,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: events.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Save an event in Discover first and it will show up here.',
                    style: TextStyle(color: PlanrDesign.muted),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final event = events[index];

                    return ListTile(
                      onTap: () => Navigator.pop(context, event),
                      contentPadding: const EdgeInsets.all(6),
                      tileColor: Colors.white.withValues(alpha: 0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: EventCover(
                            imageUrl: event.imageUrl,
                            tags: event.tags,
                            iconSize: 22,
                          ),
                        ),
                      ),
                      title: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PlanrDesign.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        planTimeLabel(event.date),
                        style: const TextStyle(color: PlanrDesign.muted),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
