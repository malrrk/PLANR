import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/story.dart';
import 'friends_provider.dart';

class StoryGroup {
  const StoryGroup({
    required this.groupId,
    required this.ownerUid,
    required this.ownerDisplayName,
    required this.ownerPhotoUrl,
    required this.dayKey,
    required this.stories,
  });

  final String groupId;
  final String ownerUid;
  final String ownerDisplayName;
  final String? ownerPhotoUrl;
  final String dayKey;
  final List<Story> stories;

  Story get latestStory => stories.last;

  String get dayLabel {
    final now = DateTime.now();
    final todayKey = Story.dayKeyFromDate(now);
    final yesterdayKey = Story.dayKeyFromDate(
      now.subtract(const Duration(days: 1)),
    );

    if (dayKey == todayKey) return 'Today';
    if (dayKey == yesterdayKey) return 'Yesterday';

    final parts = dayKey.split('-');
    if (parts.length == 3) {
      return '${parts[2]}.${parts[1]}';
    }

    return dayKey;
  }

  String get displayLabel => '$ownerDisplayName · $dayLabel';
}

final storyServiceProvider = Provider<StoryService>((ref) {
  return StoryService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    FirebaseAuth.instance,
  );
});

final friendsStoriesProvider = StreamProvider<List<Story>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return Stream.value([]);
  }

  final friendsAsync = ref.watch(myFriendsProvider);

  return friendsAsync.when(
    data: (friends) {
      final allowedUserIds = <String>[
        user.uid,
        ...friends.map((e) => e.uid),
      ];

      if (allowedUserIds.isEmpty) {
        return Stream.value([]);
      }

      return FirebaseFirestore.instance
          .collection('stories')
          .where('ownerUid', whereIn: allowedUserIds)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final now = DateTime.now();

        return snapshot.docs
            .map((doc) => Story.fromMap(doc.data()))
            .where((story) => story.expiresAt.isAfter(now))
            .toList();
      });
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

