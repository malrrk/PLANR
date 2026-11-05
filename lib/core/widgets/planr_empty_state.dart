import 'package:flutter/material.dart';

import '../theme/planr_design.dart';
import 'planr_button.dart';
import 'planr_card.dart';

class PlanrEmptyState extends StatelessWidget {
  const PlanrEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return PlanrCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: PlanrDesign.accentSoft.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
            child: Icon(
              icon,
              color: PlanrDesign.accentDark,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PlanrDesign.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PlanrDesign.muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: 18),
            PlanrButton(
              label: actionLabel!,
              onPressed: onActionPressed,
            ),
          ],
        ],
      ),
    );
  }
}