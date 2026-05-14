import 'package:flutter/material.dart';

class PlanrDesign {
  const PlanrDesign._();

  // Palette:
  // Deep Plum:    #210B2C
  // Royal Plum:   #55286F
  // Lavender:     #BC96E6
  // Soft Lilac:   #D8B4E2
  // Mauve:        #AE759F

  static const Color backgroundTop = Color(0xFFFFFBFF);
  static const Color backgroundMiddle = Color(0xFFF6EEFB);
  static const Color backgroundBottom = Color(0xFFEADCF3);
  static const Color backgroundButton = Color(0xFFEAD5F3);

  static const Color ink = Color(0xFF210B2C);
  static const Color muted = Color(0xFF6F5A78);
  static const Color softMuted = Color(0xFF907A98);

  static const Color card = Color(0xFFF8EEFC);
  static const Color cardLight = Color(0xFFFFFBFF);
  static const Color cream = Color(0xFFFEF7FF);

  static const Color accent = Color(0xFF55286F);
  static const Color accentDark = Color(0xFF210B2C);
  static const Color accentSoft = Color(0xFFE3CCF1);
  static const Color eventMetaOrange = Color(0xFFAE759F);

  static const Color storyRingStart = Color(0xFF55286F);
  static const Color storyRingEnd = Color(0xFFBC96E6);

  static const double pagePadding = 18;
  static const double cardRadius = 28;

  // Background system
  static const Color backgroundBase = backgroundTop;

  static const LinearGradient homeBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFBFF),
      Color(0xFFF6EEFB),
      Color(0xFFEADCF3),
    ],
    stops: [0.0, 0.52, 1.0],
  );

  // Neutralized texture layers.
  // Keep these defined so existing screens do not break,
  // but they are invisible to prevent ugly rectangular/patchy backgrounds.
  static const RadialGradient homeLeftTextureGradient = RadialGradient(
    center: Alignment(-0.75, -0.35),
    radius: 2.0,
    colors: [
      Color(0x00000000),
      Color(0x00000000),
    ],
  );

  static const RadialGradient homeRightTextureGradient = RadialGradient(
    center: Alignment(1.0, -0.15),
    radius: 2.0,
    colors: [
      Color(0x00000000),
      Color(0x00000000),
    ],
  );

  static const RadialGradient homeBottomWarmGradient = RadialGradient(
    center: Alignment(0.05, 1.3),
    radius: 2.0,
    colors: [
      Color(0x00000000),
      Color(0x00000000),
    ],
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
      Color(0xFFF6EEFB),
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      backgroundTop,
      backgroundMiddle,
      backgroundBottom,
    ],
    stops: [0.0, 0.52, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      Color(0xFF210B2C),
      Color(0xFF55286F),
      Color(0xFFBC96E6),
      Color(0xFFD8B4E2),
    ],
    stops: [0.0, 0.34, 0.68, 1.0],
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
      Color(0xFFFFFBFF),
      Color(0xFFF4EAFA),
      Color(0xFFE6D5F0),
    ],
    stops: [0.0, 0.52, 1.0],
  );

  static const RadialGradient eventsLeftTextureGradient = RadialGradient(
    center: Alignment(-0.75, -0.35),
    radius: 2.0,
    colors: [
      Color(0x00000000),
      Color(0x00000000),
    ],
  );

  static const RadialGradient eventsRightTextureGradient = RadialGradient(
    center: Alignment(1.0, 0.0),
    radius: 2.0,
    colors: [
      Color(0x00000000),
      Color(0x00000000),
    ],
  );

  static BoxShadow get softShadow => BoxShadow(
        color: const Color(0xFF210B2C).withOpacity(0.075),
        blurRadius: 24,
        offset: const Offset(0, 10),
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: const Color(0xFF210B2C).withOpacity(0.11),
        blurRadius: 30,
        offset: const Offset(0, 13),
      );

  static BoxDecoration softCardDecoration({
    double radius = cardRadius,
  }) {
    return BoxDecoration(
      color: card.withOpacity(0.84),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withOpacity(0.95),
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
        Colors.black.withOpacity(0.03),
        Colors.black.withOpacity(0.22),
        Colors.black.withOpacity(0.86),
      ],
      stops: const [0.0, 0.48, 1.0],
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