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
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../widgets/event_tag_selector.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  const EditEventScreen({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;

  final ImagePicker _picker = ImagePicker();

  late DateTime _selectedDate;
  late String _visibility;
  late bool _chatEnabled;
  late bool _guestsCanInvite;
  late List<String> _selectedTagIds;

  File? _selectedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController =
        TextEditingController(text: widget.event.description);
    _addressController = TextEditingController(text: widget.event.address);

    _selectedDate = widget.event.date;
    _visibility = widget.event.visibility;
    _chatEnabled = widget.event.chatEnabled;
    _guestsCanInvite = widget.event.guestsCanInvite;
    _selectedTagIds = List<String>.from(widget.event.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null) return;

    setState(() {
      _selectedImage = File(file.path);
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 1)),
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

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final address = _addressController.text.trim();

    if (title.isEmpty || description.isEmpty || address.isEmpty) {
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

    final error = await ref.read(eventServiceProvider).updateEvent(
          event: widget.event,
          title: title,
          description: description,
          address: address,
          tags: _selectedTagIds,
          date: _selectedDate,
          visibility: _visibility,
          chatEnabled: _chatEnabled,
          guestsCanInvite: _guestsCanInvite,
          newImageFile: _selectedImage,
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month.$year · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final previewImage = _selectedImage != null
        ? FileImage(_selectedImage!) as ImageProvider
        : widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty
            ? NetworkImage(widget.event.imageUrl!)
            : null;

    return PlanrScaffold(
      title: 'Edit Event',
      variant: PlanrBackgroundVariant.create,
      resizeToAvoidBottomInset: true,
      child: ListView(
        children: [
          _EditImageCard(
            imageProvider: previewImage,
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
                  hintText: 'Event title',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.edit_rounded,
                ),
                const SizedBox(height: 16),
                PlanrTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hintText: 'Tell people what changed.',
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 16),
                PlanrTextField(
                  controller: _addressController,
                  label: 'Address',
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
                  subtitle: _formatDate(_selectedDate),
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
                  subtitle: 'People who joined can write in the event chat.',
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
            label: _saving ? 'Saving...' : 'Save Changes',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _EditImageCard extends StatelessWidget {
  const _EditImageCard({
    required this.imageProvider,
    required this.onTap,
  });

  final ImageProvider? imageProvider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageProvider != null;

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
              Image(
                image: imageProvider!,
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
                  Expanded(
                    child: Text(
                      hasImage ? 'Tap to change photo' : 'Add event photo',
                      style: TextStyle(
                        color: hasImage ? Colors.white : PlanrDesign.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
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
      child: const Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: PlanrDesign.accent,
          size: 42,
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
    final background = selected
        ? PlanrDesign.accentSoft.withOpacity(0.95)
        : PlanrDesign.cardLight.withOpacity(0.74);

    final borderColor = selected
        ? PlanrDesign.accent.withOpacity(0.55)
        : Colors.white.withOpacity(0.95);

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