import 'package:flutter/material.dart';

class CycleProgressBar extends StatelessWidget {
  const CycleProgressBar({
    required this.collectedAmount,
    required this.expectedAmount,
    super.key,
  });

  final double collectedAmount;
  final double expectedAmount;

  @override
  Widget build(BuildContext context) {
    final progress = expectedAmount <= 0 ? 0.0 : (collectedAmount / expectedAmount).clamp(0.0, 1.0);
    return LinearProgressIndicator(value: progress);
  }
}
