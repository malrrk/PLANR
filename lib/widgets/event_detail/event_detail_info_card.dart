import 'package:flutter/material.dart';

import 'event_detail_design.dart';

class EventDetailInfoCard extends StatelessWidget {
  const EventDetailInfoCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: EventDetailDesign.cardDecoration(),
      child: child,
    );
  }
}