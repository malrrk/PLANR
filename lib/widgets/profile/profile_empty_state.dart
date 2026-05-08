import 'package:flutter/material.dart';

import 'profile_design.dart';

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
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: ProfileDesign.cardDecoration(radius: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: ProfileDesign.warmGradient,
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
                  color: ProfileDesign.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account exists, but your profile document is missing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ProfileDesign.muted,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onCreateProfile,
                child: const Text('Create profile now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}