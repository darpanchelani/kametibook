import 'package:flutter/material.dart';

import '../../lucky_draw/widgets/eligible_member_card.dart';
import '../../member/models/member_model.dart';
import '../../payment/models/payment_models.dart';

class EligibleReceiverCard extends StatelessWidget {
  const EligibleReceiverCard(
      {required this.member, required this.paymentStatus, super.key});

  final MemberModel member;
  final PaymentStatus? paymentStatus;

  @override
  Widget build(BuildContext context) {
    return EligibleMemberCard(member: member, paymentStatus: paymentStatus);
  }
}
