import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import '../models/user_profile.dart';
import '../providers/friends_provider.dart';
import '../providers/event_provider.dart';

class InviteToEventScreen extends ConsumerWidget {
  const InviteToEventScreen({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(myFriendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite friends'),
      ),
      body: friendsAsync.when(
        data: (friends) {
          if (friends.isEmpty) {
            return const Center(
              child: Text('No friends to invite yet'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final UserProfile friend = friends[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: friend.photoUrl != null
                      ? NetworkImage(friend.photoUrl!)
                      : null,
                  child: friend.photoUrl == null
                      ? Text(
                          friend.displayName.isNotEmpty
                              ? friend.displayName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                title: Text(friend.displayName),
                subtitle: Text('@${friend.username}'),
                trailing: FilledButton(
                  onPressed: () async {
                    final error =
                        await ref.read(eventServiceProvider).inviteUserToEvent(
                              event: event,
                              invitedUid: friend.uid,
                              invitedDisplayName: friend.displayName,
                              invitedPhotoUrl: friend.photoUrl,
                            );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Invite sent'),
                      ),
                    );
                  },
                  child: const Text('Invite'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}