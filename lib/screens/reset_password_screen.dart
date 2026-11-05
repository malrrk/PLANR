import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_scaffold.dart';
import '../core/widgets/planr_text_field.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });

    String? error;
    try {
      error = await ref.read(authProvider).resetPassword(
            email: _emailController.text,
          );
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }

    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = error == null;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlanrScaffold(
      title: 'Reset password',
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_sent)
                  const Text(
                    'If an account exists for this email, a reset link has been sent.',
                  )
                else ...[
                  PlanrTextField(
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PlanrButton(
                    label: 'Send reset link',
                    icon: Icons.send_rounded,
                    isLoading: _sending,
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}