import 'package:flutter/material.dart';

class PlanrDesign {
  const PlanrDesign._();

  // Palette:
  // Purple:     #6610F2
  // Soft Pink:  #F7B2B7
  // Coral:      #F7717D
  // Magenta:    #DE639A
  // Deep Night: #16001E

  static const Color backgroundTop = Color(0xFF16001E);
  static const Color backgroundMiddle = Color(0xFF1C0526);
  static const Color backgroundBottom = Color(0xFF09000D);
  static const Color backgroundButton = Color(0xFF32103F);

  static const Color ink = Color(0xFFFFF6F8);
  static const Color muted = Color(0xFFC7AFCF);
  static const Color softMuted = Color(0xFFA98AAF);

  static const Color card = Color(0xFF25102F);
  static const Color cardLight = Color(0xFF321540);
  static const Color cream = Color(0xFFFFE9EF);

  static const Color accent = Color(0xFFF7717D);
  static const Color accentDark = Color(0xFFDE639A);
  static const Color accentSoft = Color(0xFF451739);
  static const Color eventMetaOrange = Color(0xFFF7B2B7);

  static const Color storyRingStart = Color(0xFF6610F2);
  static const Color storyRingEnd = Color(0xFFF7717D);

  static const double pagePadding = 18;
  static const double cardRadius = 28;

  // Background system
  static const Color backgroundBase = backgroundTop;

  static const LinearGradient homeBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF16001E),
      Color(0xFF1C0526),
      Color(0xFF09000D),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  // Intentionally neutralized.
  // The previous radial texture layers caused muddy rectangular patches on dark backgrounds.
  static const RadialGradient homeLeftTextureGradient = RadialGradient(
    center: Alignment(-0.8, -0.4),
    radius: 2.0,
    colors: [
      Color(0x00000000),
      Color(0x00000000),
    ],
  );

  static const RadialGradient homeRightTextureGradient = RadialGradient(
    center: Alignment(0.9, -0.2),
    radius: 2.0,
    colors: [
      Color(0x00000000),
      Color(0x00000000),
    ],
  );

  static const RadialGradient homeBottomWarmGradient = RadialGradient(
    center: Alignment(0.0, 1.2),
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
      Color(0xFF16001E),
      Color(0xFF09000D),
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF16001E),
      Color(0xFF1C0526),
      Color(0xFF09000D),
    ],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      Color(0xFF6610F2),
      Color(0xFFDE639A),
      Color(0xFFF7717D),
      Color(0xFFF7B2B7),
    ],
    stops: [0.0, 0.42, 0.72, 1.0],
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
      Color(0xFF16001E),
      Color(0xFF1C0526),
      Color(0xFF09000D),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const RadialGradient eventsLeftTextureGradient = RadialGradient(
    center: Alignment(-0.8, -0.4),
    radius: 2.0,
    colors: [
      Color(0x00000000),
      Color(0x00000000),
    ],
  );

  static const RadialGradient eventsRightTextureGradient = RadialGradient(
    center: Alignment(0.9, -0.2),
    radius: 2.0,
    colors: [
      Color(0x00000000),
      Color(0x00000000),
    ],
  );

  static BoxShadow get softShadow => BoxShadow(
        color: Colors.black.withOpacity(0.34),
        blurRadius: 28,
        offset: const Offset(0, 14),
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(0.42),
        blurRadius: 34,
        offset: const Offset(0, 16),
      );

  static BoxDecoration softCardDecoration({
    double radius = cardRadius,
  }) {
    return BoxDecoration(
      color: card.withOpacity(0.92),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withOpacity(0.09),
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
        Colors.black.withOpacity(0.02),
        Colors.black.withOpacity(0.38),
        Colors.black.withOpacity(0.94),
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