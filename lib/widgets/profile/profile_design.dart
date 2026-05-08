import 'package:flutter/material.dart';

class ProfileDesign {
  const ProfileDesign._();

  static const Color backgroundTop = Color(0xFFFFF7ED);
  static const Color backgroundMiddle = Color(0xFFF4F0FF);
  static const Color backgroundBottom = Color(0xFFF8FAFC);

  static const Color card = Colors.white;
  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color softBorder = Color(0xFFE8EAF3);

  static const Color primary = Color(0xFF7C5CFF);
  static const Color secondary = Color(0xFFFF8A65);
  static const Color rose = Color(0xFFFF6B9A);
  static const Color amber = Color(0xFFFFB86B);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      backgroundTop,
      backgroundMiddle,
      backgroundBottom,
    ],
    stops: [0.0, 0.42, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [
      Color(0xFFFF8A65),
      Color(0xFFFF6B9A),
      Color(0xFF7C5CFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calmGradient = LinearGradient(
    colors: [
      Color(0xFF7C5CFF),
      Color(0xFF5B8DEF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxShadow get softShadow => BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 28,
        offset: const Offset(0, 14),
      );

  static BoxShadow get glowShadow => BoxShadow(
        color: primary.withOpacity(0.18),
        blurRadius: 30,
        offset: const Offset(0, 14),
      );

  static BoxDecoration cardDecoration({
    double radius = 30,
  }) {
    return BoxDecoration(
      color: card.withOpacity(0.92),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.82)),
      boxShadow: [softShadow],
    );
  }
}