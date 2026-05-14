import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../models/event_tag.dart';

final eventsProvider = StreamProvider<List<Event>>((ref) {
  return FirebaseFirestore.instance
      .collection('events')
      .where('visibility', isEqualTo: 'public')
      .orderBy('date')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

final eventByIdProvider =
    StreamProvider.family<Event?, String>((ref, eventId) {
  return FirebaseFirestore.instance
      .collection('events')
      .doc(eventId)
      .snapshots()
      .map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return Event.fromMap(doc.data()!, doc.id);
  });
});

final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    FirebaseAuth.instance,
  );
});

final myEventsProvider = StreamProvider<List<Event>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('my_events')
      .orderBy('date')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

final eventAttendeesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, eventId) {
  return FirebaseFirestore.instance
      .collection('events')
      .doc(eventId)
      .collection('attendees')
      .orderBy('joinedAt')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
      );
});

enum EventInviteFriendStatus {
  invite,
  invited,
  going,
  declined,
  accepted,
}

final friendEventInviteStatusProvider =
    StreamProvider.family<EventInviteFriendStatus, FriendEventInviteStatusArgs>(
  (ref, args) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('events')
        .doc(args.eventId)
        .snapshots()
        .asyncMap((_) async {
      final attendeeDoc = await firestore
          .collection('events')
          .doc(args.eventId)
          .collection('attendees')
          .doc(args.userId)
          .get();

      if (attendeeDoc.exists) {
        return EventInviteFriendStatus.going;
      }

      final inviteDoc = await firestore
          .collection('events')
          .doc(args.eventId)
          .collection('invites')
          .doc(args.userId)
          .get();

      if (!inviteDoc.exists) {
        return EventInviteFriendStatus.invite;
      }

      final status = inviteDoc.data()?['status'] as String?;

      return switch (status) {
        'pending' => EventInviteFriendStatus.invited,
        'accepted' => EventInviteFriendStatus.accepted,
        'declined' => EventInviteFriendStatus.declined,
        _ => EventInviteFriendStatus.invite,
      };
    });
  },
);

class FriendEventInviteStatusArgs {
  const FriendEventInviteStatusArgs({
    required this.eventId,
    required this.userId,
  });

  final String eventId;
  final String userId;

  @override
  bool operator ==(Object other) {
    return other is FriendEventInviteStatusArgs &&
        other.eventId == eventId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(eventId, userId);
}

final myEventInvitesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('event_invites')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['eventId'] = doc.id;
      return data;
    }).toList();
  });
});

final isGoingProvider = StreamProvider.family<bool, String>((ref, eventId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('events')
      .doc(eventId)
      .collection('attendees')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists);
});

final eventMessagesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, eventId) {
  return FirebaseFirestore.instance
      .collection('events')
      .doc(eventId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList());
});

