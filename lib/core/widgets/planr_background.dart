import 'package:flutter/material.dart';

import '../theme/planr_design.dart';

enum PlanrBackgroundVariant {
  home,
  events,
  create,
  profile,
  friends,
  auth,
  plain,
}

class PlanrBackground extends StatelessWidget {
  const PlanrBackground({
    super.key,
    required this.child,
    this.variant = PlanrBackgroundVariant.home,
  });

  final Widget child;
  final PlanrBackgroundVariant variant;

  @override
  Widget build(BuildContext context) {
    final config = _configForVariant(variant);

    return Container(
      color: config.baseColor,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: config.baseGradient,
            ),
          ),

          if (config.leftGradient != null)
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: config.leftWidth,
                height: config.leftHeight,
                decoration: BoxDecoration(
                  gradient: config.leftGradient,
                ),
              ),
            ),

          if (config.rightGradient != null)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: config.rightWidth,
                height: config.rightHeight,
                decoration: BoxDecoration(
                  gradient: config.rightGradient,
                ),
              ),
            ),

          if (config.bottomGradient != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: config.bottomHeight,
                decoration: BoxDecoration(
                  gradient: config.bottomGradient,
                ),
              ),
            ),

          child,
        ],
      ),
    );
  }

  _PlanrBackgroundConfig _configForVariant(PlanrBackgroundVariant variant) {
    switch (variant) {
      case PlanrBackgroundVariant.home:
        return const _PlanrBackgroundConfig(
          baseColor: PlanrDesign.backgroundBase,
          baseGradient: PlanrDesign.homeBackgroundGradient,
          leftGradient: PlanrDesign.homeLeftTextureGradient,
          rightGradient: PlanrDesign.homeRightTextureGradient,
          bottomGradient: PlanrDesign.homeBottomWarmGradient,
        );

      case PlanrBackgroundVariant.events:
        return const _PlanrBackgroundConfig(
          baseColor: PlanrDesign.backgroundBase,
          baseGradient: PlanrDesign.eventsBackgroundGradient,
          leftGradient: PlanrDesign.eventsLeftTextureGradient,
          rightGradient: PlanrDesign.eventsRightTextureGradient,
        );

      case PlanrBackgroundVariant.create:
      case PlanrBackgroundVariant.profile:
        return const _PlanrBackgroundConfig(
          baseColor: PlanrDesign.backgroundBase,
          baseGradient: PlanrDesign.profileBackgroundGradient,
          leftGradient: PlanrDesign.profileLeftTextureGradient,
          rightGradient: PlanrDesign.profileRightTextureGradient,
          bottomGradient: PlanrDesign.profileBottomWarmGradient,
        );
      case PlanrBackgroundVariant.friends:
      case PlanrBackgroundVariant.auth:
        return const _PlanrBackgroundConfig(
          baseColor: PlanrDesign.backgroundBase,
          baseGradient: PlanrDesign.homeBackgroundGradient,
          leftGradient: PlanrDesign.homeLeftTextureGradient,
          rightGradient: PlanrDesign.homeRightTextureGradient,
          bottomGradient: PlanrDesign.homeBottomWarmGradient,
        );

      case PlanrBackgroundVariant.plain:
        return const _PlanrBackgroundConfig(
          baseColor: PlanrDesign.backgroundBase,
          baseGradient: PlanrDesign.plainBackgroundGradient,
        );
    }
  }
}

class _PlanrBackgroundConfig {
  const _PlanrBackgroundConfig({
    required this.baseColor,
    required this.baseGradient,
    this.leftGradient,
    this.rightGradient,
    this.bottomGradient,
    this.leftWidth = 280,
    this.leftHeight = 300,
    this.rightWidth = 290,
    this.rightHeight = 460,
    this.bottomHeight = 360,
  });

  final Color baseColor;
  final Gradient baseGradient;

  final Gradient? leftGradient;
  final Gradient? rightGradient;
  final Gradient? bottomGradient;

  final double leftWidth;
  final double leftHeight;
  final double rightWidth;
  final double rightHeight;
  final double bottomHeight;
}