import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/account_provider.dart';

/// Explains what is deleted, asks for the password and deletes the account.
Future<void> showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
  final service = ref.read(accountServiceProvider);
  final passwordController = TextEditingController();
  var deleting = false;
  String? error;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Delete account?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This permanently deletes your profile, your events, stories and '
                  'friendships. It cannot be undone.',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  enabled: !deleting,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm with your password',
                    errorText: error,
                  ),
                ),
                if (deleting) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                onPressed: deleting
                    ? null
                    : () async {
                        if (passwordController.text.trim().isEmpty) {
                          setState(() => error = 'Enter your password.');
                          return;
                        }
                        setState(() {
                          deleting = true;
                          error = null;
                        });
                        final result = await service.deleteAccount(
                          password: passwordController.text,
                        );
                        if (!dialogContext.mounted) return;
                        if (result != null) {
                          setState(() {
                            deleting = false;
                            error = result;
                          });
                          return;
                        }
                        Navigator.pop(dialogContext);
                      },
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
    },
  );

  passwordController.dispose();
}
