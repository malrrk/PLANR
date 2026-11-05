import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../models/event_tag.dart';
import '../models/public_page.dart';
import 'firebase_providers.dart';
import 'managed_public_pages.dart';

final publicPageServiceProvider = Provider<PublicPageService>((ref) {
  return PublicPageService(
    ref.watch(firestoreProvider),
    ref.watch(storageProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final publicPagesProvider = StreamProvider<List<PublicPage>>((ref) {
  return FirebaseFirestore.instance
      .collection('public_pages')
      .where('isActive', isEqualTo: true)
      .orderBy('followerCount', descending: true)
      .limit(300)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => PublicPage.fromMap(doc.data(), doc.id))
        .toList();
  });
});

final publicPageByIdProvider =
    StreamProvider.family<PublicPage?, String>((ref, pageId) {
  return FirebaseFirestore.instance
      .collection('public_pages')
      .doc(pageId)
      .snapshots()
      .map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return PublicPage.fromMap(doc.data()!, doc.id);
  });
});

final myManagedPublicPagesProvider = StreamProvider<List<PublicPage>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;

  final ownedStream = firestore
      .collection('public_pages')
      .where('ownerUid', isEqualTo: user.uid)
      .snapshots();

  final adminStream = firestore
      .collection('public_pages')
      .where('adminUids', arrayContains: user.uid)
      .snapshots();

  return watchManagedPublicPages(
    ownedPages: ownedStream.map(
      (snapshot) => snapshot.docs
          .map((doc) => PublicPage.fromMap(doc.data(), doc.id))
          .toList(),
    ),
    administeredPages: adminStream.map(
      (snapshot) => snapshot.docs
          .map((doc) => PublicPage.fromMap(doc.data(), doc.id))
          .toList(),
    ),
  );
});

final followedPagesProvider = StreamProvider<List<PublicPage>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('followed_pages')
      .orderBy('followedAt', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final pageIds = snapshot.docs.map((doc) => doc.id).toList();

    if (pageIds.isEmpty) return <PublicPage>[];

    final firestore = FirebaseFirestore.instance;

    final pageDocs = await Future.wait(
      pageIds.map(
        (pageId) => firestore.collection('public_pages').doc(pageId).get(),
      ),
    );

    final pages = <PublicPage>[];

    for (final pageDoc in pageDocs) {
      if (!pageDoc.exists || pageDoc.data() == null) continue;

      final page = PublicPage.fromMap(pageDoc.data()!, pageDoc.id);
      if (page.isActive) pages.add(page);
    }

    return pages;
  });
});

final isFollowingPageProvider =
    StreamProvider.family<bool, String>((ref, pageId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('followed_pages')
      .doc(pageId)
      .snapshots()
      .map((doc) => doc.exists);
});

final publicPageEventsProvider =
    StreamProvider.family<List<Event>, String>((ref, pageId) {
  return FirebaseFirestore.instance
      .collection('events')
      .where('visibility', isEqualTo: 'public')
      .where('organizerId', isEqualTo: pageId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.now())
      .orderBy('date')
      .snapshots()
      .map((snapshot) {
    final now = DateTime.now();

    return snapshot.docs
        .map((doc) => Event.fromMap(doc.data(), doc.id))
        .where((event) {
          return event.date.isAfter(now) &&
              event.eventKind == 'public' &&
              event.organizerType == 'publicPage' &&
              event.organizerId == pageId;
        })
        .toList();
  });
});

class PublicPageCreationResult {
  const PublicPageCreationResult({
    required this.pageId,
    required this.error,
  });

  final String? pageId;
  final String? error;

  bool get success => pageId != null && error == null;
}

class PublicPageService {
  PublicPageService(this._firestore, this._storage, this._auth);

