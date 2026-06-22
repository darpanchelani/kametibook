import 'package:flutter/material.dart';

import '../../lucky_draw/widgets/excluded_member_card.dart';
import '../../member/models/member_model.dart';

class ExcludedReceiverCard extends StatelessWidget {
  const ExcludedReceiverCard({required this.member, required this.reason, super.key});

  final MemberModel member;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return ExcludedMemberCard(member: member, reason: reason);
  }
}
