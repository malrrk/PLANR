import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/public_page.dart';
import '../models/story.dart';
import 'friends_provider.dart';
import 'dart:async';
import 'firebase_providers.dart';
import 'public_page_provider.dart';

class StoryGroup {
  const StoryGroup({
    required this.groupId,
    required this.ownerType,
    required this.ownerUid,
    required this.ownerDisplayName,
    required this.ownerPhotoUrl,
    required this.pageId,
    required this.dayKey,
    required this.stories,
  });

  final String groupId;
  final String ownerType;
  final String ownerUid;
  final String ownerDisplayName;
  final String? ownerPhotoUrl;
  final String? pageId;
  final String dayKey;
  final List<Story> stories;

  Story get latestStory => stories.last;

  bool get isUserStoryGroup => ownerType == 'user';

  bool get isPageStoryGroup => ownerType == 'publicPage';

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
    ref.watch(firestoreProvider),
    ref.watch(storageProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final friendsStoriesProvider = StreamProvider<List<Story>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return Stream.value([]);
  }

  final friendsAsync = ref.watch(myFriendsProvider);
  final followedPagesAsync = ref.watch(followedPagesProvider);
  final managedPagesAsync = ref.watch(myManagedPublicPagesProvider);

  return friendsAsync.when(
    data: (friends) {
      return followedPagesAsync.when(
        data: (followedPages) {
          return managedPagesAsync.when(
            data: (managedPages) {
              final allowedUserIds = <String>{
                user.uid,
                ...friends.map((e) => e.uid),
              }.toList();

              final allowedPageIds = <String>{
                ...followedPages.map((page) => page.id),
                ...managedPages.map((page) => page.id),
              }.toList();

              return _watchCombinedStoryFeed(
                allowedUserIds: allowedUserIds,
                allowedPageIds: allowedPageIds,
              );
            },
            loading: () => Stream.value([]),
            error: (_, _) => Stream.value([]),
          );
        },
        loading: () => Stream.value([]),
        error: (_, _) => Stream.value([]),
      );
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

Stream<List<Story>> _watchCombinedStoryFeed({
  required List<String> allowedUserIds,
  required List<String> allowedPageIds,
}) {
  final controller = StreamController<List<Story>>();

  final userBuckets = <String, List<Story>>{};
  final pageBuckets = <String, List<Story>>{};
  final subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

  void emit() {
    final now = DateTime.now();

    final stories = <Story>[
      ...userBuckets.values.expand((stories) => stories),
      ...pageBuckets.values.expand((stories) => stories),
    ]
        .where((story) => story.expiresAt.isAfter(now))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (!controller.isClosed) {
      controller.add(stories);
    }
  }

  List<List<String>> chunkIds(List<String> ids) {
    final chunks = <List<String>>[];

    for (var i = 0; i < ids.length; i += 10) {
      final end = i + 10 > ids.length ? ids.length : i + 10;
      chunks.add(ids.sublist(i, end));
    }

    return chunks;
  }

  final userChunks = chunkIds(allowedUserIds);

  for (var i = 0; i < userChunks.length; i++) {
    final bucketKey = 'users_$i';
    final chunk = userChunks[i];

    final subscription = FirebaseFirestore.instance
      .collection('stories')
      .where('ownerType', isEqualTo: 'user')
      .where('ownerUid', whereIn: chunk)
      .snapshots()
      .listen(
      (snapshot) {
        final stories = snapshot.docs
            .map((doc) => Story.fromMap({...doc.data(), 'id': doc.id}))
            .where((story) => story.isUserStory)
            .toList();

        userBuckets[bucketKey] = stories;
        emit();
      },
      onError: controller.addError,
    );

    subscriptions.add(subscription);
  }

  final pageChunks = chunkIds(allowedPageIds);

  for (var i = 0; i < pageChunks.length; i++) {
    final bucketKey = 'pages_$i';
    final chunk = pageChunks[i];

    final subscription = FirebaseFirestore.instance
      .collection('stories')
      .where('ownerType', isEqualTo: 'publicPage')
      .where('pageId', whereIn: chunk)
      .snapshots()
      .listen(
      (snapshot) {
        final stories = snapshot.docs
            .map((doc) => Story.fromMap({...doc.data(), 'id': doc.id}))
            .where((story) => story.isPageStory)
            .toList();

        pageBuckets[bucketKey] = stories;
        emit();
      },
      onError: controller.addError,
    );

    subscriptions.add(subscription);
  }

  if (subscriptions.isEmpty) {
    Future<void>.microtask(() {
      if (!controller.isClosed) {
        controller.add([]);
      }
    });
  }

  controller.onCancel = () async {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  };

  return controller.stream;
}

final publicPagePreviewStoriesProvider =
    StreamProvider.family<List<Story>, String>((ref, pageId) {
    return FirebaseFirestore.instance
      .collection('stories')
      .where('ownerType', isEqualTo: 'publicPage')
      .where('pageId', isEqualTo: pageId)
      .where('isPublicPreview', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    final now = DateTime.now();

    final stories = snapshot.docs
        .map((doc) => Story.fromMap({...doc.data(), 'id': doc.id}))
        .where((story) => story.isPageStory)
        .where((story) => story.expiresAt.isAfter(now))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return stories.take(3).toList();
  });
});

class StoryService {
  StoryService(this._firestore, this._storage, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  static const int storyVisibleDays = 7; // changeable

  List<String> _pinnedUrls(Map<String, dynamic>? userData) {
    return (userData?['pinnedStoryImageUrls'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        <String>[];
  }

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
        ownerType: 'user',
        ownerUid: user.uid,
        ownerDisplayName: user.displayName ?? 'User',
        ownerPhotoUrl: user.photoURL,
        pageId: null,
        imageUrl: imageUrl,
        caption: null,
        createdAt: now,
        expiresAt: expiresAt,
        dayKey: dayKey,
        isPublicPreview: false,
      );

      await _firestore.collection('stories').doc(storyId).set(story.toMap());

      return null;
    } catch (_) {
      return 'Failed to add story.';
    }
  }

  Future<String?> addPageStory({
    required PublicPage page,
    required File file,
    String? caption,
    bool isPublicPreview = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final canManage =
          page.ownerUid == user.uid || page.adminUids.contains(user.uid);

      if (!canManage) {
        return 'You cannot post stories for this page.';
      }

      final storyId = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: storyVisibleDays));
      final dayKey = Story.dayKeyFromDate(now);

      final ref = _storage
          .ref()
          .child('stories/public_pages/${page.id}/$storyId.jpg');

      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      final story = Story(
        id: storyId,
        ownerType: 'publicPage',
        ownerUid: user.uid,
        ownerDisplayName: page.name,
        ownerPhotoUrl: page.photoUrl,
        pageId: page.id,
        imageUrl: imageUrl,
        caption: caption?.trim().isEmpty == true ? null : caption?.trim(),
        createdAt: now,
        expiresAt: expiresAt,
        dayKey: dayKey,
        isPublicPreview: isPublicPreview,
      );

      await _firestore.collection('stories').doc(storyId).set(story.toMap());

      return null;
    } catch (_) {
      return 'Failed to add page story.';
    }
  }