  static final SettableMetadata _imageMetadata =
      SettableMetadata(contentType: 'image/jpeg');

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  Future<String?> createPublicPage({
    required String name,
    required String handle,
    required String description,
    required String category,
    required List<String> tags,
  }) async {
    final result = await createPublicPageAndReturnId(
      name: name,
      handle: handle,
      description: description,
      category: category,
      tags: tags,
    );

    return result.error;
  }

  Future<PublicPageCreationResult> createPublicPageAndReturnId({
    required String name,
    required String handle,
    required String description,
    required String category,
    required List<String> tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const PublicPageCreationResult(
          pageId: null,
          error: 'No user logged in.',
        );
      }

      final trimmedName = name.trim();
      final normalizedHandle = _normalizeHandle(handle);
      final trimmedDescription = description.trim();
      final trimmedCategory =
          category.trim().isEmpty ? 'page' : category.trim().toLowerCase();

      if (trimmedName.isEmpty) {
        return const PublicPageCreationResult(
          pageId: null,
          error: 'Please enter a page name.',
        );
      }

      if (normalizedHandle.isEmpty) {
        return const PublicPageCreationResult(
          pageId: null,
          error: 'Please enter a page handle.',
        );
      }

      final existingHandle = await _firestore
          .collection('public_pages')
          .where('handle', isEqualTo: normalizedHandle)
          .limit(1)
          .get();

      if (existingHandle.docs.isNotEmpty) {
        return const PublicPageCreationResult(
          pageId: null,
          error: 'This page handle is already taken.',
        );
      }

      final pageId = _uuid.v4();
      final pageRef = _firestore.collection('public_pages').doc(pageId);
      final sanitizedTags = sanitizeEventTagIds(tags);

      await pageRef.set({
        'id': pageId,
        'name': trimmedName,
        'handle': normalizedHandle,
        'description': trimmedDescription,
        'photoUrl': null,
        'backgroundImageUrl': null,
        'category': trimmedCategory,
        'tags': sanitizedTags,
        'followerCount': 0,
        'eventCount': 0,
        'isVerified': false,
        'isActive': true,
        'ownerUid': user.uid,
        'adminUids': <String>[user.uid],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return PublicPageCreationResult(
        pageId: pageId,
        error: null,
      );
    } catch (_) {
      return const PublicPageCreationResult(
        pageId: null,
        error: 'Failed to create public page.',
      );
    }
  }

  Future<String?> updatePublicPage({
    required PublicPage page,
    required String name,
    required String handle,
    required String description,
    required String category,
    required List<String> tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (!page.canBeManagedBy(user.uid)) {
        return 'You cannot edit this page.';
      }

      final trimmedName = name.trim();
      final normalizedHandle = _normalizeHandle(handle);
      final trimmedDescription = description.trim();
      final trimmedCategory = category.trim().isEmpty
          ? 'page'
          : category.trim().toLowerCase();

      if (trimmedName.isEmpty) {
        return 'Please enter a page name.';
      }

      if (normalizedHandle.isEmpty) {
        return 'Please enter a page handle.';
      }

      if (normalizedHandle != page.handle) {
        final existingHandle = await _firestore
            .collection('public_pages')
            .where('handle', isEqualTo: normalizedHandle)
            .limit(1)
            .get();

        final handleTakenByOtherPage = existingHandle.docs.any(
          (doc) => doc.id != page.id,
        );

        if (handleTakenByOtherPage) {
          return 'This page handle is already taken.';
        }
      }

      await _firestore.collection('public_pages').doc(page.id).set(
        {
          'name': trimmedName,
          'handle': normalizedHandle,
          'description': trimmedDescription,
          'category': trimmedCategory,
          'tags': sanitizeEventTagIds(tags),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return null;
    } catch (_) {
      return 'Failed to update public page.';
    }
  }

  Future<String?> updatePublicPageImages({
    required PublicPage page,
    File? newPhotoFile,
    File? newBackgroundFile,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (!page.canBeManagedBy(user.uid)) {
        return 'You cannot edit this page.';
      }

      if (newPhotoFile == null && newBackgroundFile == null) {
        return null;
      }

      String? photoUrl = page.photoUrl;
      String? backgroundImageUrl = page.backgroundImageUrl;

      if (newPhotoFile != null) {
        final ref = _storage
            .ref()
            .child('public_pages/${page.id}/photo.jpg');

        await ref.putFile(newPhotoFile, _imageMetadata);
        photoUrl = await ref.getDownloadURL();
      }

      if (newBackgroundFile != null) {
        final ref = _storage
            .ref()
            .child('public_pages/${page.id}/background.jpg');

        await ref.putFile(newBackgroundFile, _imageMetadata);
        backgroundImageUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('public_pages').doc(page.id).set(
        {
          'photoUrl': photoUrl,
          'backgroundImageUrl': backgroundImageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return null;
    } catch (_) {
      return 'Failed to update page images.';
    }
  }

  Future<String?> addPageAdminByUsername({
    required PublicPage page,
    required String username,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (page.ownerUid != user.uid) {
        return 'Only the page owner can manage admins.';
      }

      final normalizedUsername = username
          .trim()
          .toLowerCase()
          .replaceAll('@', '');

      if (normalizedUsername.isEmpty) {
        return 'Please enter a username.';
      }

      final userQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return 'No user with this username was found.';
      }

      final targetDoc = userQuery.docs.first;
      final targetUid = targetDoc.id;

      if (targetUid == page.ownerUid) {
        return 'The owner is already allowed to manage this page.';
      }

      if (page.adminUids.contains(targetUid)) {
        return 'This user is already an admin.';
      }

      await _firestore.collection('public_pages').doc(page.id).set(
        {
          'adminUids': FieldValue.arrayUnion([targetUid]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return null;
    } catch (_) {
      return 'Failed to add admin.';
    }
  }

  Future<String?> removePageAdmin({
    required PublicPage page,
    required String adminUid,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (page.ownerUid != user.uid) {
        return 'Only the page owner can manage admins.';
      }

      if (adminUid == page.ownerUid) {
        return 'The owner cannot be removed from the page.';
      }

      await _firestore.collection('public_pages').doc(page.id).set(
        {
          'adminUids': FieldValue.arrayRemove([adminUid]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return null;
    } catch (_) {
      return 'Failed to remove admin.';
    }
  }

  Future<String?> followPage(PublicPage page) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final pageRef = _firestore.collection('public_pages').doc(page.id);

      final userFollowRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('followed_pages')
          .doc(page.id);

      final pageFollowerRef = pageRef.collection('followers').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final userFollowSnapshot = await transaction.get(userFollowRef);

        if (userFollowSnapshot.exists) return;

        transaction.set(userFollowRef, {
          'pageId': page.id,
          'name': page.name,
          'handle': page.handle,
          'photoUrl': page.photoUrl,
          'category': page.category,
          'tags': page.tags,
          'followedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(pageFollowerRef, {
          'uid': user.uid,
          'followedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(pageRef, {
          'followerCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return null;
    } catch (_) {
      return 'Failed to follow page.';
    }
  }

  Future<String?> unfollowPage(PublicPage page) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final pageRef = _firestore.collection('public_pages').doc(page.id);

      final userFollowRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('followed_pages')
          .doc(page.id);

      final pageFollowerRef = pageRef.collection('followers').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final userFollowSnapshot = await transaction.get(userFollowRef);

        if (!userFollowSnapshot.exists) return;

        transaction.delete(userFollowRef);
        transaction.delete(pageFollowerRef);

        transaction.update(pageRef, {
          'followerCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return null;
    } catch (_) {
      return 'Failed to unfollow page.';
    }
  }

  Future<String?> toggleFollowPage({
    required PublicPage page,
    required bool isFollowing,
  }) async {
    if (isFollowing) {
      return unfollowPage(page);
    }

    return followPage(page);
  }

  String _normalizeHandle(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('@', '')
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '');
  }
}