class StoryService {
  StoryService(this._firestore, this._storage, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  static const int storyVisibleDays = 7; //changeable

  Future<String?> addStory({
    required File file,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final storyId = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: storyVisibleDays));
      final dayKey = Story.dayKeyFromDate(now);

      final ref = _storage.ref().child('stories/${user.uid}/$storyId.jpg');

      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      final story = Story(
        id: storyId,
        ownerUid: user.uid,
        ownerDisplayName: user.displayName ?? 'User',
        ownerPhotoUrl: user.photoURL,
        imageUrl: imageUrl,
        createdAt: now,
        expiresAt: expiresAt,
        dayKey: dayKey,
      );

      await _firestore.collection('stories').doc(storyId).set(story.toMap());

      return null;
    } catch (_) {
      return 'Failed to add story.';
    }
  }

  List<StoryGroup> groupStoriesByOwnerAndDay(List<Story> stories) {
    final groups = <String, List<Story>>{};

    for (final story in stories) {
      final groupId = '${story.ownerUid}_${story.dayKey}';
      groups.putIfAbsent(groupId, () => []);
      groups[groupId]!.add(story);
    }

    final result = groups.entries.map((entry) {
      final groupStories = entry.value
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final first = groupStories.first;

      return StoryGroup(
        groupId: entry.key,
        ownerUid: first.ownerUid,
        ownerDisplayName: first.ownerDisplayName,
        ownerPhotoUrl: first.ownerPhotoUrl,
        dayKey: first.dayKey,
        stories: groupStories,
      );
    }).toList()
      ..sort(
        (a, b) => b.latestStory.createdAt.compareTo(a.latestStory.createdAt),
      );

    return result;
  }

  StoryGroup? storyGroupById(List<Story> stories, String groupId) {
    final groups = groupStoriesByOwnerAndDay(stories);

    for (final group in groups) {
      if (group.groupId == groupId) {
        return group;
      }
    }

    return null;
  }

  StoryGroup? firstStoryGroupForOwner(List<Story> stories, String ownerUid) {
    final groups = groupStoriesByOwnerAndDay(stories);

    for (final group in groups) {
      if (group.ownerUid == ownerUid) {
        return group;
      }
    }

    return null;
  }

  Future<String?> deleteStory(Story story) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (story.ownerUid != user.uid) {
        return 'You can only delete your own stories.';
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      final storyRef = _firestore.collection('stories').doc(story.id);

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final userData = userSnapshot.data();

        final pinnedUrls =
            (userData?['pinnedStoryImageUrls'] as List<dynamic>?)
                    ?.whereType<String>()
                    .toList() ??
                <String>[];

        pinnedUrls.remove(story.imageUrl);

        transaction.delete(storyRef);
        transaction.set(
          userRef,
          {
            'pinnedStoryImageUrls': pinnedUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      try {
        await _storage.refFromURL(story.imageUrl).delete();
      } catch (_) {
        // Ignore Storage cleanup failure for now.
      }

      return null;
    } catch (_) {
      return 'Failed to delete story.';
    }
  }

  Future<String?> pinStoryToProfile(Story story) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (story.ownerUid != user.uid) {
        return 'You can only pin your own stories.';
      }

      final userRef = _firestore.collection('users').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data();

        final pinnedUrls =
            (data?['pinnedStoryImageUrls'] as List<dynamic>?)
                    ?.whereType<String>()
                    .toList() ??
                <String>[];

        if (pinnedUrls.contains(story.imageUrl)) return;

        if (pinnedUrls.length >= 3) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'Pinned moments are full.',
          );
        }

        pinnedUrls.add(story.imageUrl);

        transaction.set(
          userRef,
          {
            'pinnedStoryImageUrls': pinnedUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to pin story.';
    } catch (_) {
      return 'Failed to pin story.';
    }
  }

  Future<String?> replacePinnedStory({
    required Story story,
    required int replaceIndex,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (story.ownerUid != user.uid) {
        return 'You can only pin your own stories.';
      }

      if (replaceIndex < 0 || replaceIndex > 2) {
        return 'Invalid pinned moment.';
      }

      final userRef = _firestore.collection('users').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data();

        final pinnedUrls =
            (data?['pinnedStoryImageUrls'] as List<dynamic>?)
                    ?.whereType<String>()
                    .toList() ??
                <String>[];

        if (pinnedUrls.contains(story.imageUrl)) return;

        if (replaceIndex >= pinnedUrls.length) {
          pinnedUrls.add(story.imageUrl);
        } else {
          pinnedUrls[replaceIndex] = story.imageUrl;
        }

        transaction.set(
          userRef,
          {
            'pinnedStoryImageUrls': pinnedUrls.take(3).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      return null;
    } catch (_) {
      return 'Failed to replace pinned moment.';
    }
  }

  Future<String?> unpinStoryFromProfile(Story story) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (story.ownerUid != user.uid) {
        return 'You can only unpin your own stories.';
      }

      final userRef = _firestore.collection('users').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data();

        final pinnedUrls =
            (data?['pinnedStoryImageUrls'] as List<dynamic>?)
                    ?.whereType<String>()
                    .toList() ??
                <String>[];

        pinnedUrls.remove(story.imageUrl);

        transaction.set(
          userRef,
          {
            'pinnedStoryImageUrls': pinnedUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      return null;
    } catch (_) {
      return 'Failed to unpin story.';
    }
  }

  bool isPinned({
    required Story story,
    required List<String> pinnedStoryImageUrls,
  }) {
    return pinnedStoryImageUrls.contains(story.imageUrl);
  }

  // Kept for compatibility with older screens.
  List<String> getUniqueUsers(List<Story> stories) {
    final seen = <String>{};
    final users = <String>[];

    for (final story in stories) {
      if (!seen.contains(story.ownerUid)) {
        seen.add(story.ownerUid);
        users.add(story.ownerUid);
      }
    }

    return users;
  }

  // Kept for compatibility with older screens.
  List<Story> storiesForUser(List<Story> stories, String ownerUid) {
    final result =
        stories.where((story) => story.ownerUid == ownerUid).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return result;
  }
}