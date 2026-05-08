import 'package:flutter/material.dart';

import '../theme/planr_design.dart';

enum PlanrButtonVariant {
  filled,
  soft,
  outlined,
  ghost,
}

class PlanrButton extends StatelessWidget {
  const PlanrButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = PlanrButtonVariant.filled,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PlanrButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    final backgroundColor = switch (variant) {
      PlanrButtonVariant.filled => PlanrDesign.accent,
      PlanrButtonVariant.soft => PlanrDesign.accentSoft,
      PlanrButtonVariant.outlined => Colors.white.withOpacity(0.42),
      PlanrButtonVariant.ghost => Colors.transparent,
    };

    final foregroundColor = switch (variant) {
      PlanrButtonVariant.filled => Colors.white,
      PlanrButtonVariant.soft => PlanrDesign.accentDark,
      PlanrButtonVariant.outlined => PlanrDesign.ink,
      PlanrButtonVariant.ghost => PlanrDesign.accentDark,
    };

    final borderColor = switch (variant) {
      PlanrButtonVariant.filled => PlanrDesign.accent,
      PlanrButtonVariant.soft => PlanrDesign.accentSoft,
      PlanrButtonVariant.outlined => Colors.white.withOpacity(0.95),
      PlanrButtonVariant.ghost => Colors.transparent,
    };

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: disabled ? PlanrDesign.softMuted.withOpacity(0.25) : backgroundColor,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: disabled ? Colors.black.withOpacity(0.05) : borderColor,
                width: 1.2,
              ),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: foregroundColor,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: foregroundColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}