import 'package:flutter/material.dart';

import '../../member/models/member_model.dart';
import '../../payment/models/payment_models.dart';
import '../../payment/widgets/payment_status_badge.dart';

class EligibleMemberCard extends StatelessWidget {
  const EligibleMemberCard({
    required this.member,
    required this.paymentStatus,
    super.key,
  });

  final MemberModel member;
  final PaymentStatus? paymentStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
            child: Text(member.fullName.isEmpty
                ? '?'
                : member.fullName[0].toUpperCase())),
        title: Text(member.fullName,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle:
            Text('${member.phone}\n${member.city}\nHas received kameti: No'),
        isThreeLine: true,
        trailing: paymentStatus == null
            ? null
            : PaymentStatusBadge(status: paymentStatus!),
      ),
    );
  }
}
