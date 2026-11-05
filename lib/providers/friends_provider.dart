import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import 'firebase_providers.dart';
import 'moderation_provider.dart';

/// One request per ordered pair; Firestore rules rely on this id format.
String friendRequestId({required String fromUid, required String toUid}) {
  return '${fromUid}_$toUid';
}

/// A declined request can be sent again after this long (mirrored in the Firestore rules).
const Duration friendRequestCooldown = Duration(days: 7);

final friendsServiceProvider = Provider<FriendsService>((ref) {
  return FriendsService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final myFriendsProvider = StreamProvider<List<UserProfile>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('friends')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => UserProfile.fromMap(doc.data()))
            .toList(),
      );
});

final incomingFriendRequestsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  final blocked = ref.watch(blockedUidsProvider).value ?? const <String>{};

  return FirebaseFirestore.instance
      .collection('friend_requests')
      .where('toUid', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['docId'] = doc.id;
              return data;
            })
            .where((request) => !blocked.contains(request['fromUid']))
            .toList(),
      );
});

enum FriendRelationshipStatus {
  self,
  friends,
  outgoingPending,
  incomingPending,
  none,
}

class FriendRelationship {
  const FriendRelationship({
    required this.status,
    this.incomingRequestId,
    this.incomingRequest,
  });

  final FriendRelationshipStatus status;
  final String? incomingRequestId;
  final Map<String, dynamic>? incomingRequest;
}

final friendsCountProvider = StreamProvider.family<int, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('friends')
      .snapshots()
      .map((snapshot) => snapshot.size);
});

final friendRelationshipProvider =
    FutureProvider.family<FriendRelationship, String>((ref, otherUid) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const FriendRelationship(
      status: FriendRelationshipStatus.none,
    );
  }

  if (user.uid == otherUid) {
    return const FriendRelationship(
      status: FriendRelationshipStatus.self,
    );
  }

  final firestore = FirebaseFirestore.instance;

  final friendDoc = await firestore
      .collection('users')
      .doc(user.uid)
      .collection('friends')
      .doc(otherUid)
      .get();

  if (friendDoc.exists) {
    return const FriendRelationship(
      status: FriendRelationshipStatus.friends,
    );
  }

  final outgoing = await firestore
      .collection('friend_requests')
      .where('fromUid', isEqualTo: user.uid)
      .where('toUid', isEqualTo: otherUid)
      .where('status', isEqualTo: 'pending')
      .limit(1)
      .get();

  if (outgoing.docs.isNotEmpty) {
    return const FriendRelationship(
      status: FriendRelationshipStatus.outgoingPending,
    );
  }

  final incoming = await firestore
      .collection('friend_requests')
      .where('fromUid', isEqualTo: otherUid)
      .where('toUid', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending')
      .limit(1)
      .get();

  if (incoming.docs.isNotEmpty) {
    final doc = incoming.docs.first;
    final data = doc.data();
    data['docId'] = doc.id;

    return FriendRelationship(
      status: FriendRelationshipStatus.incomingPending,
      incomingRequestId: doc.id,
      incomingRequest: data,
    );
  }

  return const FriendRelationship(
    status: FriendRelationshipStatus.none,
  );
});

