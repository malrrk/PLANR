import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/user_profile_provider.dart';
import '../widgets/profile/profile_design.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  File? _selectedProfileImage;
  File? _selectedBackgroundImage;

  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  ImageProvider? _profileImageProvider(String? currentPhotoUrl) {
    if (_selectedProfileImage != null) {
      return FileImage(_selectedProfileImage!);
    }

    if (currentPhotoUrl != null) {
      return NetworkImage(currentPhotoUrl);
    }

    return null;
  }

  Future<void> _pickProfileImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );

    if (file == null) return;

    setState(() {
      _selectedProfileImage = File(file.path);
    });
  }

  Future<void> _pickBackgroundImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );

    if (file == null) return;

    setState(() {
      _selectedBackgroundImage = File(file.path);
    });
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final displayName = _displayNameController.text.trim();
    final bio = _bioController.text.trim();

    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name is required.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final service = ref.read(userProfileServiceProvider);

      String? photoUrl;
      String? backgroundImageUrl;

      if (_selectedProfileImage != null) {
        photoUrl = await service.uploadProfilePhoto(
          uid: user.uid,
          file: _selectedProfileImage!,
        );

        await user.updatePhotoURL(photoUrl);
      }

      if (_selectedBackgroundImage != null) {
        backgroundImageUrl = await service.uploadProfileBackground(
          uid: user.uid,
          file: _selectedBackgroundImage!,
        );
      }

      await user.updateDisplayName(displayName);
      await user.reload();

      await service.updateProfile(
        uid: user.uid,
        displayName: displayName,
        bio: bio.isEmpty ? null : bio,
        photoUrl: photoUrl,
        backgroundImageUrl: backgroundImageUrl,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: ProfileDesign.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: ProfileDesign.ink,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: profileAsync.when(
          data: (profile) {
            if (!_initialized) {
              _displayNameController.text = profile?.displayName ?? '';
              _bioController.text = profile?.bio ?? '';
              _initialized = true;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                Container(
                  decoration: ProfileDesign.cardDecoration(radius: 34),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickBackgroundImage,
                        child: SizedBox(
                          height: 176,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_selectedBackgroundImage != null)
                                Image.file(
                                  _selectedBackgroundImage!,
                                  fit: BoxFit.cover,
                                )
                              else if (profile?.backgroundImageUrl != null)
                                Image.network(
                                  profile!.backgroundImageUrl!,
                                  fit: BoxFit.cover,
                                )
                              else
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: ProfileDesign.warmGradient,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_rounded,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              Container(
                                color: Colors.black.withOpacity(0.22),
                              ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.88),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.wallpaper_rounded,
                                        size: 18,
                                        color: ProfileDesign.ink,
                                      ),
                                      SizedBox(width: 7),
                                      Text(
                                        'Change background',
                                        style: TextStyle(
                                          color: ProfileDesign.ink,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -48),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickProfileImage,
                              child: CircleAvatar(
                                radius: 59,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 53,
                                  backgroundColor: const Color(0xFFF1F2FA),
                                  backgroundImage:
                                      _profileImageProvider(profile?.photoUrl),
                                  child: _selectedProfileImage == null &&
                                          profile?.photoUrl == null
                                      ? const Icon(
                                          Icons.person_rounded,
                                          size: 48,
                                          color: ProfileDesign.ink,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: _pickProfileImage,
                              icon: const Icon(Icons.photo_camera_rounded),
                              label: const Text('Change profile photo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: ProfileDesign.cardDecoration(radius: 30),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      TextField(
                        controller: _displayNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '@${profile?.username ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: ProfileDesign.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Username changes will be added later.',
                          style: TextStyle(
                            color: ProfileDesign.muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bioController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: ProfileDesign.ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          error: (_, _) => const Center(
            child: Text(
              'Could not load profile.',
              style: TextStyle(
                color: ProfileDesign.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}