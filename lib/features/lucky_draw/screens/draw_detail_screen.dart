import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../member/models/member_model.dart';
import '../../member/providers/member_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../models/lucky_draw_model.dart';
import '../providers/lucky_draw_controller.dart';
import '../widgets/draw_status_badge.dart';

class DrawDetailScreen extends ConsumerWidget {
  const DrawDetailScreen({required this.drawId, super.key});

  final String drawId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(luckyDrawControllerProvider);
    ref.watch(memberControllerProvider);
    LuckyDrawModel? draw;
    for (final item in ref.read(luckyDrawControllerProvider)) {
      if (item.id == drawId) {
        draw = item;
        break;
      }
    }
    final selectedDraw = draw;
    if (selectedDraw == null) {
      return Scaffold(appBar: AppBar(title: const Text('Draw Detail')), body: const Center(child: Text('Draw not found')));
    }
    final kameti = _findKameti(ref.watch(kametiControllerProvider), selectedDraw.kametiId);
    final memberController = ref.read(memberControllerProvider.notifier);
    final cycle = ref.read(paymentControllerProvider.notifier).getCycle(selectedDraw.cycleId);
    final winner = memberController.getMember(selectedDraw.winnerMemberId);
    final eligibleMembers = selectedDraw.eligibleMemberIds.map(memberController.getMember).whereType<MemberModel>().toList();
    final excludedMembers = selectedDraw.excludedMemberIds.map(memberController.getMember).whereType<MemberModel>().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Draw Detail')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kameti?.name ?? 'Kameti', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    DrawStatusBadge(status: selectedDraw.status),
                    const SizedBox(height: 12),
                    _Line(label: 'Cycle', value: 'Month ${selectedDraw.cycleNumber} - ${cycle?.monthLabel ?? ''}'),
                    _Line(label: 'Winner', value: selectedDraw.winnerName),
                    _Line(label: 'Winner Phone', value: winner?.phone ?? '-'),
                    _Line(label: 'Payout Amount', value: CurrencyFormatter.pkr(selectedDraw.payoutAmount)),
                    _Line(label: 'Draw Date', value: DateFormatter.display(selectedDraw.drawDate)),
                    _Line(label: 'Draw Type', value: selectedDraw.drawType.label),
                    _Line(label: 'Created By', value: selectedDraw.createdBy),
                    _Line(label: 'Eligible Members', value: '${selectedDraw.totalEligibleMembers}'),
                    _Line(label: 'Excluded Members', value: '${selectedDraw.totalExcludedMembers}'),
                    if (selectedDraw.notes.isNotEmpty) _Line(label: 'Notes', value: selectedDraw.notes),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Eligible Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ...eligibleMembers.map((member) => ListTile(title: Text(member.fullName), subtitle: Text(member.phone))),
            const SizedBox(height: 12),
            Text('Excluded Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ...excludedMembers.map(
              (member) => ListTile(
                title: Text(member.fullName),
                subtitle: Text(selectedDraw.exclusionReasons[member.id] ?? '-'),
              ),
            ),
            const SizedBox(height: 12),
            ...['Payout Proof', 'Ledger Entry', 'PDF Report'].map(
              (title) => Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_clock_outlined),
                  title: Text(title),
                  subtitle: const Text('Coming in next phases.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  KametiModel? _findKameti(List<KametiModel> kametis, String id) {
    for (final kameti in kametis) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
