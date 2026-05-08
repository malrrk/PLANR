import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
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
    setState(() {
      _saving = true;
    });

    if (_selectedTagIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose at least one tag.'),
        ),
      );
      return;
    }

    final error = await ref.read(eventServiceProvider).updateEvent(
          event: widget.event,
          title: _titleController.text,
          description: _descriptionController.text,
          address: _addressController.text,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.pop(context);
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
        : widget.event.imageUrl != null
            ? NetworkImage(widget.event.imageUrl!)
            : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: previewImage == null
                  ? const Center(
                      child: Icon(Icons.add_photo_alternate_outlined, size: 48),
                    )
                  : Image(
                      image: previewImage,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Change photo'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          EventTagSelector(
            selectedTagIds: _selectedTagIds,
            requireAtLeastOne: true,
            onChanged: (tagIds) {
              setState(() {
                _selectedTagIds = tagIds;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date & Time'),
            subtitle: Text(_formatDate(_selectedDate)),
            trailing: const Icon(Icons.calendar_month),
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _visibility,
            decoration: const InputDecoration(
              labelText: 'Visibility',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'public',
                child: Text('Public'),
              ),
              DropdownMenuItem(
                value: 'private',
                child: Text('Private'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _visibility = value;
              });
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable event chat'),
            value: _chatEnabled,
            onChanged: (value) {
              setState(() {
                _chatEnabled = value;
              });
            },
          ),
          if (_visibility == 'private')
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Guests can invite others'),
              value: _guestsCanInvite,
              onChanged: (value) {
                setState(() {
                  _guestsCanInvite = value;
                });
              },
            ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}