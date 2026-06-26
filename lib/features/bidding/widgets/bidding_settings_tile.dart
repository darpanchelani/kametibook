import 'package:flutter/material.dart';

import '../../kameti/models/kameti_model.dart';

class BiddingSettingsTile extends StatelessWidget {
  const BiddingSettingsTile({
    required this.requirePayment,
    required this.distributionType,
    required this.enabled,
    required this.onRequirePaymentChanged,
    required this.onDistributionChanged,
    super.key,
  });

  final bool requirePayment;
  final DiscountDistributionType distributionType;
  final bool enabled;
  final ValueChanged<bool> onRequirePaymentChanged;
  final ValueChanged<DiscountDistributionType> onDistributionChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: requirePayment,
              onChanged: enabled ? onRequirePaymentChanged : null,
              title: const Text('Require payment before bidding'),
              subtitle: const Text(
                  'Only paid members in the current cycle can submit bids.'),
            ),
            DropdownButtonFormField<DiscountDistributionType>(
              initialValue: distributionType,
              decoration:
                  const InputDecoration(labelText: 'Discount Distribution'),
              items: DiscountDistributionType.values
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)))
                  .toList(),
              onChanged: enabled
                  ? (value) => onDistributionChanged(value ?? distributionType)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