class FriendsService {
  FriendsService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String?> sendFriendRequest({
    required UserProfile toUser,
  }) async {
    final me = _auth.currentUser;
    if (me == null) return 'No user logged in.';
    if (me.uid == toUser.uid) return 'You cannot add yourself.';

    try {
      final sent = await _firestore
          .collection('friend_requests')
          .where('fromUid', isEqualTo: me.uid)
          .where('toUid', isEqualTo: toUser.uid)
          .limit(1)
          .get();

      if (sent.docs.isNotEmpty) {
        final previous = sent.docs.first.data();

        if (previous['status'] == 'pending') {
          return 'Request already sent.';
        }

        final declinedAt = previous['declinedAt'];
        if (previous['status'] == 'declined' &&
            (declinedAt is! Timestamp ||
                DateTime.now().difference(declinedAt.toDate()) <
                    friendRequestCooldown)) {
          return 'You cannot send another request right now.';
        }
      }

      final received = await _firestore
          .collection('friend_requests')
          .where('fromUid', isEqualTo: toUser.uid)
          .where('toUid', isEqualTo: me.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (received.docs.isNotEmpty) {
        return '${toUser.displayName} already sent you a request. '
            'Accept it in your friend requests.';
      }

      final alreadyFriends = await _firestore
          .collection('users')
          .doc(me.uid)
          .collection('friends')
          .doc(toUser.uid)
          .get();

      if (alreadyFriends.exists) {
        return 'You are already friends.';
      }

      await _firestore
          .collection('friend_requests')
          .doc(friendRequestId(fromUid: me.uid, toUid: toUser.uid))
          .set({
        'fromUid': me.uid,
        'fromDisplayName': me.displayName ?? 'User',
        'fromPhotoUrl': me.photoURL,
        'toUid': toUser.uid,
        'toDisplayName': toUser.displayName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      return 'Could not send friend request.';
    }

    return null;
  }

  Future<String?> declineFriendRequest({required String requestId}) async {
    final user = _auth.currentUser;
    if (user == null) return 'No user logged in.';
    if (requestId.trim().isEmpty) return 'Friend request not found.';

    try {
      final requestRef = _firestore.collection('friend_requests').doc(requestId);
      return await _firestore.runTransaction<String?>((transaction) async {
        final snapshot = await transaction.get(requestRef);
        final request = snapshot.data();
        if (request == null) return 'Friend request not found.';
        if (request['toUid'] != user.uid) {
          return 'Only the receiving user can decline this request.';
        }
        if (request['status'] != 'pending') {
          return 'Friend request is no longer pending.';
        }
        transaction.update(requestRef, {
          'status': 'declined',
          'declinedAt': FieldValue.serverTimestamp(),
        });
        return null;
      });
    } catch (_) {
      return 'Could not decline request.';
    }
  }

  Future<String?> removeFriend({
    required String friendUid,
  }) async {
    final me = _auth.currentUser;
    if (me == null) return 'No user logged in.';

    try {
      final batch = _firestore.batch();

      batch.delete(
        _firestore
            .collection('users')
            .doc(me.uid)
            .collection('friends')
            .doc(friendUid),
      );

      batch.delete(
        _firestore
            .collection('users')
            .doc(friendUid)
            .collection('friends')
            .doc(me.uid),
      );

      await batch.commit();
      return null;
    } catch (_) {
      return 'Failed to remove friend.';
    }
  }

  Future<String?> acceptFriendRequest({
    required String requestId,
    required Map<String, dynamic> request,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 'No user logged in.';

      final fromUid = request['fromUid'] as String;
      final toUid = request['toUid'] as String;

      if (currentUser.uid != toUid) {
        return 'Only the receiving user can accept this request.';
      }

      final fromUserDoc =
          await _firestore.collection('users').doc(fromUid).get();
      final toUserDoc =
          await _firestore.collection('users').doc(toUid).get();

      if (!fromUserDoc.exists) {
        return 'Sender profile not found.';
      }

      if (!toUserDoc.exists) {
        return 'Receiver profile not found.';
      }

      final fromUser = UserProfile.fromMap(fromUserDoc.data()!);
      final toUser = UserProfile.fromMap(toUserDoc.data()!);

      final batch = _firestore.batch();

      batch.set(
        _firestore
            .collection('users')
            .doc(fromUid)
            .collection('friends')
            .doc(toUid),
        toUser.toMap(),
      );

      batch.set(
        _firestore
            .collection('users')
            .doc(toUid)
            .collection('friends')
            .doc(fromUid),
        fromUser.toMap(),
      );

      batch.update(
        _firestore.collection('friend_requests').doc(requestId),
        {
          'status': 'accepted',
        },
      );

      await batch.commit();
      return null;
    } catch (_) {
      return 'Failed to accept request.';
    }
  }
}