import 'package:flutter/material.dart';

import '../models/receiver_allocation_model.dart';

class AllocationTypeBadge extends StatelessWidget {
  const AllocationTypeBadge({required this.type, super.key});

  final ReceiverAllocationType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade700.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(type.label,
          style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w800,
              fontSize: 12)),
    );
  }
}
