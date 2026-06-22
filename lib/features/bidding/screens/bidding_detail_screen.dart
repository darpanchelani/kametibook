import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../member/providers/member_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../providers/bidding_controller.dart';
import '../widgets/bid_card.dart';
import '../widgets/bidding_status_badge.dart';
import '../widgets/discount_adjustment_card.dart';

class BiddingDetailScreen extends ConsumerWidget {
  const BiddingDetailScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(biddingControllerProvider);
    ref.watch(memberControllerProvider);
    final biddingController = ref.read(biddingControllerProvider.notifier);
    final memberController = ref.read(memberControllerProvider.notifier);
    final session = biddingController.getSession(sessionId);
    if (session == null) {
      return Scaffold(appBar: AppBar(title: const Text('Bidding Detail')), body: const Center(child: Text('Bidding session not found')));
    }
    final kameti = _findKameti(ref.watch(kametiControllerProvider), session.kametiId);
    final cycle = ref.read(paymentControllerProvider.notifier).getCycle(session.cycleId);
    final winner = memberController.getMember(session.winnerMemberId);
    final bids = biddingController.getBidsBySessionId(session.id);
    final adjustments = biddingController.getAdjustmentsBySessionId(session.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Bidding Detail')),
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
                    BiddingStatusBadge(status: session.status),
                    const SizedBox(height: 12),
                    _Line(label: 'Cycle', value: 'Month ${session.cycleNumber} - ${cycle?.monthLabel ?? ''}'),
                    _Line(label: 'Winner', value: winner?.fullName ?? '-'),
                    _Line(label: 'Winner Phone', value: winner?.phone ?? '-'),
                    _Line(label: 'Winning Amount', value: CurrencyFormatter.pkr(session.winningAmount)),
                    _Line(label: 'Total Pool', value: CurrencyFormatter.pkr(session.totalPoolAmount)),
                    _Line(label: 'Discount', value: CurrencyFormatter.pkr(session.discountAmount)),
                    _Line(label: 'Distribution', value: session.discountDistributionType.label),
                    _Line(label: 'Created By', value: session.createdBy),
                    if (session.startTime != null) _Line(label: 'Start Time', value: DateFormatter.display(session.startTime!)),
                    if (session.endTime != null) _Line(label: 'End Time', value: DateFormatter.display(session.endTime!)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('All Bids', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            if (bids.isEmpty)
              const Text('No bids submitted.')
            else
              ...bids.map((bid) => BidCard(
                    bid: bid,
                    member: memberController.getMember(bid.memberId),
                    canEdit: false,
                    onEdit: () {},
                    onWithdraw: () {},
                  )),
            const SizedBox(height: 12),
            Text('Discount Adjustments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            if (adjustments.isEmpty)
              const Text('No discount adjustments.')
            else
              ...adjustments.map((adjustment) => DiscountAdjustmentCard(adjustment: adjustment)),
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
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
