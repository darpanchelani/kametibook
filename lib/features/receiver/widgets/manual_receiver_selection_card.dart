import 'package:flutter/material.dart';

import '../../member/models/member_model.dart';

class ManualReceiverSelectionCard extends StatelessWidget {
  const ManualReceiverSelectionCard({
    required this.members,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<MemberModel> members;
  final MemberModel? selected;
  final ValueChanged<MemberModel?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<MemberModel>(
          initialValue: selected,
          decoration: const InputDecoration(labelText: 'Select receiver'),
          validator: (value) => value == null ? 'Receiver is required' : null,
          items: members.map((member) => DropdownMenuItem(value: member, child: Text(member.fullName))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
