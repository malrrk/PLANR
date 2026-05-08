import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
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

  Future<void> _createEvent() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || description.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
        ),
      );
      return;
    }

    if (_selectedTagIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose at least one tag.'),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year} '
        '${_selectedDate.hour.toString().padLeft(2, '0')}:'
        '${_selectedDate.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
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
              child: _imagePath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate_outlined, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Add event photo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Image.file(
                      File(_imagePath!),
                      fit: BoxFit.cover,
                    ),
            ),
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
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date & Time'),
            subtitle: Text(formattedDate),
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
          const SizedBox(height: 16),
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
              onPressed: _saving ? null : _createEvent,
              child: Text(_saving ? 'Creating...' : 'Create Event'),
            ),
          ),
        ],
      ),
    );
  }
}