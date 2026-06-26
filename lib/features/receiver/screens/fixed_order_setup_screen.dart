import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../member/models/member_model.dart';
import '../../member/providers/member_controller.dart';
import '../providers/receiver_controller.dart';
import '../widgets/fixed_order_slot_card.dart';

class FixedOrderSetupScreen extends ConsumerStatefulWidget {
  const FixedOrderSetupScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  ConsumerState<FixedOrderSetupScreen> createState() =>
      _FixedOrderSetupScreenState();
}

class _FixedOrderSetupScreenState extends ConsumerState<FixedOrderSetupScreen> {
  final Map<int, MemberModel> _assignments = {};

  @override
  Widget build(BuildContext context) {
    final kameti =
        _findKameti(ref.watch(kametiControllerProvider), widget.kametiId);
    ref.watch(memberControllerProvider);
    ref.watch(receiverControllerProvider);
    if (kameti == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Fixed Order')),
          body: const Center(child: Text('Kameti not found')));
    }
    final members = ref
        .read(memberControllerProvider.notifier)
        .getMembersByKametiId(kameti.id)
        .where((member) => member.status == MemberStatus.active)
        .toList();
    if (_assignments.isEmpty) {
      for (final slot in ref
          .read(receiverControllerProvider.notifier)
          .getFixedOrderSlots(kameti.id)) {
        MemberModel? member;
        for (final item in members) {
          if (item.id == slot.memberId) {
            member = item;
            break;
          }
        }
        if (member != null) _assignments[slot.cycleNumber] = member;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Set Fixed Order')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(kameti.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Total members: ${kameti.totalMembers}'),
            Text('Duration: ${kameti.durationMonths} months'),
            const SizedBox(height: 10),
            const Text(
                'Assign one member to each cycle. Each member can appear only once.'),
            const SizedBox(height: 14),
            AppButton(
                label: 'Auto Fill Order',
                icon: Icons.auto_fix_high_outlined,
                onPressed: () => _autoFill(members, kameti.totalMembers)),
            const SizedBox(height: 8),
            AppButton(
                label: 'Clear Order',
                isOutlined: true,
                onPressed: () => setState(_assignments.clear)),
            const SizedBox(height: 14),
            for (var cycle = 1; cycle <= kameti.totalMembers; cycle++)
              FixedOrderSlotCard(
                cycleNumber: cycle,
                members: members,
                selected: _assignments[cycle],
                onChanged: (member) => setState(() {
                  if (member == null) {
                    _assignments.remove(cycle);
                  } else {
                    _assignments[cycle] = member;
                  }
                }),
              ),
            const SizedBox(height: 16),
            AppButton(
                label: 'Save Order',
                icon: Icons.save_outlined,
                onPressed: () => _save(kameti)),
          ],
        ),
      ),
    );
  }

  void _autoFill(List<MemberModel> members, int count) {
    setState(() {
      _assignments
        ..clear()
        ..addEntries([
          for (var i = 0; i < count && i < members.length; i++)
            MapEntry(i + 1, members[i]),
        ]);
    });
  }

  void _save(KametiModel kameti) {
    final error = ref
        .read(receiverControllerProvider.notifier)
        .saveFixedOrder(kameti: kameti, assignments: _assignments);
    if (error != null) {
      SnackbarHelper.showError(context, error);
    } else {
      SnackbarHelper.showSuccess(context, 'Fixed order saved successfully.');
      Navigator.of(context).pop();
    }
  }

  KametiModel? _findKameti(List<KametiModel> kametis, String id) {
    for (final kameti in kametis) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }
}
