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
import '../models/public_page.dart';
import '../providers/public_page_provider.dart';
import '../widgets/event_tag_selector.dart';

class EditPublicPageScreen extends ConsumerStatefulWidget {
  const EditPublicPageScreen({
    super.key,
    required this.page,
  });

  final PublicPage page;

  @override
  ConsumerState<EditPublicPageScreen> createState() =>
      _EditPublicPageScreenState();
}

class _EditPublicPageScreenState extends ConsumerState<EditPublicPageScreen> {
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _handleController;
  late final TextEditingController _descriptionController;

  late String _category;
  late List<String> _selectedTagIds;

  File? _newPhotoFile;
  File? _newBackgroundFile;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.page.name);
    _handleController = TextEditingController(text: widget.page.handle);
    _descriptionController =
        TextEditingController(text: widget.page.description);

    _category = widget.page.category.trim().isEmpty
        ? 'page'
        : widget.page.category.trim().toLowerCase();

    _selectedTagIds = List<String>.from(widget.page.tags);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
    );

    if (file == null) return;

    setState(() {
      _newPhotoFile = File(file.path);
    });
  }

  Future<void> _pickBackground() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
    );

    if (file == null) return;

    setState(() {
      _newBackgroundFile = File(file.path);
    });
  }

  void _removeSelectedPhoto() {
    setState(() {
      _newPhotoFile = null;
    });
  }

  void _removeSelectedBackground() {
    setState(() {
      _newBackgroundFile = null;
    });
  }

  Future<void> _savePage() async {
    final name = _nameController.text.trim();
    final handle = _handleController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Please enter a page name.');
      return;
    }

    if (handle.isEmpty) {
      _showSnackBar('Please enter a page handle.');
      return;
    }

    if (_selectedTagIds.isEmpty) {
      _showSnackBar('Please choose at least one tag.');
      return;
    }

    setState(() {
      _saving = true;
    });

    final service = ref.read(publicPageServiceProvider);

    final pageError = await service.updatePublicPage(
      page: widget.page,
      name: name,
      handle: handle,
      description: description,
      category: _category,
      tags: _selectedTagIds,
    );

    if (!mounted) return;

    if (pageError != null) {
      setState(() {
        _saving = false;
      });

      _showSnackBar(pageError);
      return;
    }

    final imageError = await service.updatePublicPageImages(
      page: widget.page,
      newPhotoFile: _newPhotoFile,
      newBackgroundFile: _newBackgroundFile,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    if (imageError != null) {
      _showSnackBar(imageError);
      return;
    }

    ref.invalidate(myManagedPublicPagesProvider);
    ref.invalidate(publicPagesProvider);
    ref.invalidate(publicPageByIdProvider(widget.page.id));

    Navigator.of(context).pop();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlanrScaffold(
      title: 'Edit Page',
      variant: PlanrBackgroundVariant.create,
      resizeToAvoidBottomInset: true,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _EditPageIntroCard(page: widget.page),
          const SizedBox(height: 18),
          _PageMediaCard(
            page: widget.page,
            newPhotoFile: _newPhotoFile,
            newBackgroundFile: _newBackgroundFile,
            onPickPhoto: _saving ? null : _pickPhoto,
            onPickBackground: _saving ? null : _pickBackground,
            onRemoveSelectedPhoto: _saving ? null : _removeSelectedPhoto,
            onRemoveSelectedBackground:
                _saving ? null : _removeSelectedBackground,
          ),
          const SizedBox(height: 18),
          PlanrCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                PlanrTextField(
                  controller: _nameController,
                  maxLength: 80,
                  label: 'Page name',
                  hintText: 'e.g. Campus Events Nürnberg',
                  prefixIcon: Icons.storefront_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                PlanrTextField(
                  controller: _handleController,
                  maxLength: 40,
                  label: 'Handle',
                  hintText: 'campusevents',
                  prefixIcon: Icons.alternate_email_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                PlanrTextField(
                  controller: _descriptionController,
                  maxLength: 1000,
                  label: 'Description',
                  hintText: 'What kind of events does this page host?',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PlanrCard(
            padding: const EdgeInsets.all(18),
            child: _CategorySelector(
              value: _category,
              onChanged: (value) {
                setState(() {
                  _category = value;
                });
              },
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
          const SizedBox(height: 24),
          PlanrButton(
            label: _saving ? 'Saving...' : 'Save Page',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _savePage,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PageMediaCard extends StatelessWidget {
  const _PageMediaCard({
    required this.page,
    required this.newPhotoFile,
    required this.newBackgroundFile,
    required this.onPickPhoto,
    required this.onPickBackground,
    required this.onRemoveSelectedPhoto,
    required this.onRemoveSelectedBackground,
  });

  final PublicPage page;
  final File? newPhotoFile;
  final File? newBackgroundFile;
  final VoidCallback? onPickPhoto;
  final VoidCallback? onPickBackground;
  final VoidCallback? onRemoveSelectedPhoto;
  final VoidCallback? onRemoveSelectedBackground;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(18),
      radius: 30,
      color: PlanrDesign.cardLight.withValues(alpha: 0.88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallIconBox(icon: Icons.photo_library_rounded),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Page media',
                  style: PlanrDesign.cardTitleStyle.copyWith(
                    fontSize: 21,
                    letterSpacing: -0.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BannerPickerPreview(
            page: page,
            newBackgroundFile: newBackgroundFile,
            onPick: onPickBackground,
            onRemoveSelected: onRemoveSelectedBackground,
          ),
          const SizedBox(height: 14),
          _LogoPickerPreview(
            page: page,
            newPhotoFile: newPhotoFile,
            onPick: onPickPhoto,
            onRemoveSelected: onRemoveSelectedPhoto,
          ),
        ],
      ),
    );
  }
}

class _BannerPickerPreview extends StatelessWidget {
  const _BannerPickerPreview({
    required this.page,
    required this.newBackgroundFile,
    required this.onPick,
    required this.onRemoveSelected,
  });

  final PublicPage page;
  final File? newBackgroundFile;
  final VoidCallback? onPick;
  final VoidCallback? onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    final existingUrl = page.backgroundImageUrl?.trim();
    final hasExisting = existingUrl != null && existingUrl.isNotEmpty;
    final hasNew = newBackgroundFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MediaLabel(
          title: 'Banner image',
          subtitle: 'Shown at the top of your public page.',
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onPick,
          child: AspectRatio(
            aspectRatio: 2.2,
            child: Container(
              decoration: BoxDecoration(
                color: PlanrDesign.accentSoft.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasNew)
                    Image.file(
                      newBackgroundFile!,
                      fit: BoxFit.cover,
                    )
                  else if (hasExisting)
                    Image.network(
                      existingUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _BannerFallback(),
                    )
                  else
                    const _BannerFallback(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.38),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasNew
                                ? 'New banner selected'
                                : hasExisting
                                    ? 'Change banner'
                                    : 'Add banner',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _OverlayIconButton(
                          icon: Icons.photo_library_rounded,
                          onTap: onPick,
                        ),
                        if (hasNew) ...[
                          const SizedBox(width: 8),
                          _OverlayIconButton(
                            icon: Icons.close_rounded,
                            onTap: onRemoveSelected,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoPickerPreview extends StatelessWidget {
  const _LogoPickerPreview({
    required this.page,
    required this.newPhotoFile,
    required this.onPick,
    required this.onRemoveSelected,
  });

  final PublicPage page;
  final File? newPhotoFile;
  final VoidCallback? onPick;
  final VoidCallback? onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    final existingUrl = page.photoUrl?.trim();
    final hasExisting = existingUrl != null && existingUrl.isNotEmpty;
    final hasNew = newPhotoFile != null;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: PlanrDesign.card.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPick,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: PlanrDesign.accentSoft.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(27),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.94),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasNew
                  ? Image.file(
                      newPhotoFile!,
                      fit: BoxFit.cover,
                    )
                  : hasExisting
                      ? Image.network(
                          existingUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _LogoFallback(name: page.name),
                        )
                      : _LogoFallback(name: page.name),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MediaLabel(
                  title: 'Page logo',
                  subtitle: 'Used in Discover, stories and event pages.',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SmallMediaButton(
                        label: hasNew || hasExisting ? 'Change' : 'Add logo',
                        icon: Icons.add_photo_alternate_rounded,
                        onTap: onPick,
                      ),
                    ),
                    if (hasNew) ...[
                      const SizedBox(width: 8),
                      _SmallMediaButton(
                        label: 'Reset',
                        icon: Icons.close_rounded,
                        muted: true,
                        onTap: onRemoveSelected,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: PlanrDesign.brandGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: PlanrDesign.accentDark,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.20),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SmallMediaButton extends StatelessWidget {
  const _SmallMediaButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: muted
          ? PlanrDesign.cardLight.withValues(alpha: 0.65)
          : PlanrDesign.accentSoft.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: muted ? PlanrDesign.muted : PlanrDesign.accentDark,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted ? PlanrDesign.muted : PlanrDesign.accentDark,
                  fontSize: 12.2,
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

class _MediaLabel extends StatelessWidget {
  const _MediaLabel({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            fontSize: 12.4,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _SmallIconBox extends StatelessWidget {
  const _SmallIconBox({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: PlanrDesign.accentSoft.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.88),
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

class _EditPageIntroCard extends StatelessWidget {
  const _EditPageIntroCard({
    required this.page,
  });

  final PublicPage page;

  @override
  Widget build(BuildContext context) {
    final handle =
        page.displayHandle.isEmpty ? 'Public page' : page.displayHandle;

    return PlanrCard(
      padding: const EdgeInsets.all(20),
      radius: 30,
      color: PlanrDesign.cardLight.withValues(alpha: 0.88),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: PlanrDesign.accentDark,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const _categories = [
    _PageCategoryOption(
      id: 'page',
      label: 'Page',
      icon: Icons.storefront_rounded,
    ),
    _PageCategoryOption(
      id: 'club',
      label: 'Club',
      icon: Icons.nightlife_rounded,
    ),
    _PageCategoryOption(
      id: 'bar',
      label: 'Bar',
      icon: Icons.local_bar_rounded,
    ),
    _PageCategoryOption(
      id: 'venue',
      label: 'Venue',
      icon: Icons.location_city_rounded,
    ),
    _PageCategoryOption(
      id: 'organization',
      label: 'Organization',
      icon: Icons.groups_rounded,
    ),
    _PageCategoryOption(
      id: 'student_group',
      label: 'Student Group',
      icon: Icons.school_rounded,
    ),
    _PageCategoryOption(
      id: 'collective',
      label: 'Collective',
      icon: Icons.diversity_3_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            color: PlanrDesign.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final category in _categories)
              _CategoryChip(
                option: category,
                selected: value == category.id,
                onTap: () => onChanged(category.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _PageCategoryOption {
  const _PageCategoryOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PageCategoryOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? PlanrDesign.accentSoft.withValues(alpha: 0.95)
        : PlanrDesign.cardLight.withValues(alpha: 0.72);

    final foreground = selected ? PlanrDesign.accentDark : PlanrDesign.muted;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? PlanrDesign.accent.withValues(alpha: 0.38)
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option.icon,
                color: foreground,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                option.label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.5,
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