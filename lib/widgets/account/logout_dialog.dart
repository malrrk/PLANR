import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';

/// Signs out only after the user confirms; cancelling or dismissing keeps the session.
Future<void> confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.logOutConfirmTitle),
      content: Text(dialogContext.l10n.logOutConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(dialogContext.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(dialogContext.l10n.logOut),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  await ref.read(authProvider).logout();
}
