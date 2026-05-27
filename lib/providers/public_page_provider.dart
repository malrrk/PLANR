import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import '../models/public_page.dart';

final publicPageServiceProvider = Provider<PublicPageService>((ref) {
  return PublicPageService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final publicPagesProvider = StreamProvider<List<PublicPage>>((ref) {
  return FirebaseFirestore.instance
      .collection('public_pages')
      .where('isActive', isEqualTo: true)
      .orderBy('followerCount', descending: true)
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
    final pages = <PublicPage>[];

    for (final pageId in pageIds) {
      final pageDoc = await firestore.collection('public_pages').doc(pageId).get();

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
      .where('hostType', isEqualTo: 'page')
      .where('hostId', isEqualTo: pageId)
      .orderBy('date')
      .snapshots()
      .map((snapshot) {
    final now = DateTime.now();

    return snapshot.docs
        .map((doc) => Event.fromMap(doc.data(), doc.id))
        .where((event) => event.date.isAfter(now))
        .toList();
  });
});

class PublicPageService {
  PublicPageService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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
}