import 'package:flutter/material.dart';

import 'core/theme/planr_design.dart';
import 'screens/auth_gate.dart';

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
      selectionColor: PlanrDesign.accentSoft.withOpacity(0.8),
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