import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_controller.dart';
import '../../bidding/providers/bidding_controller.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../ledger/providers/ledger_controller.dart';
import '../../lucky_draw/providers/lucky_draw_controller.dart';
import '../../member/providers/member_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../../receiver/providers/receiver_controller.dart';
import '../models/report_model.dart';
import '../providers/report_controller.dart';
import '../widgets/report_option_card.dart';
import '../widgets/report_summary_card.dart';

class ReportsDashboardScreen extends ConsumerWidget {
  const ReportsDashboardScreen({required this.kametiId, super.key});
  final String kametiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kameti = _findKameti(ref.watch(kametiControllerProvider), kametiId);
    if (kameti == null) {
      return Scaffold(appBar: AppBar(title: const Text('Reports')), body: const Center(child: Text('Kameti not found')));
    }
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final ledgerController = ref.read(ledgerControllerProvider.notifier);
    final currentCycle = paymentController.getCurrentCycle(kameti.id);
    final summary = ledgerController.calculateGroupLedgerSummary(kameti.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.reportHistory, arguments: kameti.id),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(kameti.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            Text('${kameti.type.label} | ${kameti.status.label} | ${kameti.totalMembers} members'),
            Text('Current cycle: ${currentCycle == null ? '-' : 'Month ${currentCycle.cycleNumber}'}'),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 520 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.25,
              children: [
                ReportSummaryCard(title: 'Collected', value: CurrencyFormatter.pkr(summary.totalContributions)),
                ReportSummaryCard(title: 'Payouts', value: CurrencyFormatter.pkr(summary.totalPayouts)),
                ReportSummaryCard(title: 'Pending Payments', value: '${ref.read(paymentControllerProvider).payments.where((p) => p.kametiId == kameti.id && p.paymentStatus.name != 'paid').length}'),
                ReportSummaryCard(title: 'Balance', value: CurrencyFormatter.pkr(summary.groupBalance)),
              ],
            ),
            const SizedBox(height: 16),
            _option(context, ref, kameti, ReportType.monthlyCycle, 'Monthly Report', 'View payments, receiver, payout, and balance for current cycle.', selectedCycle: currentCycle, enabled: currentCycle != null, reason: 'No cycle found.'),
            _option(context, ref, kameti, ReportType.fullKameti, 'Full Kameti Report', 'Complete group report with members, cycles, ledger, and warnings.'),
            _option(
              context,
              ref,
              kameti,
              ReportType.memberStatement,
              'Member Statement',
              'Generate a statement for a member with payment, payout, discount, and ledger history.',
              selectedMember: _firstMember(ref.read(memberControllerProvider.notifier).getMembersByKametiId(kameti.id)),
              enabled: ref.read(memberControllerProvider.notifier).getMembersByKametiId(kameti.id).isNotEmpty,
              reason: 'No members found.',
            ),
            _option(context, ref, kameti, ReportType.payment, 'Payment Report', 'All payment records with statuses and proof indicators.'),
            _option(context, ref, kameti, ReportType.payout, 'Payout Report', 'All receiver allocations and payout proof status.'),
            _option(context, ref, kameti, ReportType.ledger, 'Ledger Report', 'Complete hisaab book with money in, money out, and balance.'),
            _option(context, ref, kameti, ReportType.bidding, 'Bidding Report', 'Auction sessions, bids, winners, and discount adjustments.', enabled: kameti.type == KametiType.bidding, reason: 'Bidding report is only available for auction kametis.'),
            _option(context, ref, kameti, ReportType.luckyDraw, 'Lucky Draw Report', 'Draw history with eligible and excluded member counts.', enabled: kameti.type == KametiType.luckyDraw, reason: 'Lucky draw report is only available for Khulli Chhutti kametis.'),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context,
    WidgetRef ref,
    KametiModel kameti,
    ReportType type,
    String title,
    String description, {
    bool enabled = true,
    String? reason,
    dynamic selectedCycle,
    dynamic selectedMember,
  }) {
    return ReportOptionCard(
      title: title,
      description: description,
      enabled: enabled,
      disabledReason: reason,
      onGenerate: () {
        final data = _buildData(ref, kameti, type, selectedCycle: selectedCycle, selectedMember: selectedMember);
        Navigator.of(context).pushNamed(AppRoutes.reportPreview, arguments: data);
      },
    );
  }

  ReportData _buildData(WidgetRef ref, KametiModel kameti, ReportType type, {dynamic selectedCycle, dynamic selectedMember}) {
    return ref.read(reportControllerProvider.notifier).buildReportData(
          type: type,
          kameti: kameti,
          generatedBy: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
          members: ref.read(memberControllerProvider.notifier).getMembersByKametiId(kameti.id),
          cycles: ref.read(paymentControllerProvider.notifier).getCyclesByKametiId(kameti.id),
          payments: ref.read(paymentControllerProvider).payments.where((p) => p.kametiId == kameti.id).toList(),
          allocations: ref.read(receiverControllerProvider).allocations.where((a) => a.kametiId == kameti.id).toList(),
          ledgerEntries: ref.read(ledgerControllerProvider.notifier).getLedgerEntriesByKametiId(kameti.id),
          biddingSessions: ref.read(biddingControllerProvider.notifier).getBiddingSessionsByKametiId(kameti.id),
          bids: ref.read(biddingControllerProvider).bids,
          discountAdjustments: ref.read(biddingControllerProvider).adjustments,
          draws: ref.read(luckyDrawControllerProvider.notifier).getDrawsByKametiId(kameti.id),
          selectedCycle: selectedCycle,
          selectedMember: selectedMember,
        );
  }

  KametiModel? _findKameti(List<KametiModel> kametis, String id) {
    for (final kameti in kametis) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }

  dynamic _firstMember(List<dynamic> members) {
    if (members.isEmpty) return null;
    return members.first;
  }
}
