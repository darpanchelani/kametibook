import 'package:flutter/material.dart';

import '../models/payment_models.dart';

class PaymentFilterChips extends StatelessWidget {
  const PaymentFilterChips({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final PaymentStatus? selected;
  final ValueChanged<PaymentStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onChanged(null)),
        for (final status in PaymentStatus.values)
          FilterChip(
            label: Text(status.label),
            selected: selected == status,
            onSelected: (_) => onChanged(status),
          ),
      ],
    );
  }
}
