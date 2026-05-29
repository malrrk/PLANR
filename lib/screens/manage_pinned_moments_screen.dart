import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_empty_state.dart';
import '../core/widgets/planr_scaffold.dart';
import '../models/user_profile.dart';
import '../providers/pinned_moments_provider.dart';
import '../providers/user_profile_provider.dart';

class ManagePinnedMomentsScreen extends ConsumerStatefulWidget {
  const ManagePinnedMomentsScreen({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  ConsumerState<ManagePinnedMomentsScreen> createState() =>
      _ManagePinnedMomentsScreenState();
}

class _ManagePinnedMomentsScreenState
    extends ConsumerState<ManagePinnedMomentsScreen> {
  late List<String> _selectedUrls;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedUrls = widget.profile.pinnedStoryImageUrls.take(3).toList();
  }

  bool _isSelected(String imageUrl) {
    return _selectedUrls.contains(imageUrl);
  }

  void _toggleImage(String imageUrl) {
    setState(() {
      if (_selectedUrls.contains(imageUrl)) {
        _selectedUrls.remove(imageUrl);
        return;
      }

      if (_selectedUrls.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can pin up to 3 moments.'),
          ),
        );
        return;
      }

      _selectedUrls.add(imageUrl);
    });
  }

  void _removeAt(int index) {
    setState(() {
      _selectedUrls.removeAt(index);
    });
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _saving = true;
    });

    try {
      await ref.read(userProfileServiceProvider).updatePinnedStoryImageUrls(
            uid: user.uid,
            imageUrls: _selectedUrls,
          );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update pinned moments: $e'),
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final storiesAsync = uid == null
        ? const AsyncValue<List<PinnedMomentCandidate>>.data([])
        : ref.watch(recentStoryImagesProvider(uid));

    return PlanrScaffold(
      title: 'Pinned Moments',
      variant: PlanrBackgroundVariant.profile,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _PinnedMomentsSaveButton(
            saving: _saving,
            onSave: _save,
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectedMomentsCard(
            selectedUrls: _selectedUrls,
            onRemoveAt: _removeAt,
          ),
          const SizedBox(height: 18),
          const Text(
            'Choose from recent stories',
            style: TextStyle(
              color: PlanrDesign.ink,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.55,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Only stories from the last 30 days are shown.',
            style: TextStyle(
              color: PlanrDesign.muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: storiesAsync.when(
              data: (stories) {
                if (stories.isEmpty) {
                  return const Center(
                    child: PlanrEmptyState(
                      icon: Icons.auto_stories_outlined,
                      title: 'No recent stories',
                      subtitle:
                          'Create stories first, then pin your favorite ones here.',
                    ),
                  );
                }

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: stories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.76,
                  ),
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    final selected = _isSelected(story.imageUrl);

                    return _StoryCandidateTile(
                      imageUrl: story.imageUrl,
                      selected: selected,
                      onTap: () => _toggleImage(story.imageUrl),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
              error: (_, _) => const Center(
                child: PlanrEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load stories',
                  subtitle: 'Please try again in a moment.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedMomentsSaveButton extends StatelessWidget {
  const _PinnedMomentsSaveButton({
    required this.saving,
    required this.onSave,
  });

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanrDesign.backgroundButton,
      borderRadius: BorderRadius.circular(999),
      elevation: 3,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: saving ? null : onSave,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.black.withOpacity(0.12),
              width: 1.1,
            ),
          ),
          alignment: Alignment.center,
          child: saving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
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
    );
  }
}

class _SelectedMomentsCard extends StatelessWidget {
  const _SelectedMomentsCard({
    required this.selectedUrls,
    required this.onRemoveAt,
  });

  final List<String> selectedUrls;
  final ValueChanged<int> onRemoveAt;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(18),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.push_pin_rounded,
                color: PlanrDesign.accentDark,
                size: 22,
              ),
              SizedBox(width: 9),
              Text(
                'Currently pinned',
                style: TextStyle(
                  color: PlanrDesign.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${selectedUrls.length}/3 moments selected',
            style: const TextStyle(
              color: PlanrDesign.muted,
              fontSize: 13.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (index) {
              final hasImage = index < selectedUrls.length;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
                  child: AspectRatio(
                    aspectRatio: 0.76,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.95),
                          width: 1.2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  selectedUrls[index],
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 7,
                                  right: 7,
                                  child: Material(
                                    color: Colors.black.withOpacity(0.46),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => onRemoveAt(index),
                                      child: const SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const _EmptyPinnedSlot(),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StoryCandidateTile extends StatelessWidget {
  const _StoryCandidateTile({
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? PlanrDesign.accent
                  : Colors.white.withOpacity(0.95),
              width: selected ? 2.4 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.055),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
              if (selected)
                Container(
                  color: Colors.black.withOpacity(0.18),
                ),
              if (selected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 29,
                    height: 29,
                    decoration: const BoxDecoration(
                      color: PlanrDesign.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPinnedSlot extends StatelessWidget {
  const _EmptyPinnedSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PlanrDesign.accentSoft.withOpacity(0.42),
      child: const Center(
        child: Icon(
          Icons.add_photo_alternate_rounded,
          color: PlanrDesign.accentDark,
          size: 30,
        ),
      ),
    );
  }
}