import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../member/models/member_model.dart';
import '../models/bidding_models.dart';

class BidCard extends StatelessWidget {
  const BidCard({
    required this.bid,
    required this.member,
    required this.canEdit,
    required this.onEdit,
    required this.onWithdraw,
    super.key,
  });

  final BidModel bid;
  final MemberModel? member;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${bid.memberName} - ${CurrencyFormatter.pkr(bid.bidAmount)}', style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${member?.phone ?? '-'}\nSubmitted: ${DateFormatter.display(bid.submittedAt)}${bid.note.isEmpty ? '' : '\n${bid.note}'}'),
        isThreeLine: bid.note.isNotEmpty,
        trailing: PopupMenuButton<String>(
          enabled: canEdit,
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'withdraw') onWithdraw();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'withdraw', child: Text('Withdraw')),
          ],
        ),
      ),
    );
  }
}
