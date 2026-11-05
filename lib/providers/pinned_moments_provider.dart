import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_profile_provider.dart';

class PinnedMomentCandidate {
  const PinnedMomentCandidate({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String imageUrl;
  final DateTime createdAt;
}

final recentStoryImagesProvider =
    StreamProvider.family<List<PinnedMomentCandidate>, String>((ref, uid) {
  final firestore = ref.watch(firestoreProvider);
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

  return firestore
      .collection('stories')
      .where('ownerUid', isEqualTo: uid)
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    final stories = snapshot.docs.map((doc) {
      final data = doc.data();

      final imageUrl = data['imageUrl'] as String?;
      final createdAtRaw = data['createdAt'];

      if (imageUrl == null || imageUrl.isEmpty) {
        return null;
      }

      DateTime createdAt;

      if (createdAtRaw is Timestamp) {
        createdAt = createdAtRaw.toDate();
      } else {
        createdAt = DateTime.fromMillisecondsSinceEpoch(0);
      }

      if (createdAt.isBefore(thirtyDaysAgo)) {
        return null;
      }

      return PinnedMomentCandidate(
        id: doc.id,
        imageUrl: imageUrl,
        createdAt: createdAt,
      );
    }).whereType<PinnedMomentCandidate>().toList();

    stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return stories;
  });
});