class EventService {
  EventService(this._firestore, this._storage, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  Future<String?> createEvent({
    required String title,
    required String description,
    required String address,
    required DateTime date,
    required String visibility,
    required bool chatEnabled,
    required bool guestsCanInvite,
    required List<String> tags,
    File? imageFile,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'No user logged in.';
      }

      final trimmedTitle = title.trim();
      final trimmedDescription = description.trim();
      final trimmedAddress = address.trim();
      final sanitizedTags = sanitizeEventTagIds(tags);

      if (trimmedTitle.isEmpty ||
          trimmedDescription.isEmpty ||
          trimmedAddress.isEmpty) {
        return 'Please fill in all fields.';
      }

      if (date.isBefore(DateTime.now())) {
        return 'Event date must be in the future.';
      }

      final eventId = _uuid.v4();

      String? imageUrl;
      if (imageFile != null) {
        final ref = _storage.ref().child('events/${user.uid}/$eventId.jpg');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final eventRef = _firestore.collection('events').doc(eventId);
      final attendeeRef = eventRef.collection('attendees').doc(user.uid);

      final myEventRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_events')
          .doc(eventId);

      final batch = _firestore.batch();

      final eventData = {
        'creatorUid': user.uid,
        'creatorDisplayName': user.displayName ?? 'User',
        'creatorPhotoUrl': user.photoURL,
        'title': trimmedTitle,
        'description': trimmedDescription,
        'address': trimmedAddress,
        'date': Timestamp.fromDate(date),
        'tags': sanitizedTags,
        'imageUrl': imageUrl,
        'visibility': visibility,
        'chatEnabled': chatEnabled,
        'guestsCanInvite': guestsCanInvite,
        'attendeeCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': null,
        'lastReadMessageAt': null,
        'lastMessageText': null,
        'lastMessageSenderUid': null,
        'lastMessageSenderName': null,
      };

      batch.set(eventRef, eventData);
      batch.set(myEventRef, eventData);

      batch.set(attendeeRef, {
        'uid': user.uid,
        'displayName': user.displayName ?? 'User',
        'photoUrl': user.photoURL,
        'role': 'creator',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return null;
    } catch (e) {
      return 'Failed to create event.';
    }
  }

  Future<String?> joinEvent(Event event) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final eventRef = _firestore.collection('events').doc(event.id);
      final attendeeRef = eventRef.collection('attendees').doc(user.uid);
      final myEventRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_events')
          .doc(event.id);

      if (event.visibility == 'private') {
        final inviteDoc =
            await eventRef.collection('invites').doc(user.uid).get();

        final isCreator = event.creatorUid == user.uid;

        if (!isCreator &&
            (!inviteDoc.exists || inviteDoc.data()?['status'] != 'pending')) {
          return 'You need an invite to join this event.';
        }
      }

      final attendeeDoc = await attendeeRef.get();
      if (attendeeDoc.exists) {
        return 'You are already going.';
      }

      final batch = _firestore.batch();

      batch.set(attendeeRef, {
        'uid': user.uid,
        'displayName': user.displayName ?? 'User',
        'photoUrl': user.photoURL,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      batch.update(eventRef, {
        'attendeeCount': FieldValue.increment(1),
      });

      final eventDoc = await eventRef.get();
      if (!eventDoc.exists || eventDoc.data() == null) {
        return 'Event not found.';
      }

      final eventData = eventDoc.data()!;

      batch.set(myEventRef, {
        ...eventData,
        'lastReadMessageAt': eventData['lastMessageAt'],
      });

      await batch.commit();

      return null;
    } catch (e) {
      return 'Failed to join event.';
    }
  }

  Future<String?> leaveEvent(Event event) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (event.creatorUid == user.uid) {
        return 'The creator cannot leave their own event.';
      }

      final eventRef = _firestore.collection('events').doc(event.id);
      final attendeeRef = eventRef.collection('attendees').doc(user.uid);
      final myEventRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_events')
          .doc(event.id);

      final attendeeDoc = await attendeeRef.get();
      if (!attendeeDoc.exists) {
        return 'You are not going to this event.';
      }

      final batch = _firestore.batch();

      batch.delete(attendeeRef);

      batch.update(eventRef, {
        'attendeeCount': FieldValue.increment(-1),
      });

      batch.delete(myEventRef);

      await batch.commit();

      return null;
    } catch (e) {
      return 'Failed to leave event.';
    }
  }

  Future<String?> acceptEventInvite({
    required String eventId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final eventRef = _firestore.collection('events').doc(eventId);
      final eventDoc = await eventRef.get();

      if (!eventDoc.exists) {
        return 'Event not found.';
      }

      final userInviteRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('event_invites')
          .doc(eventId);

      final inviteRef = eventRef.collection('invites').doc(user.uid);
      final attendeeRef = eventRef.collection('attendees').doc(user.uid);
      final myEventRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_events')
          .doc(eventId);

      final inviteDoc = await inviteRef.get();
      if (!inviteDoc.exists) {
        return 'Invite not found.';
      }

      final inviteData = inviteDoc.data();
      if (inviteData?['status'] != 'pending') {
        return 'Invite is no longer pending.';
      }

      final batch = _firestore.batch();

      batch.set(attendeeRef, {
        'uid': user.uid,
        'displayName': user.displayName ?? 'User',
        'photoUrl': user.photoURL,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      batch.update(inviteRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      batch.update(eventRef, {
        'attendeeCount': FieldValue.increment(1),
      });

      batch.update(userInviteRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      final eventData = eventDoc.data()!;

      batch.set(myEventRef, {
        ...eventData,
        'attendeeCount': (eventData['attendeeCount'] as num? ?? 0).toInt() + 1,
        'lastReadMessageAt': eventData['lastMessageAt'],
      });

      await batch.commit();

      return null;
    } catch (e) {
      return 'Failed to accept invite.';
    }
  }

  Future<String?> inviteUserToEvent({
    required Event event,
    required String invitedUid,
    required String invitedDisplayName,
    String? invitedPhotoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final isCreator = event.creatorUid == user.uid;

      if (!isCreator && !event.guestsCanInvite) {
        return 'Guests cannot invite others to this event.';
      }

      final userInviteRef = _firestore
          .collection('users')
          .doc(invitedUid)
          .collection('event_invites')
          .doc(event.id);

      final eventRef = _firestore.collection('events').doc(event.id);
      final inviteRef = eventRef.collection('invites').doc(invitedUid);
      final attendeeRef = eventRef.collection('attendees').doc(invitedUid);

      final attendeeDoc = await attendeeRef.get();
      if (attendeeDoc.exists) {
        return 'This user is already going.';
      }

      final batch = _firestore.batch();

      final inviteData = {
        'uid': invitedUid,
        'displayName': invitedDisplayName,
        'photoUrl': invitedPhotoUrl,
        'eventId': event.id,
        'eventTitle': event.title,
        'eventDescription': event.description,
        'eventImageUrl': event.imageUrl,
        'eventAddress': event.address,
        'eventTags': event.tags,
        'eventDate': Timestamp.fromDate(event.date),
        'invitedByUid': user.uid,
        'invitedByDisplayName': user.displayName ?? 'User',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(inviteRef, inviteData);
      batch.set(userInviteRef, inviteData);

      await batch.commit();

      return null;
    } catch (e) {
      return 'Failed to invite user.';
    }
  }

  Future<String?> declineEventInvite({
    required String eventId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final eventInviteRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('invites')
          .doc(user.uid);

      final userInviteRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('event_invites')
          .doc(eventId);

      final batch = _firestore.batch();

      batch.update(eventInviteRef, {
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      batch.update(userInviteRef, {
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return null;
    } catch (e) {
      return 'Failed to decline invite.';
    }
  }

  Future<String?> updateEvent({
    required Event event,
    required String title,
    required String description,
    required String address,
    required List<String> tags,
    required DateTime date,
    required String visibility,
    required bool chatEnabled,
    required bool guestsCanInvite,
    File? newImageFile,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (event.creatorUid != user.uid) {
        return 'Only the creator can edit this event.';
      }

      final trimmedTitle = title.trim();
      final trimmedDescription = description.trim();
      final trimmedAddress = address.trim();
      final sanitizedTags = sanitizeEventTagIds(tags);

      if (trimmedTitle.isEmpty ||
          trimmedDescription.isEmpty ||
          trimmedAddress.isEmpty) {
        return 'Please fill in all fields.';
      }

      String? imageUrl = event.imageUrl;

      if (newImageFile != null) {
        final ref = _storage.ref().child('events/${user.uid}/${event.id}.jpg');
        await ref.putFile(newImageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final updateData = {
        'title': trimmedTitle,
        'description': trimmedDescription,
        'address': trimmedAddress,
        'tags': sanitizedTags,
        'date': Timestamp.fromDate(date),
        'imageUrl': imageUrl,
        'visibility': visibility,
        'chatEnabled': chatEnabled,
        'guestsCanInvite': guestsCanInvite,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('events').doc(event.id).update(updateData);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_events')
          .doc(event.id)
          .set(updateData, SetOptions(merge: true));

      return null;
    } catch (e) {
      return 'Failed to update event.';
    }
  }

  Future<String?> deleteEvent(Event event) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (event.creatorUid != user.uid) {
        return 'Only the creator can delete this event.';
      }

      final eventRef = _firestore.collection('events').doc(event.id);

      final attendeesSnapshot = await eventRef.collection('attendees').get();
      final invitesSnapshot = await eventRef.collection('invites').get();
      final messagesSnapshot = await eventRef.collection('messages').get();

      final batch = _firestore.batch();

      for (final attendeeDoc in attendeesSnapshot.docs) {
        final attendeeUid = attendeeDoc.id;

        batch.delete(attendeeDoc.reference);

        final attendeeMyEventRef = _firestore
            .collection('users')
            .doc(attendeeUid)
            .collection('my_events')
            .doc(event.id);

        batch.delete(attendeeMyEventRef);
      }

      for (final inviteDoc in invitesSnapshot.docs) {
        batch.delete(inviteDoc.reference);

        final invitedUid = inviteDoc.id;

        final userInviteRef = _firestore
            .collection('users')
            .doc(invitedUid)
            .collection('event_invites')
            .doc(event.id);

        batch.delete(userInviteRef);
      }

      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }

      final creatorMyEventRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_events')
          .doc(event.id);

      batch.delete(creatorMyEventRef);
      batch.delete(eventRef);

      await batch.commit();

      if (event.imageUrl != null) {
        try {
          await _storage.refFromURL(event.imageUrl!).delete();
        } catch (_) {}
      }

      return null;
    } catch (e) {
      return 'Failed to delete event.';
    }
  }

  Future<String?> sendEventMessage({
    required Event event,
    required String text,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final trimmedText = text.trim();
      if (trimmedText.isEmpty) return 'Message cannot be empty.';

      if (!event.chatEnabled) {
        return 'Chat is disabled for this event.';
      }

      final eventRef = _firestore.collection('events').doc(event.id);

      final attendeeDoc =
          await eventRef.collection('attendees').doc(user.uid).get();

      if (!attendeeDoc.exists) {
        return 'Only attendees can send messages.';
      }

      final attendeesSnapshot = await eventRef.collection('attendees').get();

      final batch = _firestore.batch();
      final messageRef = eventRef.collection('messages').doc();

      batch.set(messageRef, {
        'senderUid': user.uid,
        'senderDisplayName': user.displayName ?? 'User',
        'senderPhotoUrl': user.photoURL,
        'text': trimmedText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final chatSummary = {
        'lastMessageText': trimmedText,
        'lastMessageSenderUid': user.uid,
        'lastMessageSenderName': user.displayName ?? 'User',
        'lastMessageAt': FieldValue.serverTimestamp(),
      };

      batch.update(eventRef, chatSummary);

      for (final attendee in attendeesSnapshot.docs) {
        final attendeeUid = attendee.id;

        final myEventRef = _firestore
            .collection('users')
            .doc(attendeeUid)
            .collection('my_events')
            .doc(event.id);

        if (attendeeUid == user.uid) {
          batch.update(myEventRef, {
            ...chatSummary,
            'lastReadMessageAt': FieldValue.serverTimestamp(),
          });
        } else {
          batch.update(myEventRef, chatSummary);
        }
      }

      await batch.commit();

      return null;
    } catch (e) {
      return 'Failed to send message.';
    }
  }

  Future<String?> markEventChatReadAt({
    required String eventId,
    required DateTime lastMessageAt,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_events')
          .doc(eventId)
          .set(
        {
          'lastReadMessageAt': Timestamp.fromDate(lastMessageAt),
        },
        SetOptions(merge: true),
      );

      return null;
    } catch (e) {
      return 'Failed to mark chat as read.';
    }
  }
}