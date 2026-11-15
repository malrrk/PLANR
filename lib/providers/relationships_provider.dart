import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_providers.dart';

/// The user's private "Close friends" list. Only the owner can read it and the other
/// person is never notified, so two people can classify each other differently.
final closeFriendUidsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(const <String>{});

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .collection('relationships')
      .where('tier', isEqualTo: 'close')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
});

final relationshipsServiceProvider = Provider<RelationshipsService>((ref) {
  return RelationshipsService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class RelationshipsService {
  RelationshipsService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String?> setCloseFriend(String otherUid, bool close) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final ref = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('relationships')
          .doc(otherUid);

      if (close) {
        await ref.set({
          'uid': otherUid,
          'tier': 'close',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.delete();
      }

      return null;
    } catch (_) {
      return 'Could not update your close friends.';
    }
  }
}
