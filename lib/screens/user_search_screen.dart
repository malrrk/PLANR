import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../providers/friends_provider.dart';
import '../providers/user_profile_provider.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _controller = TextEditingController();
  List<UserProfile> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
    });

    final users =
        await ref.read(userProfileServiceProvider).searchUsers(_controller.text);

    if (!mounted) return;

    setState(() {
      _results = users;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(currentFirebaseUserProvider);
    final currentUser = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find friends'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Search username',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _search,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    if (user.uid == currentUser?.uid) {
                      return const SizedBox.shrink();
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.displayName.characters.first.toUpperCase(),
                              )
                            : null,
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      trailing: FilledButton(
                        onPressed: () async {
                          final error = await ref
                              .read(friendsServiceProvider)
                              .sendFriendRequest(toUser: user);

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error ?? 'Friend request sent'),
                            ),
                          );
                        },
                        child: const Text('Add'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}