import 'package:flutter/material.dart';

class HomeDesign {
  const HomeDesign._();

  static const Color backgroundTop = Color(0xFFFFFBF4);
  static const Color backgroundMiddle = Color(0xFFFFF4E8);
  static const Color backgroundBottom = Color(0xFFF9F1FF);
  static const Color backgroundButton = Color(0xFFFFF2E4);

  static const Color ink = Color(0xFF171717);
  static const Color muted = Color(0xFF7B7169);
  static const Color softMuted = Color(0xFF9A9088);

  static const Color card = Color(0xFFFFF5E8);
  static const Color cardLight = Color(0xFFFFFAF3);
  static const Color cream = Color(0xFFFFF7EC);

  static const Color accent = Color(0xFFD95B28);
  static const Color accentDark = Color(0xFFC54F24);
  static const Color accentSoft = Color(0xFFFFDFC3);
  static const Color eventMetaOrange = Color(0xFFF59E3D);

  static const Color storyRingStart = Color(0xFFE95F75);
  static const Color storyRingEnd = Color(0xFFFFB15E);

  static const double pagePadding = 18;
  static const double cardRadius = 28;

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      backgroundTop,
      backgroundMiddle,
      backgroundBottom,
    ],
    stops: [0, 0.58, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      Color(0xFFFF8A65),
      Color(0xFFFF6B9A),
      Color(0xFF7C5CFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient storyRingGradient = LinearGradient(
    colors: [
      storyRingStart,
      storyRingEnd,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxShadow get softShadow => BoxShadow(
        color: Colors.black.withOpacity(0.055),
        blurRadius: 24,
        offset: const Offset(0, 10),
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(0.075),
        blurRadius: 28,
        offset: const Offset(0, 12),
      );

  static BoxDecoration softCardDecoration({
    double radius = cardRadius,
  }) {
    return BoxDecoration(
      color: card.withOpacity(0.72),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withOpacity(0.9),
      ),
      boxShadow: [softShadow],
    );
  }

  static BoxDecoration cardDecoration({
    double radius = cardRadius,
  }) {
    return softCardDecoration(radius: radius);
  }

  static LinearGradient eventOverlayGradient() { 
    return LinearGradient(
      colors: [
        Colors.black.withOpacity(0.04), // changeable
        Colors.black.withOpacity(0.24), // changeable
        Colors.black.withOpacity(0.90), // changeable
      ],
      stops: const [0, 0.48, 1],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static TextStyle get brandTitleStyle => const TextStyle(
        color: accentDark,
        fontSize: 38,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.5,
      );

  static TextStyle get serifHeadingStyle => const TextStyle(
        color: ink,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.7,
      );

  static TextStyle get sectionTitleStyle => const TextStyle(
        color: ink,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.7,
      );
}