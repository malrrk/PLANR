import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';

final friendsServiceProvider = Provider<FriendsService>((ref) {
  return FriendsService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
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

  return FirebaseFirestore.instance
      .collection('friend_requests')
      .where('toUid', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['docId'] = doc.id;
          return data;
        }).toList(),
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
  final Uuid _uuid = const Uuid();

  Future<String?> sendFriendRequest({
    required UserProfile toUser,
  }) async {
    final me = _auth.currentUser;
    if (me == null) return 'No user logged in.';
    if (me.uid == toUser.uid) return 'You cannot add yourself.';

    final existing = await _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: me.uid)
        .where('toUid', isEqualTo: toUser.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return 'Request already sent.';
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

    await _firestore.collection('friend_requests').doc(_uuid.v4()).set({
      'fromUid': me.uid,
      'fromDisplayName': me.displayName ?? 'User',
      'fromPhotoUrl': me.photoURL,
      'toUid': toUser.uid,
      'toDisplayName': toUser.displayName,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return null;
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
    } catch (e) {
      return 'Failed to remove friend: $e';
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
    } catch (e) {
      return 'Failed to accept request: $e';
    }
  }
}