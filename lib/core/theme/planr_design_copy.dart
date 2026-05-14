import 'package:flutter/material.dart';

class PlanrDesign {
  const PlanrDesign._();

  // Palette:
  // Night:       #03071E
  // Dark Wine:   #370617
  // Wine:        #6A040F
  // Red:         #9D0208
  // Strong Red:  #D00000
  // Hot Orange:  #DC2F02
  // Orange:      #E85D04
  // Amber:       #F48C06
  // Gold:        #FAA307
  // Yellow:      #FFBA08
  //
  // Direction:
  // dark, fiery, nightlife-oriented.
  // The background stays very dark and clean; red/orange/yellow carry the energy.

  static const Color backgroundTop = Color(0xFF03071E);
  static const Color backgroundMiddle = Color(0xFF210512);
  static const Color backgroundBottom = Color(0xFF370617);
  static const Color backgroundButton = Color(0xFF4A0713);

  static const Color ink = Color(0xFFFFF4E8);
  static const Color muted = Color(0xFFC8AAA0);
  static const Color softMuted = Color(0xFFA9867C);

  static const Color card = Color(0xFF2B0715);
  static const Color cardLight = Color(0xFF3B0A18);
  static const Color cream = Color(0xFFFFEED8);

  static const Color accent = Color(0xFFE85D04);
  static const Color accentDark = Color(0xFFD00000);
  static const Color accentSoft = Color(0xFF5A1B13);
  static const Color eventMetaOrange = Color(0xFFFFBA08);

  static const Color storyRingStart = Color(0xFFD00000);
  static const Color storyRingEnd = Color(0xFFFFBA08);

  static const double pagePadding = 18;
  static const double cardRadius = 28;

  // Background system
  static const Color backgroundBase = backgroundTop;

  static const LinearGradient homeBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF03071E),
      Color(0xFF210512),
      Color(0xFF370617),
    ],
    stops: [0.0, 0.52, 1.0],
  );

  // Neutralized texture layers.
  // Keeps existing background widgets compatible without adding rectangular patches.
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
      Color(0xFF03071E),
      Color(0xFF370617),
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
      Color(0xFFD00000),
      Color(0xFFDC2F02),
      Color(0xFFE85D04),
      Color(0xFFF48C06),
      Color(0xFFFFBA08),
    ],
    stops: [0.0, 0.25, 0.50, 0.75, 1.0],
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
      Color(0xFF03071E),
      Color(0xFF210512),
      Color(0xFF370617),
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
        color: Colors.black.withOpacity(0.38),
        blurRadius: 28,
        offset: const Offset(0, 14),
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(0.46),
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
        color: const Color(0xFFFFBA08).withOpacity(0.10),
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
        Colors.black.withOpacity(0.38),
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