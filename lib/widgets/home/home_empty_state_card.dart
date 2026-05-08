import 'package:flutter/material.dart';

import 'home_design.dart';

class HomeEmptyStateCard extends StatelessWidget {
  const HomeEmptyStateCard({
    super.key,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
    this.icon = Icons.auto_awesome_rounded,
    this.height,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final IconData icon;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: HomeDesign.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: HomeDesign.brandGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: HomeDesign.muted,
                fontSize: 15.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onActionPressed,
              style: FilledButton.styleFrom(
                backgroundColor: HomeDesign.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}