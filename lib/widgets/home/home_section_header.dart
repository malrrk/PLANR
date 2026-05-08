import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: PlanrDesign.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: PlanrDesign.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      ),
    );
  }
}