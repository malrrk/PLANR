import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/account_provider.dart';

/// Two confirmations; only the second one starts the deletion. A password is asked only when the login is too old.
Future<void> showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
  final service = ref.read(accountServiceProvider);

  final proceed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.deleteAccountTitle),
      content: Text(dialogContext.l10n.deleteAccountBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(dialogContext.l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(dialogContext.l10n.continueAction),
        ),
      ],
    ),
  );

  if (proceed != true || !context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FinalDeleteDialog(service: service),
  );
}

class _FinalDeleteDialog extends StatefulWidget {
  const _FinalDeleteDialog({required this.service});

  final AccountService service;

  @override
  State<_FinalDeleteDialog> createState() => _FinalDeleteDialogState();
}

class _FinalDeleteDialogState extends State<_FinalDeleteDialog> {
  final _password = TextEditingController();
  bool _deleting = false;
  bool _needsPassword = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_deleting) return;

    if (_needsPassword && _password.text.trim().isEmpty) {
      setState(() => _error = context.l10n.enterPassword);
      return;
    }

    setState(() {
      _deleting = true;
      _error = null;
    });

    final result = await widget.service.deleteAccount(
      password: _needsPassword ? _password.text : null,
    );

    if (!mounted) return;

    if (result == null) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _deleting = false;
      if (result == AccountService.reauthRequired) {
        _needsPassword = true;
      } else {
        _error = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: !_deleting,
      child: AlertDialog(
        title: Text(l10n.deleteAccountFinalTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAccountFinalBody),
            if (_needsPassword) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                enabled: !_deleting,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.confirmWithPassword,
                  errorText: _error,
                ),
              ),
            ] else if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ],
            if (_deleting) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _deleting ? null : () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: _deleting ? null : _delete,
            child: Text(l10n.deletePermanently),
          ),
        ],
      ),
    );
  }
}
