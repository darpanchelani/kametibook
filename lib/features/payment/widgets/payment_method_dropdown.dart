import 'package:flutter/material.dart';

import '../models/payment_models.dart';

class PaymentMethodDropdown extends StatelessWidget {
  const PaymentMethodDropdown({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PaymentMethod? value;
  final ValueChanged<PaymentMethod?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PaymentMethod>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Payment Method',
        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
      ),
      validator: (value) => value == null ? 'Payment method is required' : null,
      items: PaymentMethod.values
          .map((method) =>
              DropdownMenuItem(value: method, child: Text(method.label)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
