import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../models/event_tag.dart';
import '../models/event_update.dart';
import '../models/public_page.dart';
import 'firebase_providers.dart';

export '../models/event_update.dart';

final eventsProvider = StreamProvider<List<Event>>((ref) {
  return FirebaseFirestore.instance
      .collection('events')
      .where('visibility', isEqualTo: 'public')
      .orderBy('date')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .where((event) => event.eventKind == 'public')
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
    ref.watch(firestoreProvider),
    ref.watch(storageProvider),
    ref.watch(firebaseAuthProvider),
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

final linkedGroupForPublicEventProvider =
    StreamProvider.family<Event?, String>((ref, publicEventId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('events')
      .where('creatorUid', isEqualTo: user.uid)
      .where('eventKind', isEqualTo: 'linkedGroup')
      .where('linkedPublicEventId', isEqualTo: publicEventId)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return Event.fromMap(doc.data(), doc.id);
  });
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
      .where('status', whereIn: ['pending', 'declined'])
      .snapshots()
      .map((snapshot) {
    final invites = snapshot.docs.map((doc) {
      final data = doc.data();
      data['eventId'] = doc.id;
      return data;
    }).toList();

    invites.sort((a, b) {
      final aStatus = a['status'] as String? ?? 'pending';
      final bStatus = b['status'] as String? ?? 'pending';

      if (aStatus == 'pending' && bStatus == 'declined') return -1;
      if (aStatus == 'declined' && bStatus == 'pending') return 1;

      final aDate = a['eventDate'];
      final bDate = b['eventDate'];

      if (aDate is Timestamp && bDate is Timestamp) {
        return aDate.compareTo(bDate);
      }

      return 0;
    });

    return invites;
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

class LinkedGroupCreationResult {
  const LinkedGroupCreationResult({
    required this.group,
    required this.error,
  });

  final Event? group;
  final String? error;

  bool get success => group != null && error == null;
}

final eventUpdatesProvider =
    StreamProvider.family<List<EventUpdate>, String>((ref, eventId) {
  return FirebaseFirestore.instance
      .collection('events')
      .doc(eventId)
      .collection('updates')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => EventUpdate.fromMap(doc.data(), doc.id))
        .toList();
  });
});

class EventService {
  EventService(this._firestore, this._storage, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  DocumentReference<Map<String, dynamic>> _myEventRef(
    String uid,
    String eventId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('my_events')
        .doc(eventId);
  }

  Map<String, dynamic> _attendeeData(User user, String role) {
    return {
      'uid': user.uid,
      'displayName': user.displayName ?? 'User',
      'photoUrl': user.photoURL,
      'role': role,
      'joinedAt': FieldValue.serverTimestamp(),
    };
  }

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

    /// New optional phase-1 fields.
    /// Existing screens do not need to pass them yet.
    String? eventKind,
    String organizerType = 'profile',
    String? organizerId,
    String? organizerDisplayName,
    String? organizerPhotoUrl,
    bool organizerVerified = false,
    PublicPage? organizerPage,
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

      final resolvedEventKind =
          eventKind ?? (visibility == 'public' ? 'public' : 'private');

      final resolvedVisibility =
          resolvedEventKind == 'public' ? 'public' : visibility;

      final resolvedChatEnabled =
          resolvedEventKind == 'public' ? false : chatEnabled;

      final resolvedOrganizerType =
          organizerPage != null ? 'publicPage' : organizerType;

      final resolvedOrganizerId =
          organizerPage?.id ?? organizerId ?? user.uid;

      final resolvedOrganizerDisplayName =
          organizerPage?.name ??
              organizerDisplayName ??
              user.displayName ??
              'User';

      final resolvedOrganizerPhotoUrl =
          organizerPage?.photoUrl ?? organizerPhotoUrl ?? user.photoURL;

      final resolvedOrganizerVerified =
          organizerPage?.isVerified ?? organizerVerified;

      final eventId = _uuid.v4();

      String? imageUrl;
      if (imageFile != null) {
        final ref = _storage.ref().child('events/${user.uid}/$eventId.jpg');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final eventRef = _firestore.collection('events').doc(eventId);
      final attendeeRef = eventRef.collection('attendees').doc(user.uid);

      final myEventRef = _myEventRef(user.uid, eventId);

      final batch = _firestore.batch();

      final eventData = {
        'creatorUid': user.uid,
        'creatorDisplayName': user.displayName ?? 'User',
        'creatorPhotoUrl': user.photoURL,
        'eventKind': resolvedEventKind,
        'organizerType': resolvedOrganizerType,
        'organizerId': resolvedOrganizerId,
        'organizerDisplayName': resolvedOrganizerDisplayName,
        'organizerPhotoUrl': resolvedOrganizerPhotoUrl,
        'organizerVerified': resolvedOrganizerVerified,
        'title': trimmedTitle,
        'description': trimmedDescription,
        'address': trimmedAddress,
        'date': Timestamp.fromDate(date),
        'tags': sanitizedTags,
        'imageUrl': imageUrl,
        'visibility': resolvedVisibility,
        'chatEnabled': resolvedChatEnabled,
        'guestsCanInvite': guestsCanInvite,
        'attendeeCount': 1,
        'interestedCount': 0,
        'linkedPublicEventId': null,
        'linkedPublicEventTitle': null,
        'linkedPublicEventImageUrl': null,
        'linkedPublicEventDate': null,
        'linkedPublicEventAddress': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': null,
        'lastReadMessageAt': null,
        'lastMessageText': null,
        'lastMessageSenderUid': null,
        'lastMessageSenderName': null,
      };

      batch.set(eventRef, eventData);
      batch.set(myEventRef, eventData);

      batch.set(attendeeRef, _attendeeData(user, 'creator'));

      if (organizerPage != null) {
        final pageRef =
            _firestore.collection('public_pages').doc(organizerPage.id);

        batch.update(pageRef, {
          'eventCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      return null;
    } catch (_) {
      return 'Failed to create event.';
    }
  }

  Future<LinkedGroupCreationResult> createLinkedGroupFromPublicEventAndReturn({
    required Event publicEvent,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const LinkedGroupCreationResult(
          group: null,
          error: 'No user logged in.',
        );
      }

      if (!publicEvent.isPublicEvent) {
        return const LinkedGroupCreationResult(
          group: null,
          error: 'Groups can only be created from public events.',
        );
      }

      final existingGroupQuery = await _firestore
          .collection('events')
          .where('creatorUid', isEqualTo: user.uid)
          .where('eventKind', isEqualTo: 'linkedGroup')
          .where('linkedPublicEventId', isEqualTo: publicEvent.id)
          .limit(1)
          .get();

      if (existingGroupQuery.docs.isNotEmpty) {
        final doc = existingGroupQuery.docs.first;
        return LinkedGroupCreationResult(
          group: Event.fromMap(doc.data(), doc.id),
          error: null,
        );
      }

      final groupId = _uuid.v4();
      final now = DateTime.now();

      final groupRef = _firestore.collection('events').doc(groupId);
      final groupAttendeeRef = groupRef.collection('attendees').doc(user.uid);

      final publicEventRef = _firestore.collection('events').doc(publicEvent.id);
      final publicAttendeeRef =
          publicEventRef.collection('attendees').doc(user.uid);

      final userMyGroupRef = _myEventRef(user.uid, groupId);
      final userMyPublicEventRef = _myEventRef(user.uid, publicEvent.id);

      final publicAttendeeDoc = await publicAttendeeRef.get();

      final groupData = {
        'creatorUid': user.uid,
        'creatorDisplayName': user.displayName ?? 'User',
        'creatorPhotoUrl': user.photoURL,
        'eventKind': 'linkedGroup',
        'organizerType': 'profile',
        'organizerId': user.uid,
        'organizerDisplayName': user.displayName ?? 'User',
        'organizerPhotoUrl': user.photoURL,
        'organizerVerified': false,
        'title': 'Group for ${publicEvent.title}',
        'description':
            'Private group for coordinating with friends around this public event.',
        'address': publicEvent.address,
        'date': Timestamp.fromDate(publicEvent.date),
        'tags': publicEvent.tags,
        'imageUrl': publicEvent.imageUrl,
        'visibility': 'private',
        'chatEnabled': true,
        'guestsCanInvite': true,
        'attendeeCount': 1,
        'interestedCount': 0,
        'linkedPublicEventId': publicEvent.id,
        'linkedPublicEventTitle': publicEvent.title,
        'linkedPublicEventImageUrl': publicEvent.imageUrl,
        'linkedPublicEventDate': Timestamp.fromDate(publicEvent.date),
        'linkedPublicEventAddress': publicEvent.address,
        'createdAt': Timestamp.fromDate(now),
        'lastMessageAt': null,
        'lastReadMessageAt': null,
        'lastMessageText': null,
        'lastMessageSenderUid': null,
        'lastMessageSenderName': null,
      };

      final batch = _firestore.batch();

      batch.set(groupRef, groupData);
      batch.set(userMyGroupRef, groupData);

      batch.set(groupAttendeeRef, _attendeeData(user, 'creator'));

      if (!publicAttendeeDoc.exists) {
        batch.set(publicAttendeeRef, _attendeeData(user, 'member'));

        batch.update(publicEventRef, {
          'attendeeCount': FieldValue.increment(1),
        });

        final publicEventDoc = await publicEventRef.get();

        if (publicEventDoc.exists && publicEventDoc.data() != null) {
          batch.set(userMyPublicEventRef, {
            ...publicEventDoc.data()!,
            'lastReadMessageAt': publicEventDoc.data()!['lastMessageAt'],
          });
        }
      }

      await batch.commit();

      return LinkedGroupCreationResult(
        group: Event.fromMap(groupData, groupId),
        error: null,
      );
    } catch (_) {
      return const LinkedGroupCreationResult(
        group: null,
        error: 'Failed to create group.',
      );
    }
  }

  Future<String?> joinEvent(Event event) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final eventRef = _firestore.collection('events').doc(event.id);
      final attendeeRef = eventRef.collection('attendees').doc(user.uid);
      final myEventRef = _myEventRef(user.uid, event.id);

      if (!event.isPublicEvent) {
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

      final eventDoc = await eventRef.get();
      if (!eventDoc.exists || eventDoc.data() == null) {
        return 'Event not found.';
      }

      final eventData = eventDoc.data()!;

      final batch = _firestore.batch();

      batch.set(attendeeRef, _attendeeData(user, 'member'));

      batch.update(eventRef, {
        'attendeeCount': FieldValue.increment(1),
      });

      batch.set(myEventRef, {
        ...eventData,
        'lastReadMessageAt': eventData['lastMessageAt'],
      });

      await batch.commit();

      return null;
    } catch (_) {
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
      final myEventRef = _myEventRef(user.uid, event.id);

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
    } catch (_) {
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

      if (!eventDoc.exists || eventDoc.data() == null) {
        return 'Event not found.';
      }

      final eventData = eventDoc.data()!;

      final userInviteRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('event_invites')
          .doc(eventId);

      final inviteRef = eventRef.collection('invites').doc(user.uid);
      final attendeeRef = eventRef.collection('attendees').doc(user.uid);
      final myEventRef = _myEventRef(user.uid, eventId);

      final attendeeDoc = await attendeeRef.get();
      if (attendeeDoc.exists) {
        return 'You are already going.';
      }

      final inviteDoc = await inviteRef.get();
      if (!inviteDoc.exists) {
        return 'Invite not found.';
      }

      final inviteData = inviteDoc.data();
      final inviteStatus = inviteData?['status'] as String?;

      if (inviteStatus != 'pending' && inviteStatus != 'declined') {
        return 'Invite is no longer available.';
      }

      final batch = _firestore.batch();

      batch.set(attendeeRef, _attendeeData(user, 'member'));

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

      batch.set(myEventRef, {
        ...eventData,
        'attendeeCount': (eventData['attendeeCount'] as num? ?? 0).toInt() + 1,
        'lastReadMessageAt': eventData['lastMessageAt'],
      });

      await batch.commit();

      return null;
    } catch (_) {
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

      if (event.isPublicEvent) {
        return 'Create a group for this public event before inviting friends.';
      }

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
        'eventKind': event.eventKind,
        'eventTitle': event.title,
        'eventDescription': event.description,
        'eventImageUrl': event.imageUrl,
        'eventAddress': event.address,
        'eventTags': event.tags,
        'eventDate': Timestamp.fromDate(event.date),
        'linkedPublicEventId': event.linkedPublicEventId,
        'linkedPublicEventTitle': event.linkedPublicEventTitle,
        'linkedPublicEventImageUrl': event.linkedPublicEventImageUrl,
        'invitedByUid': user.uid,
        'invitedByDisplayName': user.displayName ?? 'User',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(inviteRef, inviteData);
      batch.set(userInviteRef, inviteData);

      await batch.commit();

      return null;
    } catch (_) {
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
    } catch (_) {
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

      final resolvedVisibility = event.isPublicEvent ? 'public' : visibility;
      final resolvedChatEnabled =
          event.isPublicEvent ? false : chatEnabled;

      final updateData = {
        'title': trimmedTitle,
        'description': trimmedDescription,
        'address': trimmedAddress,
        'tags': sanitizedTags,
        'date': Timestamp.fromDate(date),
        'imageUrl': imageUrl,
        'visibility': event.isLinkedGroup ? 'private' : resolvedVisibility,
        'chatEnabled': resolvedChatEnabled,
        'guestsCanInvite': guestsCanInvite,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final eventRef = _firestore.collection('events').doc(event.id);
      final attendeesSnapshot = await eventRef.collection('attendees').get();

      final batch = _firestore.batch();

      batch.update(eventRef, updateData);

      for (final attendee in attendeesSnapshot.docs) {
        final attendeeMyEventRef = _myEventRef(attendee.id, event.id);

        batch.set(
          attendeeMyEventRef,
          updateData,
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      return null;
    } catch (_) {
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

        final attendeeMyEventRef = _myEventRef(attendeeUid, event.id);

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

      final creatorMyEventRef = _myEventRef(user.uid, event.id);

      batch.delete(creatorMyEventRef);
      batch.delete(eventRef);

      if (event.isOrganizedByPage) {
        final pageRef =
            _firestore.collection('public_pages').doc(event.organizerId);

        batch.update(pageRef, {
          'eventCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (event.imageUrl != null) {
        try {
          await _storage.refFromURL(event.imageUrl!).delete();
        } catch (_) {}
      }

      return null;
    } catch (_) {
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

      if (event.isPublicEvent || !event.chatEnabled) {
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

        final myEventRef = _myEventRef(attendeeUid, event.id);

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
    } catch (_) {
      return 'Failed to send message.';
    }
  }

  Future<String?> createEventUpdate({
    required Event event,
    required String text,
    bool isPinned = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      final trimmedText = text.trim();
      if (trimmedText.isEmpty) return 'Update cannot be empty.';

      if (trimmedText.length > 600) {
        return 'Update is too long.';
      }

      if (!event.isPublicEvent) {
        return 'Updates are only available for public events.';
      }

      final canPost = await _canManageEventUpdates(event);
      if (!canPost) {
        return 'You cannot post updates for this event.';
      }

      final updateRef = _firestore
          .collection('events')
          .doc(event.id)
          .collection('updates')
          .doc();

      await updateRef.set({
        'authorUid': user.uid,
        'authorName': user.displayName ?? 'Organizer',
        'authorPhotoUrl': user.photoURL,
        'text': trimmedText,
        'isPinned': isPinned,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (_) {
      return 'Failed to post update.';
    }
  }

  Future<String?> deleteEventUpdate({
    required Event event,
    required String updateId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      if (!event.isPublicEvent) {
        return 'Updates are only available for public events.';
      }

      final canDelete = await _canManageEventUpdates(event);
      if (!canDelete) {
        return 'You cannot delete updates for this event.';
      }

      await _firestore
          .collection('events')
          .doc(event.id)
          .collection('updates')
          .doc(updateId)
          .delete();

      return null;
    } catch (_) {
      return 'Failed to delete update.';
    }
  }

  Future<bool> canManageEventUpdates(Event event) {
    return _canManageEventUpdates(event);
  }

  Future<bool> _canManageEventUpdates(Event event) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    if (event.creatorUid == user.uid) return true;

    if (!event.isOrganizedByPage) return false;

    final pageDoc = await _firestore
        .collection('public_pages')
        .doc(event.organizerId)
        .get();

    if (!pageDoc.exists || pageDoc.data() == null) return false;

    final data = pageDoc.data()!;
    final ownerUid = data['ownerUid'] as String?;
    final adminUidsRaw = data['adminUids'];

    final adminUids = adminUidsRaw is List
        ? adminUidsRaw.whereType<String>().toList()
        : <String>[];

    return ownerUid == user.uid || adminUids.contains(user.uid);
  }

  Future<String?> markEventChatReadAt({
    required String eventId,
    required DateTime lastMessageAt,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      await _myEventRef(user.uid, eventId).set(
        {
          'lastReadMessageAt': Timestamp.fromDate(lastMessageAt),
        },
        SetOptions(merge: true),
      );

      return null;
    } catch (_) {
      return 'Failed to mark chat as read.';
    }
  }
}