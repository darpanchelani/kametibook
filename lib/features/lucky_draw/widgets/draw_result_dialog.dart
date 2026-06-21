import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../member/models/member_model.dart';

class DrawResultDialog extends StatelessWidget {
  const DrawResultDialog({
    required this.winner,
    required this.amount,
    required this.cycleNumber,
    required this.onSave,
    super.key,
  });

  final MemberModel winner;
  final double amount;
  final int cycleNumber;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Congratulations!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${winner.fullName} has won the kameti for Month $cycleNumber.'),
          const SizedBox(height: 10),
          Text('Winner: ${winner.fullName}'),
          Text('Amount: ${CurrencyFormatter.pkr(amount)}'),
          Text('Cycle: Month $cycleNumber'),
          Text('Draw Date: ${DateFormatter.display(DateTime.now())}'),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSave();
          },
          child: const Text('Save Result'),
        ),
      ],
    );
  }
}
