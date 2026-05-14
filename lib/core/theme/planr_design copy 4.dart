import 'package:flutter/material.dart';

class PlanrDesign {
  const PlanrDesign._();

  // Palette:
  // Almost Black Brown: #250902
  // Dark Burgundy:      #38040E
  // Wine Red:           #640D14
  // Deep Red:           #800E13
  // Soft Red:           #AD2831
  //
  // Direction:
  // dark red / burgundy nightlife palette.
  // Cleaner background, no visible radial texture layers.

  static const Color backgroundTop = Color(0xFF1A0504);
  static const Color backgroundMiddle = Color(0xFF250902);
  static const Color backgroundBottom = Color(0xFF38040E);
  static const Color backgroundButton = Color(0xFF4A0A10);

  static const Color ink = Color(0xFFFFF4EF);
  static const Color muted = Color(0xFFC9A9A3);
  static const Color softMuted = Color(0xFFA98680);

  static const Color card = Color(0xFF3A0A0D);
  static const Color cardLight = Color(0xFF4A0D12);
  static const Color cream = Color(0xFFFFEFE8);

  static const Color accent = Color(0xFFAD2831);
  static const Color accentDark = Color(0xFF800E13);
  static const Color accentSoft = Color(0xFF5A1417);
  static const Color eventMetaOrange = Color(0xFFFFB3A8);

  static const Color storyRingStart = Color(0xFFAD2831);
  static const Color storyRingEnd = Color(0xFF800E13);

  static const double pagePadding = 18;
  static const double cardRadius = 28;

  // Background system
  static const Color backgroundBase = backgroundTop;

  static const LinearGradient homeBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A0504),
      Color(0xFF250902),
      Color(0xFF38040E),
    ],
    stops: [0.0, 0.48, 1.0],
  );

  // Neutralized texture layers.
  // Keeps existing screen code compatible without adding patchy/rectangular background effects.
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
      Color(0xFF1A0504),
      Color(0xFF38040E),
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      backgroundTop,
      backgroundMiddle,
      backgroundBottom,
    ],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      Color(0xFFAD2831),
      Color(0xFF800E13),
      Color(0xFF640D14),
      Color(0xFF38040E),
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
      Color(0xFF1A0504),
      Color(0xFF250902),
      Color(0xFF38040E),
    ],
    stops: [0.0, 0.50, 1.0],
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
        color: Colors.black.withOpacity(0.36),
        blurRadius: 28,
        offset: const Offset(0, 14),
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(0.44),
        blurRadius: 34,
        offset: const Offset(0, 16),
      );

  static BoxDecoration softCardDecoration({
    double radius = cardRadius,
  }) {
    return BoxDecoration(
      color: card.withOpacity(0.90),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: const Color(0xFFFFEFE8).withOpacity(0.10),
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
        Colors.black.withOpacity(0.36),
        Colors.black.withOpacity(0.94),
      ],
      stops: const [0.0, 0.48, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static const TextStyle brandTitleStyle = TextStyle(
    color: accent,
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