  List<StoryGroup> groupStoriesByOwnerAndDay(List<Story> stories) {
    final groups = <String, List<Story>>{};

    for (final story in stories) {
      final groupId = '${story.storyOwnerKey}_${story.dayKey}';
      groups.putIfAbsent(groupId, () => []);
      groups[groupId]!.add(story);
    }

    final result = groups.entries.map((entry) {
      final groupStories = entry.value
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final first = groupStories.first;

      return StoryGroup(
        groupId: entry.key,
        ownerType: first.ownerType,
        ownerUid: first.ownerUid,
        ownerDisplayName: first.ownerDisplayName,
        ownerPhotoUrl: first.ownerPhotoUrl,
        pageId: first.pageId,
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
      if (group.isUserStoryGroup && group.ownerUid == ownerUid) {
        return group;
      }
    }

    return null;
  }

  Future<String?> deleteStory(Story story) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (story.isPageStory) {
        final pageId = story.pageId;

        if (pageId == null || pageId.trim().isEmpty) {
          return 'Invalid page story.';
        }

        final pageSnapshot =
            await _firestore.collection('public_pages').doc(pageId).get();

        final pageData = pageSnapshot.data();

        if (pageData == null) {
          return 'Page not found.';
        }

        final ownerUid = pageData['ownerUid'] as String?;
        final adminUids = (pageData['adminUids'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            <String>[];

        final canManage = ownerUid == user.uid || adminUids.contains(user.uid);

        if (!canManage) {
          return 'You cannot delete this page story.';
        }

        await _firestore.collection('stories').doc(story.id).delete();

        try {
          await _storage.refFromURL(story.imageUrl).delete();
        } catch (_) {
          // Ignore Storage cleanup failure for now.
        }

        return null;
      }

      if (story.ownerUid != user.uid) {
        return 'You can only delete your own stories.';
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      final storyRef = _firestore.collection('stories').doc(story.id);

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final userData = userSnapshot.data();

        final pinnedUrls = _pinnedUrls(userData);

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

      if (!story.isUserStory) {
        return 'Only personal stories can be pinned.';
      }

      if (story.ownerUid != user.uid) {
        return 'You can only pin your own stories.';
      }

      final userRef = _firestore.collection('users').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data();

        final pinnedUrls = _pinnedUrls(data);

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

      if (!story.isUserStory) {
        return 'Only personal stories can be pinned.';
      }

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

        final pinnedUrls = _pinnedUrls(data);

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

      if (!story.isUserStory) {
        return 'Only personal stories can be unpinned.';
      }

      if (story.ownerUid != user.uid) {
        return 'You can only unpin your own stories.';
      }

      final userRef = _firestore.collection('users').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data();

        final pinnedUrls = _pinnedUrls(data);

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
}