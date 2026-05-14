import 'package:flutter/material.dart';

class PlanrDesign {
  const PlanrDesign._();

  // Background from the orange palette, toned down.
  // Rest of the system uses the original PLANR design colors.

  static const Color backgroundTop = Color(0xFFFFFCF6);
  static const Color backgroundMiddle = Color(0xFFFFF0DC);
  static const Color backgroundBottom = Color(0xFFFFE4BE);
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

  static const Color backgroundBase = backgroundTop;

  static const LinearGradient homeBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFCF6),
      Color(0xFFFFF0DC),
      Color(0xFFFFE4BE),
    ],
    stops: [0.0, 0.58, 1.0],
  );

  static const RadialGradient homeLeftTextureGradient = RadialGradient(
    center: Alignment(-1.15, -0.35),
    radius: 1.85,
    colors: [
      Color(0x18FFB627),
      Color(0x0AFFB627),
      Color(0x02FFB627),
      Color(0x00FFB627),
    ],
    stops: [0.0, 0.34, 0.68, 1.0],
  );

  static const RadialGradient homeRightTextureGradient = RadialGradient(
    center: Alignment(1.28, -0.22),
    radius: 2.00,
    colors: [
      Color(0x12FF9505),
      Color(0x08FF9505),
      Color(0x02FF9505),
      Color(0x00FF9505),
    ],
    stops: [0.0, 0.34, 0.70, 1.0],
  );

  static const RadialGradient homeBottomWarmGradient = RadialGradient(
    center: Alignment(0.15, 1.42),
    radius: 2.00,
    colors: [
      Color(0x14CC5803),
      Color(0x08CC5803),
      Color(0x02CC5803),
      Color(0x00CC5803),
    ],
    stops: [0.0, 0.36, 0.72, 1.0],
  );

  static const LinearGradient profileBackgroundGradient =
      homeBackgroundGradient;

  static const RadialGradient profileLeftTextureGradient =
      homeLeftTextureGradient;

  static const RadialGradient profileRightTextureGradient =
      homeRightTextureGradient;

  static const RadialGradient profileBottomWarmGradient =
      homeBottomWarmGradient;

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
    stops: [0.0, 0.58, 1.0],
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
      Color(0xFFFFFCF6),
      Color(0xFFFFEBD0),
      Color(0xFFFFDDAE),
    ],
    stops: [0.0, 0.58, 1.0],
  );

  static const RadialGradient eventsLeftTextureGradient = RadialGradient(
    center: Alignment(-1.15, -0.35),
    radius: 1.85,
    colors: [
      Color(0x14FFB627),
      Color(0x08FFB627),
      Color(0x02FFB627),
      Color(0x00FFB627),
    ],
    stops: [0.0, 0.34, 0.68, 1.0],
  );

  static const RadialGradient eventsRightTextureGradient = RadialGradient(
    center: Alignment(1.25, 0.00),
    radius: 1.95,
    colors: [
      Color(0x10CC5803),
      Color(0x07CC5803),
      Color(0x02CC5803),
      Color(0x00CC5803),
    ],
    stops: [0.0, 0.36, 0.72, 1.0],
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