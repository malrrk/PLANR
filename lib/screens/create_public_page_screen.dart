import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_scaffold.dart';
import '../core/widgets/planr_text_field.dart';
import '../providers/public_page_provider.dart';
import '../widgets/event_tag_selector.dart';
import 'public_page_screen.dart';

class CreatePublicPageScreen extends ConsumerStatefulWidget {
  const CreatePublicPageScreen({super.key});

  @override
  ConsumerState<CreatePublicPageScreen> createState() =>
      _CreatePublicPageScreenState();
}

class _CreatePublicPageScreenState
    extends ConsumerState<CreatePublicPageScreen> {
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'page';
  List<String> _selectedTagIds = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createPage() async {
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

    final result =
        await ref.read(publicPageServiceProvider).createPublicPageAndReturnId(
              name: name,
              handle: handle,
              description: description,
              category: _category,
              tags: _selectedTagIds,
            );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    if (result.error != null || result.pageId == null) {
      _showSnackBar(result.error ?? 'Could not create page.');
      return;
    }

    ref.invalidate(myManagedPublicPagesProvider);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PublicPageScreen(pageId: result.pageId!),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlanrScaffold(
      title: 'Create Page',
      variant: PlanrBackgroundVariant.create,
      resizeToAvoidBottomInset: true,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const _CreatePageIntroCard(),
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
            label: _saving ? 'Creating...' : 'Create Page',
            icon: Icons.add_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _createPage,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _CreatePageIntroCard extends StatelessWidget {
  const _CreatePageIntroCard();

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(20),
      radius: 30,
      color: PlanrDesign.cardLight.withValues(alpha: 0.88),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: PlanrDesign.accentDark,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public page',
                  style: TextStyle(
                    color: PlanrDesign.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Create a page for clubs, groups, venues or organizations that host public events.',
                  style: TextStyle(
                    color: PlanrDesign.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.32,
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