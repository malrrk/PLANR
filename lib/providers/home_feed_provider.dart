import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import 'event_provider.dart';
import 'firebase_providers.dart';
import 'friends_provider.dart';
import 'moderation_provider.dart';
import 'public_page_provider.dart';
import 'saved_events_provider.dart';

class GoingFriend {
  const GoingFriend({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
}

/// Friends who are attending an event, so cards can show social proof.
final friendsGoingProvider =
    FutureProvider.family<List<GoingFriend>, String>((ref, eventId) async {
  final friends = await ref.watch(myFriendsProvider.future);
  final blocked = ref.watch(blockedUidsProvider).value ?? const <String>{};
  final friendIds =
      friends.map((friend) => friend.uid).where((uid) => !blocked.contains(uid));

  if (friendIds.isEmpty) return const [];

  final firestore = ref.watch(firestoreProvider);
  final ids = friendIds.toList();
  final going = <GoingFriend>[];

  try {
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snapshot = await firestore
          .collection('events')
          .doc(eventId)
          .collection('attendees')
          .where('uid', whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        going.add(
          GoingFriend(
            uid: data['uid'] as String? ?? doc.id,
            displayName: data['displayName'] as String? ?? 'Friend',
            photoUrl: data['photoUrl'] as String?,
          ),
        );
      }
    }
  } on FirebaseException {
    return const [];
  }

  return going;
});

enum PeopleFeedReason { friendsGoing, followedPage }

class PeopleFeedItem {
  const PeopleFeedItem({
    required this.event,
    required this.reason,
    required this.friends,
  });

  final Event event;
  final PeopleFeedReason reason;
  final List<GoingFriend> friends;
}

/// Upcoming public events that matter because friends go or a followed page hosts them.
final aroundYourPeopleProvider =
    FutureProvider<List<PeopleFeedItem>>((ref) async {
  final events = await ref.watch(eventsProvider.future);
  final followedPages = await ref.watch(followedPagesProvider.future);
  final mine = ref.watch(myEventsProvider).value ?? const <Event>[];
  final saved = ref.watch(savedEventsProvider).value ?? const <Event>[];

  final hiddenIds = {
    ...mine.map((event) => event.id),
    ...saved.map((event) => event.id),
    ...mine.map((event) => event.linkedPublicEventId).whereType<String>(),
  };
  final followedPageIds = followedPages.map((page) => page.id).toSet();
  final now = DateTime.now();

  final candidates = events
      .where((event) => event.date.isAfter(now))
      .where((event) => !hiddenIds.contains(event.id))
      .take(25)
      .toList();

  final friendsPerEvent = await Future.wait(
    candidates.map((event) => ref.watch(friendsGoingProvider(event.id).future)),
  );

  final items = <PeopleFeedItem>[];
  for (var i = 0; i < candidates.length; i++) {
    final event = candidates[i];
    final friends = friendsPerEvent[i];

    if (friends.isNotEmpty) {
      items.add(
        PeopleFeedItem(
          event: event,
          reason: PeopleFeedReason.friendsGoing,
          friends: friends,
        ),
      );
    } else if (event.isOrganizedByPage &&
        followedPageIds.contains(event.organizerId)) {
      items.add(
        PeopleFeedItem(
          event: event,
          reason: PeopleFeedReason.followedPage,
          friends: const [],
        ),
      );
    }
  }

  items.sort((a, b) {
    final byFriends = b.friends.length.compareTo(a.friends.length);
    if (byFriends != 0) return byFriends;
    return a.event.date.compareTo(b.event.date);
  });

  return items.take(8).toList();
});
