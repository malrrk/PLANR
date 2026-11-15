import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/planr_design.dart';
import '../../providers/firebase_providers.dart';
import '../../providers/pinned_moments_provider.dart';

/// Lets the user reuse one of their own recent stories as a profile photo or banner.
/// Returns a local copy so the normal upload flow can be used unchanged.
Future<File?> pickPhotoFromMyStories(
  BuildContext context,
  WidgetRef ref, {
  required String uid,
}) async {
  final candidate = await showModalBottomSheet<PinnedMomentCandidate>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) => _StoryPhotoSheet(uid: uid),
  );

  if (candidate == null) return null;

  try {
    final file = File(
      '${Directory.systemTemp.path}/story_pick_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.read(storageProvider).refFromURL(candidate.imageUrl).writeToFile(file);
    return file;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load that story photo.')),
      );
    }
    return null;
  }
}

class _StoryPhotoSheet extends ConsumerWidget {
  const _StoryPhotoSheet({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(recentStoryImagesProvider(uid));

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: PlanrDesign.cardLight,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [PlanrDesign.cardShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: PlanrDesign.softMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'From your stories',
              style: TextStyle(
                color: PlanrDesign.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Photos you posted in the last 30 days.',
              style: TextStyle(color: PlanrDesign.muted, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: storiesAsync.when(
                data: (stories) {
                  if (stories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        'No recent stories yet. Post one and it will show up here.',
                        style: TextStyle(color: PlanrDesign.muted),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    itemCount: stories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final story = stories[index];

                      return GestureDetector(
                        onTap: () => Navigator.pop(context, story),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            story.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: PlanrDesign.accentSoft,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    'Could not load your stories.',
                    style: TextStyle(color: PlanrDesign.muted),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
