import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_scaffold.dart';
import '../providers/story_provider.dart';
import '../models/public_page.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({
    super.key,
    this.page,
  });

  final PublicPage? page;

  bool get isPageStory => page != null;

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;
  bool _saving = false;

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null) return;

    setState(() {
      _imagePath = file.path;
    });
  }

  Future<void> _pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (file == null) return;

    setState(() {
      _imagePath = file.path;
    });
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: PlanrDesign.cardLight.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.95),
                ),
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
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add Story Photo',
                      style: TextStyle(
                        color: PlanrDesign.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose a photo from your gallery or take a new one.',
                      style: TextStyle(
                        color: PlanrDesign.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SourceSheetOption(
                    icon: Icons.photo_library_outlined,
                    title: 'Choose from gallery',
                    subtitle: 'Use an existing photo',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFromGallery();
                    },
                  ),
                  const SizedBox(height: 10),
                  _SourceSheetOption(
                    icon: Icons.photo_camera_outlined,
                    title: 'Take a photo',
                    subtitle: 'Open the camera',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFromCamera();
                    },
                  ),
                  const SizedBox(height: 10),
                  _SourceSheetOption(
                    icon: Icons.close_rounded,
                    title: 'Cancel',
                    subtitle: 'Go back without choosing',
                    muted: true,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _postStory() async {
    if (_imagePath == null) {
      _showSnackBar('Please choose a photo first.');
      return;
    }

    setState(() {
      _saving = true;
    });

    final service = ref.read(storyServiceProvider);

    final error = widget.page == null
        ? await service.addStory(
            file: File(_imagePath!),
          )
        : await service.addPageStory(
            page: widget.page!,
            file: File(_imagePath!),
            isPublicPreview: true,
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

  void _removeImage() {
    setState(() {
      _imagePath = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imagePath != null;
    final isPageStory = widget.isPageStory;
    final page = widget.page;

    return PlanrScaffold(
      title: isPageStory ? 'Page Story' : 'Create Story',
      variant: PlanrBackgroundVariant.create,
      resizeToAvoidBottomInset: true,
      child: ListView(
        children: [
          Text(
            isPageStory ? 'Post as ${page!.name}' : 'Share a moment',
            style: const TextStyle(
              color: PlanrDesign.ink,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPageStory
                ? 'This story will appear as a public preview on the page and in followers’ stories.'
                : 'Stories are temporary and help friends see what is happening right now.',
            style: const TextStyle(
              color: PlanrDesign.muted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          _StoryPreviewCard(
            imagePath: _imagePath,
            onTap: _showImageSourceSheet,
            onRemove: _removeImage,
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: PlanrButton(
                  label: hasImage ? 'Change Photo' : 'Add Photo',
                  icon: hasImage
                      ? Icons.photo_library_rounded
                      : Icons.add_photo_alternate_outlined,
                  variant: PlanrButtonVariant.soft,
                  onPressed: _saving ? null : _showImageSourceSheet,
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 10),
                _StoryRemoveButton(
                  onPressed: _saving ? null : _removeImage,
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          PlanrButton(
            label: _saving
                ? 'Posting...'
                : isPageStory
                    ? 'Post Page Story'
                    : 'Post Story',
            icon: Icons.auto_stories_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _postStory,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StoryPreviewCard extends StatelessWidget {
  const _StoryPreviewCard({
    required this.imagePath,
    required this.onTap,
    required this.onRemove,
  });

  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.78,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: PlanrDesign.storyRingGradient,
            boxShadow: [PlanrDesign.cardShadow],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              color: PlanrDesign.card.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(31),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
                width: 1.2,
              ),
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
                  const _EmptyStoryState(),

                if (hasImage)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0, 0.55, 1],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                if (hasImage)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.42),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onRemove,
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (hasImage)
                  const Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: _StorySelectedLabel(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStoryState extends StatelessWidget {
  const _EmptyStoryState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PlanrDesign.cardLight.withValues(alpha: 0.96),
            PlanrDesign.accentSoft.withValues(alpha: 0.52),
            const Color(0xFFF9F1FF).withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.96),
                ),
                boxShadow: [PlanrDesign.softShadow],
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: PlanrDesign.accent,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add story photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PlanrDesign.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.55,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Tap here to choose a moment from your gallery or camera.',
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
    );
  }
}

class _StorySelectedLabel extends StatelessWidget {
  const _StorySelectedLabel();

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 22,
      color: Colors.white.withValues(alpha: 0.88),
      shadow: false,
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: PlanrDesign.accent,
            size: 22,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ready to post',
              style: TextStyle(
                color: PlanrDesign.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            'Tap to change',
            style: TextStyle(
              color: PlanrDesign.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryRemoveButton extends StatelessWidget {
  const _StoryRemoveButton({
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Material(
      color: disabled
          ? PlanrDesign.softMuted.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 58,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: disabled
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.95),
              width: 1.2,
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            color: disabled ? PlanrDesign.softMuted : PlanrDesign.ink,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _SourceSheetOption extends StatelessWidget {
  const _SourceSheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final iconColor = muted ? PlanrDesign.softMuted : PlanrDesign.accentDark;
    final iconBackground = muted
        ? PlanrDesign.card.withValues(alpha: 0.6)
        : PlanrDesign.accentSoft.withValues(alpha: 0.75);

    return Material(
      color: PlanrDesign.card.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color:
                            muted ? PlanrDesign.muted : PlanrDesign.ink,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: PlanrDesign.softMuted,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}