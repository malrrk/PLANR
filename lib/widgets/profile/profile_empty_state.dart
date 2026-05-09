import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';
import '../../core/widgets/planr_button.dart';
import '../../core/widgets/planr_card.dart';

class ProfileEmptyState extends StatelessWidget {
  const ProfileEmptyState({
    super.key,
    required this.onCreateProfile,
  });

  final VoidCallback onCreateProfile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlanrDesign.pagePadding),
        child: PlanrCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: PlanrDesign.brandGradient,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No profile found',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: PlanrDesign.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account exists, but your profile document is missing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlanrDesign.muted,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              PlanrButton(
                label: 'Create profile now',
                icon: Icons.add_rounded,
                onPressed: onCreateProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}