import 'package:flutter/material.dart';

import '../../core/theme/planr_design.dart';

class HomeLoadingCard extends StatelessWidget {
  const HomeLoadingCard({
    super.key,
    this.height = 140,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: PlanrDesign.cardDecoration(),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
        ),
      ),
    );
  }
}