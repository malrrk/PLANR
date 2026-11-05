import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/moderation_provider.dart';

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Asks for a reason and sends a report. Content is reviewed by the team; the reporter is never revealed.
Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required ReportTarget target,
  required String targetId,
  required String title,
}) async {
  final service = ref.read(moderationServiceProvider);
  final detailsController = TextEditingController();
  var reason = reportReasons.first;
  var sending = false;

  final sent = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioGroup<String>(
                    groupValue: reason,
                    onChanged: (value) {
                      if (sending || value == null) return;
                      setState(() => reason = value);
                    },
                    child: Column(
                      children: [
                        for (final option in reportReasons)
                          RadioListTile<String>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(option),
                            value: option,
                          ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: detailsController,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Details (optional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        setState(() => sending = true);
                        final error = await service.report(
                          target: target,
                          targetId: targetId,
                          reason: reason,
                          details: detailsController.text,
                        );
                        if (!dialogContext.mounted) return;
                        if (error != null) {
                          setState(() => sending = false);
                          _showMessage(dialogContext, error);
                          return;
                        }
                        Navigator.pop(dialogContext, true);
                      },
                child: Text(sending ? 'Sending...' : 'Report'),
              ),
            ],
          );
        },
      );
    },
  );

  detailsController.dispose();

  if (sent == true && context.mounted) {
    _showMessage(context, 'Thanks. Your report has been sent for review.');
  }
}

/// Confirms, then blocks. Returns true when the user was blocked.
Future<bool> confirmAndBlockUser(
  BuildContext context,
  WidgetRef ref, {
  required String uid,
  required String name,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Block $name?'),
      content: const Text(
        'They will no longer be able to send you friend requests or invites, '
        'and their content is hidden from you. Any friendship ends.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Block'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;

  final error = await ref.read(moderationServiceProvider).blockUser(uid);

  if (!context.mounted) return false;

  _showMessage(context, error ?? '$name is blocked.');
  return error == null;
}
