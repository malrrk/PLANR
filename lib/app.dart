import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/planr_design.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_gate.dart';

/// Owns the Riverpod container and recreates it whenever the signed-in user changes,
/// so cached streams and state from one account never reach the next one.
class PlanrRoot extends StatefulWidget {
  const PlanrRoot({
    super.key,
    this.userIds,
    this.child = const PlannerApp(),
  });

  /// Signed-in uid changes (null when signed out). Defaults to Firebase Auth.
  final Stream<String?>? userIds;
  final Widget child;

  @override
  State<PlanrRoot> createState() => _PlanrRootState();
}

class _PlanrRootState extends State<PlanrRoot> {
  StreamSubscription<String?>? _subscription;
  bool _resolved = false;
  String? _uid;
  bool _hasPending = false;
  String? _pendingUid;

  @override
  void initState() {
    super.initState();
    signUpInProgress.addListener(_applyPending);
    _subscription = (widget.userIds ??
            FirebaseAuth.instance.authStateChanges().map((user) => user?.uid))
        .listen(_onUser);
  }

  @override
  void dispose() {
    signUpInProgress.removeListener(_applyPending);
    _subscription?.cancel();
    super.dispose();
  }

  void _onUser(String? uid) {
    // Sign-up writes the profile right after the account exists; hold the switch until it is done.
    if (_resolved && signUpInProgress.value) {
      _hasPending = true;
      _pendingUid = uid;
      return;
    }
    _apply(uid);
  }

  void _applyPending() {
    if (signUpInProgress.value || !_hasPending) return;
    _hasPending = false;
    _apply(_pendingUid);
  }

  void _apply(String? uid) {
    if (_resolved && uid == _uid) return;
    setState(() {
      _resolved = true;
      _uid = uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: PlanrDesign.backgroundBase,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ProviderScope(
      key: ValueKey(_uid ?? 'signed-out'),
      child: widget.child,
    );
  }
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planr',
      debugShowCheckedModeBanner: false,
      theme: _buildPlanrTheme(),
      home: const AuthGate(),
    );
  }
}

ThemeData _buildPlanrTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: PlanrDesign.backgroundBase,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PlanrDesign.accent,
      brightness: Brightness.light,
      primary: PlanrDesign.accent,
      secondary: PlanrDesign.eventMetaOrange,
      surface: PlanrDesign.cardLight,
      error: const Color(0xFFD32F2F),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: PlanrDesign.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(
        color: PlanrDesign.ink,
      ),
      titleTextStyle: TextStyle(
        color: PlanrDesign.ink,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: PlanrDesign.accent,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: PlanrDesign.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: CircleBorder(),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: PlanrDesign.accent,
      selectionColor: PlanrDesign.accentSoft.withValues(alpha: 0.8),
      selectionHandleColor: PlanrDesign.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: PlanrDesign.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}