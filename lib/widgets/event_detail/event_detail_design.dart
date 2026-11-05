import 'package:flutter/material.dart';

class EventDetailDesign {
  const EventDetailDesign._();

  static const Color backgroundTop = Color(0xFFF3F0FF);
  static const Color backgroundBottom = Color(0xFFF8FAFC);
  static const Color card = Colors.white;
  static const Color primary = Color(0xFF6D5DF6);
  static const Color secondary = Color(0xFF5B8DEF);
  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color softBorder = Color(0xFFE8EAF3);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      primary,
      secondary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      backgroundTop,
      backgroundBottom,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxShadow get softShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 12),
      );

  static BoxDecoration cardDecoration({
    double radius = 30,
  }) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: softBorder),
      boxShadow: [softShadow],
    );
  }
}