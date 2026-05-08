import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Timer? _usernameDebounce;

  bool _isLogin = true;
  bool _loading = false;
  bool _checkingUsername = false;
  bool? _usernameAvailable;

  String? _errorText;
  String? _usernameText;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    if (_isLogin) return;

    _usernameDebounce?.cancel();

    final auth = ref.read(authProvider);
    final normalized = auth.normalizeUsername(_usernameController.text);
    final validationError = auth.validateUsername(normalized);

    setState(() {
      _usernameAvailable = null;
      _usernameText = validationError;
      _checkingUsername = false;
    });

    if (validationError != null) return;

    _usernameDebounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;

      setState(() {
        _checkingUsername = true;
      });

      final available = await auth.isUsernameAvailable(normalized);

      if (!mounted) return;

      setState(() {
        _checkingUsername = false;
        _usernameAvailable = available;
        _usernameText = available
            ? 'Username is available.'
            : 'Username is already taken.';
      });
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final auth = ref.read(authProvider);
      String? error;

      if (_isLogin) {
        error = await auth.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        final normalizedUsername =
            auth.normalizeUsername(_usernameController.text);
        final usernameError = auth.validateUsername(normalizedUsername);

        if (usernameError != null) {
          if (!mounted) return;

          setState(() {
            _loading = false;
            _usernameText = usernameError;
            _usernameAvailable = false;
          });
          return;
        }

        final usernameAvailable =
            await auth.isUsernameAvailable(normalizedUsername);

        if (!usernameAvailable) {
          if (!mounted) return;

          setState(() {
            _loading = false;
            _usernameText = 'Username is already taken.';
            _usernameAvailable = false;
          });
          return;
        }

        error = await auth.signUp(
          name: _nameController.text,
          username: normalizedUsername,
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorText = error;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorText = 'Something went wrong. Please try again.';
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorText = null;
      _usernameText = null;
      _usernameAvailable = null;
      _checkingUsername = false;
    });

    _usernameDebounce?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Welcome back' : 'Create account';
    final subtitle = _isLogin
        ? 'Log in to continue to Planr'
        : 'Sign up to start planning with friends';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Planr',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 28),
                  if (!_isLogin) ...[
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'alec_123',
                        prefixText: '@',
                        border: const OutlineInputBorder(),
                        helperText: _usernameText,
                        helperStyle: TextStyle(
                          color: _usernameAvailable == null
                              ? Colors.grey.shade700
                              : _usernameAvailable!
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                        suffixIcon: _checkingUsername
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : _usernameAvailable == null
                                ? null
                                : Icon(
                                    _usernameAvailable!
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: _usernameAvailable!
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_loading) _submit();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isLogin ? 'Log In' : 'Sign Up'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading ? null : _toggleMode,
                    child: Text(
                      _isLogin
                          ? 'No account yet? Sign up'
                          : 'Already have an account? Log in',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}