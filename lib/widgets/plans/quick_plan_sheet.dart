import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/plan_time.dart';
import '../../core/theme/planr_design.dart';
import '../../core/widgets/planr_avatar.dart';
import '../../models/user_profile.dart';
import '../../providers/event_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/relationships_provider.dart';
import '../../screens/create_event_screen.dart';

Future<void> showQuickPlanSheet(
  BuildContext context, {
  String? initialTitle,
  String? initialPlace,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (_) => QuickPlanSheet(
      initialTitle: initialTitle,
      initialPlace: initialPlace,
    ),
  );
}

class _Vibe {
  const _Vibe(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _vibes = [
  _Vibe('Coffee', Icons.local_cafe_rounded),
  _Vibe('Food', Icons.restaurant_rounded),
  _Vibe('Drinks', Icons.sports_bar_rounded),
  _Vibe('Party', Icons.celebration_rounded),
  _Vibe('Sport', Icons.sports_soccer_rounded),
  _Vibe('Study', Icons.menu_book_rounded),
  _Vibe('Walk', Icons.directions_walk_rounded),
  _Vibe('Movie', Icons.movie_rounded),
];

/// Make a plan in a few taps: what, when, who. "More options" opens the full form.
class QuickPlanSheet extends ConsumerStatefulWidget {
  const QuickPlanSheet({
    super.key,
    this.initialTitle,
    this.initialPlace,
  });

  final String? initialTitle;
  final String? initialPlace;

  @override
  ConsumerState<QuickPlanSheet> createState() => _QuickPlanSheetState();
}

class _QuickPlanSheetState extends ConsumerState<QuickPlanSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _placeController;
  late final List<QuickTimeOption> _options;

  final Set<String> _inviteeUids = {};

  late DateTime _selectedDate;
  bool _customDate = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _placeController = TextEditingController(text: widget.initialPlace ?? '');
    _options = quickTimeOptions(DateTime.now());
    _selectedDate = _options.first.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _titleController.text.trim().isNotEmpty && _selectedDate.isAfter(DateTime.now());

  void _pickVibe(_Vibe vibe) {
    HapticFeedback.selectionClick();

    final current = _titleController.text.trim();
    final isVibeTitle = _vibes.any((v) => v.label == current);

    if (current.isEmpty || isVibeTitle) {
      setState(() => _titleController.text = vibe.label);
    }
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();

    ThemeData themed(BuildContext context) => Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: PlanrDesign.accent,
              ),
        );

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) =>
          Theme(data: themed(context), child: child!),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) =>
          Theme(data: themed(context), child: child!),
    );
    if (time == null) return;

    setState(() {
      _customDate = true;
      _selectedDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _send(List<UserProfile> friends) async {
    if (!_canSend || _sending) return;

    setState(() => _sending = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final invitees =
        friends.where((friend) => _inviteeUids.contains(friend.uid)).toList();

    final error = await ref.read(eventServiceProvider).createQuickPlan(
          title: _titleController.text.trim(),
          date: _selectedDate,
          place: _placeController.text,
          invitees: invitees,
        );

    if (!mounted) return;

    if (error != null) {
      setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    HapticFeedback.mediumImpact();
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          invitees.isEmpty
              ? 'Plan created. Invite friends any time.'
              : invitees.length == 1
                  ? "You're on! Invite sent to ${invitees.first.displayName}."
                  : "You're on! Invites sent to ${invitees.length} friends.",
        ),
      ),
    );
  }

  void _openFullForm(List<UserProfile> friends) {
    final navigator = Navigator.of(context);
    final title = _titleController.text.trim();
    final place = _placeController.text.trim();
    final date = _selectedDate.isAfter(DateTime.now()) ? _selectedDate : null;

    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(
          initialTitle: title,
          initialPlace: place,
          initialDate: date,
          startPrivate: true,
          initialInvitees: friends.where((friend) => _inviteeUids.contains(friend.uid)).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(myFriendsProvider);
    final closeUids = ref.watch(closeFriendUidsProvider).value ?? const <String>{};
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final friends = [...(friendsAsync.value ?? const <UserProfile>[])]
      ..sort((a, b) {
        final byClose = (closeUids.contains(b.uid) ? 1 : 0)
            .compareTo(closeUids.contains(a.uid) ? 1 : 0);
        if (byClose != 0) return byClose;
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 10 + bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: PlanrDesign.cardLight,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
          boxShadow: [PlanrDesign.cardShadow],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: PlanrDesign.softMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "What's the plan?",
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pick a vibe, a time and your people. Done in seconds.',
                style: TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _vibes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final vibe = _vibes[index];
                    final selected =
                        _titleController.text.trim() == vibe.label;

                    return _SheetChip(
                      label: vibe.label,
                      icon: vibe.icon,
                      selected: selected,
                      onTap: () => _pickVibe(vibe),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: _titleController,
                hint: 'Coffee at the Burgberg, movie night...',
                icon: Icons.edit_rounded,
                maxLength: 80,
                autofocus: widget.initialTitle == null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              const _SheetLabel('When'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in _options)
                    _SheetChip(
                      label: option.label,
                      selected: !_customDate &&
                          _selectedDate == option.date,
                      onTap: () => setState(() {
                        _customDate = false;
                        _selectedDate = option.date;
                      }),
                    ),
                  _SheetChip(
                    label: _customDate
                        ? planTimeLabel(_selectedDate)
                        : 'Pick a time',
                    icon: Icons.event_rounded,
                    selected: _customDate,
                    onTap: _pickCustomDate,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _SheetLabel('Where (optional)'),
              const SizedBox(height: 8),
              _SheetField(
                controller: _placeController,
                hint: 'A place, or decide later',
                icon: Icons.place_rounded,
                maxLength: 120,
              ),
              const SizedBox(height: 18),
              _SheetLabel(
                _inviteeUids.isEmpty
                    ? 'Who is invited?'
                    : 'Inviting ${_inviteeUids.length}',
              ),
              const SizedBox(height: 10),
              if (friends.isEmpty)
                const Text(
                  'Add friends to invite them. You can still create the plan now.',
                  style: TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: friends.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final selected = _inviteeUids.contains(friend.uid);

                      return _FriendPick(
                        friend: friend,
                        selected: selected,
                        isClose: closeUids.contains(friend.uid),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (selected) {
                              _inviteeUids.remove(friend.uid);
                            } else {
                              _inviteeUids.add(friend.uid);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: _sending ? null : () => _openFullForm(friends),
                    child: const Text(
                      'More options',
                      style: TextStyle(
                        color: PlanrDesign.accentDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _canSend && !_sending
                            ? () => _send(friends)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: PlanrDesign.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _inviteeUids.isEmpty
                                    ? 'Create plan'
                                    : 'Send plan',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: PlanrDesign.ink,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLength,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int? maxLength;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLength: maxLength,
        onChanged: onChanged,
        cursorColor: PlanrDesign.accent,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          color: PlanrDesign.ink,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          icon: Icon(icon, color: PlanrDesign.accentDark, size: 21),
          hintText: hint,
          hintStyle: const TextStyle(
            color: PlanrDesign.softMuted,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : PlanrDesign.ink;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? PlanrDesign.accent
                : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? PlanrDesign.accentDark.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : PlanrDesign.accentDark,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendPick extends StatelessWidget {
  const _FriendPick({
    required this.friend,
    required this.selected,
    required this.isClose,
    required this.onTap,
  });

  final UserProfile friend;
  final bool selected;
  final bool isClose;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? PlanrDesign.accent : Colors.transparent,
                      width: 2.4,
                    ),
                  ),
                  child: PlanrAvatar(
                    imageUrl: friend.photoUrl,
                    name: friend.displayName,
                    radius: 24,
                  ),
                ),
                if (selected)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: PlanrDesign.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (isClose)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: PlanrDesign.storyRingStart,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              friend.displayName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? PlanrDesign.accentDark : PlanrDesign.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
