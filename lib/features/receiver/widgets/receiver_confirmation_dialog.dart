import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../member/models/member_model.dart';

class ReceiverConfirmationDialog extends StatelessWidget {
  const ReceiverConfirmationDialog({
    required this.member,
    required this.amount,
    required this.cycleNumber,
    super.key,
  });

  final MemberModel member;
  final double amount;
  final int cycleNumber;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Receiver?'),
      content: Text(
        '${member.fullName} will receive ${CurrencyFormatter.pkr(amount)} for Month $cycleNumber. This cannot be changed later.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
      ],
    );
  }
}
