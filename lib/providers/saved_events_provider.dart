import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import 'firebase_providers.dart';

/// Private bookmarks; saving an event never means attending it.
final savedEventsProvider = StreamProvider<List<Event>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return Stream<List<Event>>.multi((controller) {
    final eventSubscriptions = <StreamSubscription<dynamic>>[];
    var generation = 0;
    final bookmarks = firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_events')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      generation++;
      final currentGeneration = generation;
      for (final subscription in eventSubscriptions) {
        subscription.cancel();
      }
      eventSubscriptions.clear();

      final ids = snapshot.docs.map((doc) => doc.id).toList();
      if (ids.isEmpty) {
        controller.add([]);
        return;
      }

      final events = <String, Event?>{};
      for (final id in ids) {
        eventSubscriptions.add(
          firestore.collection('events').doc(id).snapshots().listen((doc) {
            if (generation != currentGeneration) return;
            final data = doc.data();
            events[id] = data == null ? null : Event.fromMap(data, doc.id);
            if (events.length == ids.length) {
              controller.add(ids.map((id) => events[id]).whereType<Event>().toList());
            }
          }, onError: controller.addError),
        );
      }
    }, onError: controller.addError);

    controller.onCancel = () async {
      generation++;
      await bookmarks.cancel();
      await Future.wait(eventSubscriptions.map((subscription) => subscription.cancel()));
    };
  });
});

final isEventSavedProvider =
    StreamProvider.family<bool, String>((ref, eventId) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(false);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .collection('saved_events')
      .doc(eventId)
      .snapshots()
      .map((doc) => doc.exists);
});

final savedEventsServiceProvider = Provider<SavedEventsService>((ref) {
  return SavedEventsService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class SavedEventsService {
  SavedEventsService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>>? _ref(String eventId) {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_events')
        .doc(eventId);
  }

  Future<String?> save(Event event) async {
    try {
      final ref = _ref(event.id);
      if (ref == null) return 'No user logged in.';

      await ref.set({
        ...event.toMap(),
        'savedAt': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (_) {
      return 'Could not save this event.';
    }
  }

  Future<String?> unsave(String eventId) async {
    try {
      final ref = _ref(eventId);
      if (ref == null) return 'No user logged in.';

      await ref.delete();

      return null;
    } catch (_) {
      return 'Could not remove this event.';
    }
  }
}
