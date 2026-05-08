import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../providers/friends_provider.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  Future<void> _confirmRemoveFriend(
    BuildContext context,
    WidgetRef ref,
    UserProfile friend,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Remove friend'),
              content: Text(
                'Do you want to remove ${friend.displayName} from your friends?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !context.mounted) return;

    final error = await ref.read(friendsServiceProvider).removeFriend(
          friendUid: friend.uid,
        );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '${friend.displayName} removed'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(myFriendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: friendsAsync.when(
        data: (friends) {
          if (friends.isEmpty) {
            return const Center(
              child: Text('No friends yet'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final friend = friends[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${friend.username}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _confirmRemoveFriend(context, ref, friend);
                      },
                      icon: const Icon(Icons.person_remove_outlined),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}