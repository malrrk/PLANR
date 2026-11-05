import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_providers.dart';

const List<String> reportReasons = [
  'Spam or scam',
  'Harassment or hate',
  'Nudity or sexual content',
  'Violence or dangerous acts',
  'Illegal activity',
  'Other',
];

enum ReportTarget { event, user, page, story, message }

/// Uids the signed-in user has blocked. Empty while loading or signed out.
final blockedUidsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(const <String>{});

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .collection('blocked')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
});

final moderationServiceProvider = Provider<ModerationService>((ref) {
  return ModerationService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class ModerationService {
  ModerationService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String?> report({
    required ReportTarget target,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'No user logged in.';
    if (targetId.trim().isEmpty) return 'Nothing to report.';

    final trimmedDetails = details?.trim();

    try {
      await _firestore.collection('reports').add({
        'reporterUid': user.uid,
        'targetType': target.name,
        'targetId': targetId,
        'reason': reason,
        if (trimmedDetails != null && trimmedDetails.isNotEmpty)
          'details': trimmedDetails.length > 500
              ? trimmedDetails.substring(0, 500)
              : trimmedDetails,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (_) {
      return 'Could not send your report. Please try again.';
    }
  }

  /// Blocks the user and ends any friendship with them.
  Future<String?> blockUser(String uid) async {
    final me = _auth.currentUser;
    if (me == null) return 'No user logged in.';
    if (me.uid == uid) return 'You cannot block yourself.';

    try {
      final batch = _firestore.batch();

      batch.set(
        _firestore.collection('users').doc(me.uid).collection('blocked').doc(uid),
        {'uid': uid, 'createdAt': FieldValue.serverTimestamp()},
      );
      batch.delete(
        _firestore.collection('users').doc(me.uid).collection('friends').doc(uid),
      );
      batch.delete(
        _firestore.collection('users').doc(uid).collection('friends').doc(me.uid),
      );

      await batch.commit();
      return null;
    } catch (_) {
      return 'Could not block this user. Please try again.';
    }
  }

  Future<String?> unblockUser(String uid) async {
    final me = _auth.currentUser;
    if (me == null) return 'No user logged in.';

    try {
      await _firestore
          .collection('users')
          .doc(me.uid)
          .collection('blocked')
          .doc(uid)
          .delete();
      return null;
    } catch (_) {
      return 'Could not unblock this user. Please try again.';
    }
  }
}
