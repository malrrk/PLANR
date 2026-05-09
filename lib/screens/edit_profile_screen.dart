import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_text_field.dart';
import '../providers/user_profile_provider.dart';

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

    if (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty) {
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

    return PlanrBackground(
      variant: PlanrBackgroundVariant.profile,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: profileAsync.when(
            data: (profile) {
              if (!_initialized) {
                _displayNameController.text = profile?.displayName ?? '';
                _bioController.text = profile?.bio ?? '';
                _initialized = true;
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      PlanrDesign.pagePadding,
                      14,
                      PlanrDesign.pagePadding,
                      18,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _EditProfileTopBar(
                        onSave: _saving ? null : _save,
                        saving: _saving,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      PlanrDesign.pagePadding,
                      0,
                      PlanrDesign.pagePadding,
                      34,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _ImageEditorCard(
                            profilePhotoUrl: profile?.photoUrl,
                            backgroundImageUrl: profile?.backgroundImageUrl,
                            selectedProfileImage: _selectedProfileImage,
                            selectedBackgroundImage: _selectedBackgroundImage,
                            profileImageProvider:
                                _profileImageProvider(profile?.photoUrl),
                            onPickProfileImage: _pickProfileImage,
                            onPickBackgroundImage: _pickBackgroundImage,
                          ),
                          const SizedBox(height: 18),
                          PlanrCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle(
                                  title: 'Profile info',
                                  icon: Icons.badge_rounded,
                                ),
                                const SizedBox(height: 16),
                                PlanrTextField(
                                  controller: _displayNameController,
                                  label: 'Display name',
                                  hintText: 'Your name',
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 16),
                                _UsernameField(
                                  username: profile?.username ?? '',
                                ),
                                const SizedBox(height: 16),
                                PlanrTextField(
                                  controller: _bioController,
                                  label: 'Bio',
                                  hintText: 'Tell people a little about you',
                                  maxLines: 4,
                                  textInputAction: TextInputAction.newline,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          PlanrButton(
                            label: 'Save Profile',
                            icon: Icons.check_rounded,
                            isLoading: _saving,
                            height: 58,
                            onPressed: _saving ? null : _save,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const _EditProfileLoadingState(),
            error: (_, _) => const _EditProfileErrorState(),
          ),
        ),
      ),
    );
  }
}

class _EditProfileTopBar extends StatelessWidget {
  const _EditProfileTopBar({
    required this.onSave,
    required this.saving,
  });

  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: PlanrDesign.backgroundButton,
          shape: const CircleBorder(),
          elevation: 3,
          shadowColor: Colors.black12,
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            customBorder: const CircleBorder(),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black.withOpacity(0.12),
                  width: 1.1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: PlanrDesign.ink,
                size: 19,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 0.98,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Update your look and bio',
                style: TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: PlanrDesign.backgroundButton,
          borderRadius: BorderRadius.circular(999),
          elevation: 3,
          shadowColor: Colors.black12,
          child: InkWell(
            onTap: onSave,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.black.withOpacity(0.12),
                  width: 1.1,
                ),
              ),
              child: Center(
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.3),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: PlanrDesign.accentDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageEditorCard extends StatelessWidget {
  const _ImageEditorCard({
    required this.profilePhotoUrl,
    required this.backgroundImageUrl,
    required this.selectedProfileImage,
    required this.selectedBackgroundImage,
    required this.profileImageProvider,
    required this.onPickProfileImage,
    required this.onPickBackgroundImage,
  });

  final String? profilePhotoUrl;
  final String? backgroundImageUrl;
  final File? selectedProfileImage;
  final File? selectedBackgroundImage;
  final ImageProvider? profileImageProvider;
  final VoidCallback onPickProfileImage;
  final VoidCallback onPickBackgroundImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PlanrDesign.cardLight.withOpacity(0.88),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
          width: 1.1,
        ),
        boxShadow: [PlanrDesign.softShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: onPickBackgroundImage,
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (selectedBackgroundImage != null)
                    Image.file(
                      selectedBackgroundImage!,
                      fit: BoxFit.cover,
                    )
                  else if (backgroundImageUrl != null &&
                      backgroundImageUrl!.isNotEmpty)
                    Image.network(
                      backgroundImageUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    const _BackgroundPlaceholder(),
                  const _BackgroundOverlay(),
                  Center(
                    child: _ImageEditPill(
                      icon: Icons.wallpaper_rounded,
                      label: 'Change background',
                      onTap: onPickBackgroundImage,
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
                  onTap: onPickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(3.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: PlanrDesign.storyRingGradient,
                      boxShadow: [
                        BoxShadow(
                          color: PlanrDesign.accent.withOpacity(0.16),
                          blurRadius: 26,
                          offset: const Offset(0, 13),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 53,
                        backgroundColor: PlanrDesign.accentSoft,
                        backgroundImage: profileImageProvider,
                        child: profileImageProvider == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: PlanrDesign.accentDark,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ImageEditPill(
                  icon: Icons.photo_camera_rounded,
                  label: 'Change profile photo',
                  onTap: onPickProfileImage,
                  compact: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPlaceholder extends StatelessWidget {
  const _BackgroundPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: PlanrDesign.brandGradient,
      ),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          color: Colors.white.withOpacity(0.82),
          size: 54,
        ),
      ),
    );
  }
}

class _BackgroundOverlay extends StatelessWidget {
  const _BackgroundOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x33000000),
            Color(0x44000000),
            Color(0x55FFFAF3),
          ],
          stops: [0.0, 0.52, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _ImageEditPill extends StatelessWidget {
  const _ImageEditPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.90),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 13 : 15,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: compact ? 17 : 18,
                color: PlanrDesign.ink,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: compact ? 13.2 : 13.8,
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

class _UsernameField extends StatelessWidget {
  const _UsernameField({
    required this.username,
  });

  final String username;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Username',
          style: TextStyle(
            color: PlanrDesign.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: PlanrDesign.cardLight.withOpacity(0.82),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          child: Text(
            '@$username',
            style: const TextStyle(
              color: PlanrDesign.accentDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Username changes will be added later.',
          style: TextStyle(
            color: PlanrDesign.softMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PlanrDesign.accentSoft.withOpacity(0.72),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: PlanrDesign.accentDark,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: PlanrDesign.ink,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _EditProfileLoadingState extends StatelessWidget {
  const _EditProfileLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.6),
    );
  }
}

class _EditProfileErrorState extends StatelessWidget {
  const _EditProfileErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlanrDesign.pagePadding),
        child: PlanrCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.error_outline_rounded,
                color: PlanrDesign.accentDark,
                size: 36,
              ),
              SizedBox(height: 12),
              Text(
                'Could not load profile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Please try again in a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlanrDesign.muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}