import 'package:flutter/material.dart';

import '../../member/models/member_model.dart';

class ExcludedMemberCard extends StatelessWidget {
  const ExcludedMemberCard({
    required this.member,
    required this.reason,
    super.key,
  });

  final MemberModel member;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.block_outlined),
        title: Text(member.fullName,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(reason),
      ),
    );
  }
}
