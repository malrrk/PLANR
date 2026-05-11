import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/planr_design.dart';
import '../core/widgets/planr_background.dart';
import '../core/widgets/planr_button.dart';
import '../core/widgets/planr_card.dart';
import '../core/widgets/planr_text_field.dart';
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
  bool _passwordVisible = false;
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

    if (_loading) return;

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
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorText = 'Something went wrong. Please try again.';
      });
    }
  }

  void _toggleMode() {
    _usernameDebounce?.cancel();

    setState(() {
      _isLogin = !_isLogin;
      _errorText = null;
      _usernameText = null;
      _usernameAvailable = null;
      _checkingUsername = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Welcome back' : 'Create account';
    final subtitle = _isLogin
        ? 'Log in with your username.'
        : 'Create your PLANR account.';

    return PlanrBackground(
      variant: PlanrBackgroundVariant.auth,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 24),
                    PlanrCard(
                      padding: const EdgeInsets.all(20),
                      radius: 34,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 22),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: PlanrDesign.ink,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              height: 1.04,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: PlanrDesign.muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 24),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: _isLogin
                                ? const SizedBox.shrink()
                                : Column(
                                    key: const ValueKey('signup-fields'),
                                    children: [
                                      PlanrTextField(
                                        controller: _nameController,
                                        label: 'Name',
                                        hintText: 'Your display name',
                                        textInputAction: TextInputAction.next,
                                        prefixIcon:
                                            Icons.badge_outlined,
                                      ),
                                      const SizedBox(height: 16),
                                      _UsernameField(
                                        controller: _usernameController,
                                        checking: _checkingUsername,
                                        available: _usernameAvailable,
                                        helperText: _usernameText,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                          ),

                          PlanrTextField(
                            controller: _emailController,
                            label: _isLogin ? 'Username' : 'Email',
                            hintText: _isLogin ? 'your_username' : 'you@example.com',
                            keyboardType:
                                _isLogin ? TextInputType.text : TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: _isLogin
                                ? Icons.alternate_email_rounded
                                : Icons.mail_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          PlanrTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: 'Your password',
                            obscureText: !_passwordVisible,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: PlanrDesign.softMuted,
                                size: 20,
                              ),
                            ),
                          ),

                          if (_errorText != null) ...[
                            const SizedBox(height: 14),
                            _AuthErrorBox(message: _errorText!),
                          ],

                          const SizedBox(height: 22),
                          PlanrButton(
                            label: _isLogin ? 'Log In' : 'Sign Up',
                            icon: _isLogin
                                ? Icons.login_rounded
                                : Icons.person_add_alt_1_rounded,
                            isLoading: _loading,
                            onPressed: _loading ? null : _submit,
                          ),
                          const SizedBox(height: 14),
                          _FooterToggle(
                            isLogin: _isLogin,
                            disabled: _loading,
                            onTap: _toggleMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'PLANR',
          textAlign: TextAlign.center,
          style: PlanrDesign.brandTitleStyle,
        ),
        SizedBox(height: 8),
        Text(
          'SOCIAL PLANS. REAL CONNECTIONS.',
          textAlign: TextAlign.center,
          style: PlanrDesign.brandSubtitleStyle,
        ),
      ],
    );
  }
}

class _UsernameField extends StatelessWidget {
  const _UsernameField({
    required this.controller,
    required this.checking,
    required this.available,
    required this.helperText,
  });

  final TextEditingController controller;
  final bool checking;
  final bool? available;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final helperColor = available == null
        ? PlanrDesign.muted
        : available!
            ? const Color(0xFF2E7D32)
            : const Color(0xFFD32F2F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Username',
          style: TextStyle(
            color: PlanrDesign.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          cursorColor: PlanrDesign.accent,
          style: const TextStyle(
            color: PlanrDesign.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: 'alec_123',
            hintStyle: const TextStyle(
              color: PlanrDesign.softMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: const Icon(
              Icons.alternate_email_rounded,
              color: PlanrDesign.softMuted,
              size: 20,
            ),
            suffixIcon: checking
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : available == null
                    ? null
                    : Icon(
                        available!
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: helperColor,
                        size: 21,
                      ),
            filled: true,
            fillColor: PlanrDesign.cardLight.withOpacity(0.82),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: _border(Colors.white.withOpacity(0.95)),
            enabledBorder: _border(Colors.white.withOpacity(0.95)),
            focusedBorder: _border(PlanrDesign.accent, width: 1.4),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: helperText == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(helperText),
                  padding: const EdgeInsets.only(top: 7, left: 2),
                  child: Text(
                    helperText!,
                    style: TextStyle(
                      color: helperColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}

class _AuthErrorBox extends StatelessWidget {
  const _AuthErrorBox({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD32F2F).withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD32F2F),
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterToggle extends StatelessWidget {
  const _FooterToggle({
    required this.isLogin,
    required this.disabled,
    required this.onTap,
  });

  final bool isLogin;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = isLogin
        ? 'No account yet? Sign up'
        : 'Already have an account? Log in';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: disabled
                  ? PlanrDesign.softMuted
                  : PlanrDesign.accentDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}