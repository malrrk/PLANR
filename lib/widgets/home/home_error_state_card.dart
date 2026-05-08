import 'package:flutter/material.dart';

import 'home_design.dart';

class HomeErrorStateCard extends StatelessWidget {
  const HomeErrorStateCard({
    super.key,
    required this.message,
    this.height,
  });

  final String message;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      decoration: HomeDesign.cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade500,
            size: 22,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}