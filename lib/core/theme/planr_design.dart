import 'package:flutter/material.dart';

class PlanrDesign {
  const PlanrDesign._();

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

  // Background system
  static const Color backgroundBase = backgroundTop;

  static const LinearGradient homeBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      backgroundTop,
      backgroundMiddle,
      backgroundBottom,
    ],
    stops: [0.0, 0.58, 1.0],
  );

  static const RadialGradient homeLeftTextureGradient = RadialGradient(
    center: Alignment(-0.55, -0.20),
    radius: 1.05,
    colors: [
      Color(0x88FFF4E8), // warm middle tone, subtle left texture
      Color(0x00FFF4E8),
    ],
  );

  static const RadialGradient homeRightTextureGradient = RadialGradient(
    center: Alignment(0.80, 0.10),
    radius: 1.15,
    colors: [
      Color(0x6EF9F1FF), // original soft purple bottom, subtle right texture
      Color(0x00F9F1FF),
    ],
  );

  static const RadialGradient homeBottomWarmGradient = RadialGradient(
    center: Alignment(0.0, 1.15),
    radius: 1.05,
    colors: [
      Color(0xCCFFF4E8), // warmer glow from bottom
      Color(0x00FFF4E8),
    ],
  );

  static const LinearGradient plainBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFFFBF6),
    ],
  );

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

  static const LinearGradient eventsBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFBF4),
      Color(0xFFFFF3E6),
      Color(0xFFFFE3CC),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const RadialGradient eventsLeftTextureGradient = RadialGradient(
    center: Alignment(-0.45, -0.25),
    radius: 1.05,
    colors: [
      Color(0x24FFD0A0),
      Color(0x00FFD0A0),
    ],
  );

  static const RadialGradient eventsRightTextureGradient = RadialGradient(
    center: Alignment(0.75, 0.05),
    radius: 1.05,
    colors: [
      Color(0x14FFC7A3),
      Color(0x00FFC7A3),
    ],
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
        Colors.black.withOpacity(0.04),
        Colors.black.withOpacity(0.24),
        Colors.black.withOpacity(0.90),
      ],
      stops: const [0, 0.48, 1],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static const TextStyle brandTitleStyle = TextStyle(
    color: accentDark,
    fontSize: 38,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.5,
    height: 1,
  );

  static const TextStyle brandSubtitleStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.4,
    color: muted,
    height: 1,
  );

  static const TextStyle serifHeadingStyle = TextStyle(
    color: ink,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.7,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: ink,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.7,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    color: ink,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: ink,
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle mutedBodyStyle = TextStyle(
    color: muted,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle smallMutedStyle = TextStyle(
    color: softMuted,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle metaOrangeStyle = TextStyle(
    color: eventMetaOrange,
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w900,
  );
}