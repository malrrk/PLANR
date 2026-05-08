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
              alignment: config.leftAlignment,
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
              alignment: config.rightAlignment,
              child: Container(
                width: config.rightWidth,
                height: config.rightHeight,
                decoration: BoxDecoration(
                  gradient: config.rightGradient,
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
        );

      case PlanrBackgroundVariant.plain:
        return const _PlanrBackgroundConfig(
          baseColor: PlanrDesign.backgroundBase,
          baseGradient: PlanrDesign.plainBackgroundGradient,
        );

      case PlanrBackgroundVariant.events:
      case PlanrBackgroundVariant.create:
      case PlanrBackgroundVariant.profile:
      case PlanrBackgroundVariant.friends:
      case PlanrBackgroundVariant.auth:
        return const _PlanrBackgroundConfig(
          baseColor: PlanrDesign.backgroundBase,
          baseGradient: PlanrDesign.homeBackgroundGradient,
          leftGradient: PlanrDesign.homeLeftTextureGradient,
          rightGradient: PlanrDesign.homeRightTextureGradient,
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
    this.leftAlignment = Alignment.topLeft,
    this.rightAlignment = Alignment.centerRight,
    this.leftWidth = 260,
    this.leftHeight = 260,
    this.rightWidth = 260,
    this.rightHeight = 420,
  });

  final Color baseColor;
  final Gradient baseGradient;

  final Gradient? leftGradient;
  final Gradient? rightGradient;

  final Alignment leftAlignment;
  final Alignment rightAlignment;

  final double leftWidth;
  final double leftHeight;
  final double rightWidth;
  final double rightHeight;
}