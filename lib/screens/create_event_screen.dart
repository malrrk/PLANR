import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_scaffold.dart';
import '../core/widgets/planr_text_field.dart';
import '../providers/event_provider.dart';
import '../widgets/event_tag_selector.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _imagePath;
  bool _saving = false;

  String _visibility = 'public';
  bool _chatEnabled = true;
  bool _guestsCanInvite = true;

  List<String> _selectedTagIds = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null) return;

    setState(() {
      _imagePath = file.path;
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now)
          ? now.add(const Duration(days: 1))
          : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: PlanrDesign.accent,
                  secondary: PlanrDesign.eventMetaOrange,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: PlanrDesign.accent,
                  secondary: PlanrDesign.eventMetaOrange,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _createEvent() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || description.isEmpty || location.isEmpty) {
      _showSnackBar('Please fill in all fields.');
      return;
    }

    if (_selectedTagIds.isEmpty) {
      _showSnackBar('Please choose at least one tag.');
      return;
    }

    setState(() {
      _saving = true;
    });

    final error = await ref.read(eventServiceProvider).createEvent(
          title: title,
          description: description,
          address: location,
          tags: _selectedTagIds,
          date: _selectedDate,
          visibility: _visibility,
          chatEnabled: _chatEnabled,
          guestsCanInvite: _guestsCanInvite,
          imageFile: _imagePath != null ? File(_imagePath!) : null,
        );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    Navigator.pop(context);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String get _formattedDate {
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final year = _selectedDate.year.toString();
    final hour = _selectedDate.hour.toString().padLeft(2, '0');
    final minute = _selectedDate.minute.toString().padLeft(2, '0');

    return '$day.$month.$year · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return PlanrScaffold(
      title: 'Create Event',
      variant: PlanrBackgroundVariant.create,
      resizeToAvoidBottomInset: true,
      child: ListView(
        children: [
          _ImagePickerCard(
            imagePath: _imagePath,
            onTap: _pickImage,
          ),
          const SizedBox(height: 18),

          PlanrCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                PlanrTextField(
                  controller: _titleController,
                  label: 'Title',
                  hintText: 'e.g. Friday house party',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.edit_rounded,
                ),
                const SizedBox(height: 16),
                PlanrTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hintText: 'Tell people what the vibe is.',
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 16),
                PlanrTextField(
                  controller: _locationController,
                  label: 'Location',
                  hintText: 'Where is it happening?',
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.place_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          PlanrCard(
            padding: const EdgeInsets.all(18),
            child: EventTagSelector(
              selectedTagIds: _selectedTagIds,
              requireAtLeastOne: true,
              onChanged: (tagIds) {
                setState(() {
                  _selectedTagIds = tagIds;
                });
              },
            ),
          ),

          const SizedBox(height: 18),

          PlanrCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.calendar_month_rounded,
                  title: 'Date & Time',
                  subtitle: _formattedDate,
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 16),
                _VisibilitySelector(
                  value: _visibility,
                  onChanged: (value) {
                    setState(() {
                      _visibility = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          PlanrCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _SettingsToggle(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Enable event chat',
                  subtitle: 'People who join can write in the event chat.',
                  value: _chatEnabled,
                  onChanged: (value) {
                    setState(() {
                      _chatEnabled = value;
                    });
                  },
                ),
                if (_visibility == 'private') ...[
                  const SizedBox(height: 14),
                  _SettingsToggle(
                    icon: Icons.group_add_rounded,
                    title: 'Guests can invite others',
                    subtitle: 'Attendees can bring more people into this event.',
                    value: _guestsCanInvite,
                    onChanged: (value) {
                      setState(() {
                        _guestsCanInvite = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          PlanrButton(
            label: _saving ? 'Creating...' : 'Create Event',
            icon: Icons.add_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _createEvent,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.imagePath,
    required this.onTap,
  });

  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 232,
        decoration: BoxDecoration(
          color: PlanrDesign.card.withOpacity(0.74),
          borderRadius: BorderRadius.circular(PlanrDesign.cardRadius),
          border: Border.all(
            color: Colors.white.withOpacity(0.92),
            width: 1.2,
          ),
          boxShadow: [PlanrDesign.cardShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
              )
            else
              const _EmptyImageState(),

            if (hasImage)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: PlanrDesign.eventOverlayGradient(),
                ),
              ),

            if (hasImage)
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        color: PlanrDesign.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event photo selected',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap to change image',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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

class _EmptyImageState extends StatelessWidget {
  const _EmptyImageState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PlanrDesign.cardLight.withOpacity(0.95),
            PlanrDesign.accentSoft.withOpacity(0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: PlanrDesign.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add event photo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'A strong photo makes the event feel more alive.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanrDesign.cardLight.withOpacity(0.78),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.92),
            ),
          ),
          child: Row(
            children: [
              _SettingIcon(icon: icon),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PlanrDesign.eventMetaOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: PlanrDesign.softMuted,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilitySelector extends StatelessWidget {
  const _VisibilitySelector({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visibility',
          style: TextStyle(
            color: PlanrDesign.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _VisibilityOption(
                icon: Icons.public_rounded,
                title: 'Public',
                subtitle: 'Discoverable',
                selected: value == 'public',
                onTap: () => onChanged('public'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VisibilityOption(
                icon: Icons.lock_outline_rounded,
                title: 'Private',
                subtitle: 'Invite only',
                selected: value == 'private',
                onTap: () => onChanged('private'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        selected ? PlanrDesign.accentSoft.withOpacity(0.95) : PlanrDesign.cardLight.withOpacity(0.74);

    final borderColor =
        selected ? PlanrDesign.accent.withOpacity(0.55) : Colors.white.withOpacity(0.95);

    final iconColor = selected ? PlanrDesign.accentDark : PlanrDesign.softMuted;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: selected ? PlanrDesign.accentDark : PlanrDesign.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withOpacity(0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
        ),
      ),
      child: Row(
        children: [
          _SettingIcon(icon: icon),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: PlanrDesign.accent,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: PlanrDesign.softMuted.withOpacity(0.35),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.88),
        ),
      ),
      child: Icon(
        icon,
        color: PlanrDesign.accentDark,
        size: 21,
      ),
    );
  }
}