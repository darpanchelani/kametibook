import 'package:flutter/material.dart';

import '../../member/models/member_model.dart';

class FixedOrderSlotCard extends StatelessWidget {
  const FixedOrderSlotCard({
    required this.cycleNumber,
    required this.members,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final int cycleNumber;
  final List<MemberModel> members;
  final MemberModel? selected;
  final ValueChanged<MemberModel?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<MemberModel>(
          initialValue: selected,
          decoration: InputDecoration(labelText: 'Cycle $cycleNumber Receiver'),
          items: members
              .map((member) =>
                  DropdownMenuItem(value: member, child: Text(member.fullName)))
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}
