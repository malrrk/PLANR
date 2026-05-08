import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friends_provider.dart';


class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingFriendRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Text('No requests right now'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];

              return Card(
                child: ListTile(
                  title: Text(request['fromDisplayName'] as String? ?? 'User'),
                  subtitle: const Text('sent you a friend request'),
                  trailing: FilledButton(
                    onPressed: () async {
                      final error = await ref.read(friendsServiceProvider).acceptFriendRequest(
                            requestId: request['docId'] as String,
                            request: request,
                          );

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error ?? 'Friend request accepted'),
                        ),
                      );
                    },
                    child: const Text('Accept'),
                  ),
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