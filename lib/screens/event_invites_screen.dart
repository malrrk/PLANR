import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/event_provider.dart';

import '../widgets/event_tag_chips.dart';

class EventInvitesScreen extends ConsumerWidget {
  const EventInvitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(myEventInvitesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Invites'),
      ),
      body: invitesAsync.when(
        data: (invites) {
          if (invites.isEmpty) {
            return const Center(
              child: Text('No event invites'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invites.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final invite = invites[index];
              final eventId = invite['eventId'] as String;
              final tagIds = List<String>.from(invite['eventTags'] as List? ?? const []);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite['eventTitle'] as String? ?? 'Event invite',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (tagIds.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        EventTagChips(
                          tagIds: tagIds,
                          maxVisible: 3,
                          compact: true,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Invited by ${invite['invitedByDisplayName'] ?? 'someone'}',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final error = await ref
                                    .read(eventServiceProvider)
                                    .declineEventInvite(eventId: eventId);

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error ?? 'Invite declined'),
                                  ),
                                );
                              },
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                final error = await ref
                                    .read(eventServiceProvider)
                                    .acceptEventInvite(eventId: eventId);

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error ?? 'Invite accepted'),
                                  ),
                                );
                              },
                              child: const Text('Accept'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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