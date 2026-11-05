import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import 'event_provider.dart';
import 'firebase_providers.dart';

final accountServiceProvider = Provider<AccountService>((ref) {
  return AccountService(
    ref.watch(firestoreProvider),
    ref.watch(storageProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(eventServiceProvider),
  );
});

class AccountService {
  AccountService(this._firestore, this._storage, this._auth, this._events);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final EventService _events;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Re-checks the password, removes the user's data and finally the login. Safe to retry.
  Future<String?> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return 'No user logged in.';

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password.trim()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Password is incorrect.';
      }
      if (e.code == 'network-request-failed') {
        return 'Network error. Please check your connection.';
      }
      return 'Could not verify your password. Please try again.';
    }

    final uid = user.uid;

    try {
      final profile = await _userRef(uid).get();
      final username = profile.data()?['username'] as String?;

      final error = await _removeEvents(uid);
      if (error != null) return error;

      await _removeInvites(uid);
      await _removeFriends(uid);
      await _removeStories(uid);
      await _removeFollows(uid);
      await _removeOwnedPages(uid);
      await _removeFriendRequests(uid);
      await _deleteCollection(_userRef(uid).collection('blocked'));
      await _deleteFiles(['users/$uid/profile.jpg', 'users/$uid/background.jpg']);

      if (username != null && username.isNotEmpty) {
        await _firestore.collection('usernames').doc(username).delete();
      }
      await _userRef(uid).delete();
    } catch (_) {
      return 'We could not remove all of your data. Please try again.';
    }

    try {
      await user.delete();
    } catch (_) {
      return 'Your data was removed but the login could not be deleted. '
          'Log out, log in again and retry.';
    }

    return null;
  }

  Future<String?> _removeEvents(String uid) async {
    final mine = await _userRef(uid).collection('my_events').get();

    for (final doc in mine.docs) {
      final event = Event.fromMap(doc.data(), doc.id);
      final error = event.creatorUid == uid
          ? await _events.deleteEvent(event)
          : await _events.leaveEvent(event);
      if (error != null) return error;
    }

    return null;
  }

  Future<void> _removeInvites(String uid) async {
    final invites = await _userRef(uid).collection('event_invites').get();

    for (final doc in invites.docs) {
      await _ignoreErrors(
        () => _firestore
            .collection('events')
            .doc(doc.id)
            .collection('invites')
            .doc(uid)
            .delete(),
      );
      await doc.reference.delete();
    }
  }

  Future<void> _removeFriends(String uid) async {
    final friends = await _userRef(uid).collection('friends').get();

    for (final doc in friends.docs) {
      await _ignoreErrors(
        () => _userRef(doc.id).collection('friends').doc(uid).delete(),
      );
      await doc.reference.delete();
    }
  }

  Future<void> _removeStories(String uid) async {
    final stories = await _firestore
        .collection('stories')
        .where('ownerUid', isEqualTo: uid)
        .where('ownerType', isEqualTo: 'user')
        .get();

    for (final doc in stories.docs) {
      final imageUrl = doc.data()['imageUrl'] as String?;
      await doc.reference.delete();
      if (imageUrl != null) {
        await _ignoreErrors(() => _storage.refFromURL(imageUrl).delete());
      }
    }
  }

  Future<void> _removeFollows(String uid) async {
    final follows = await _userRef(uid).collection('followed_pages').get();

    for (final doc in follows.docs) {
      final pageRef = _firestore.collection('public_pages').doc(doc.id);

      await _ignoreErrors(
        () => _firestore.runTransaction((transaction) async {
          final page = await transaction.get(pageRef);
          transaction.delete(pageRef.collection('followers').doc(uid));
          transaction.delete(doc.reference);
          if (page.exists) {
            transaction.update(pageRef, {
              'followerCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }),
      );
    }
  }

  Future<void> _removeOwnedPages(String uid) async {
    final pages = await _firestore
        .collection('public_pages')
        .where('ownerUid', isEqualTo: uid)
        .get();

    for (final doc in pages.docs) {
      await doc.reference.delete();
      await _deleteFiles([
        'public_pages/${doc.id}/photo.jpg',
        'public_pages/${doc.id}/background.jpg',
      ]);
    }
  }

  Future<void> _removeFriendRequests(String uid) async {
    final sent = await _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: uid)
        .get();
    final received = await _firestore
        .collection('friend_requests')
        .where('toUid', isEqualTo: uid)
        .get();

    for (final doc in [...sent.docs, ...received.docs]) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteFiles(List<String> paths) async {
    for (final path in paths) {
      await _ignoreErrors(() => _storage.ref().child(path).delete());
    }
  }

  /// Cleanup of data that may already be gone must not abort the deletion.
  Future<void> _ignoreErrors(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {}
  }
}
