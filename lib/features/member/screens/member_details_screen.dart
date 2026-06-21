import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../payment/models/payment_models.dart';
import '../../payment/providers/payment_controller.dart';
import '../../payment/widgets/payment_status_badge.dart';
import '../models/member_model.dart';
import '../providers/member_controller.dart';
import '../widgets/member_info_tile.dart';
import '../widgets/member_role_badge.dart';
import '../widgets/member_status_badge.dart';

class MemberDetailsScreen extends ConsumerWidget {
  const MemberDetailsScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(paymentControllerProvider);
    MemberModel? member;
    for (final item in ref.watch(memberControllerProvider)) {
      if (item.id == memberId) {
        member = item;
        break;
      }
    }
    if (member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Details')),
        body: const Center(child: Text('Member not found')),
      );
    }
    final selectedMember = member;
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final payments = paymentController.getPaymentsByMemberId(selectedMember.id);
    final paidCycles = payments.where((payment) => payment.paymentStatus == PaymentStatus.paid).length;
    final pendingCycles = payments.where((payment) => payment.paymentStatus == PaymentStatus.pending).length;
    final lateCycles = payments.where((payment) => payment.paymentStatus == PaymentStatus.late).length;
    final totalPaid = payments.fold<double>(0, (total, payment) => total + payment.amountPaid);
    final totalPending = payments.fold<double>(
      0,
      (total, payment) => total + (payment.countsAsPaid ? 0 : payment.amountDue),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Member Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedMember.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      MemberRoleBadge(role: selectedMember.role),
                      MemberStatusBadge(status: selectedMember.status),
                    ]),
                    const SizedBox(height: 12),
                    MemberInfoTile(label: 'Phone', value: selectedMember.phone, icon: Icons.phone_outlined),
                    MemberInfoTile(label: 'WhatsApp', value: selectedMember.whatsappNumber, icon: Icons.chat_outlined),
                    MemberInfoTile(label: 'Email', value: selectedMember.email, icon: Icons.email_outlined),
                    MemberInfoTile(label: 'City', value: selectedMember.city, icon: Icons.location_city_outlined),
                    if (selectedMember.cnic.isNotEmpty)
                      MemberInfoTile(label: 'CNIC', value: selectedMember.cnic, icon: Icons.badge_outlined),
                    MemberInfoTile(label: 'Role', value: selectedMember.role.label, icon: Icons.admin_panel_settings_outlined),
                    MemberInfoTile(label: 'Status', value: selectedMember.status.label, icon: Icons.flag_outlined),
                    MemberInfoTile(
                      label: 'Joined Date',
                      value: DateFormatter.display(selectedMember.joinedAt),
                      icon: Icons.event_outlined,
                    ),
                    MemberInfoTile(
                      label: 'Has Received Kameti',
                      value: selectedMember.hasReceivedKameti ? 'Yes' : 'No',
                      icon: Icons.savings_outlined,
                    ),
                    if (selectedMember.notes.isNotEmpty)
                      MemberInfoTile(label: 'Notes', value: selectedMember.notes, icon: Icons.notes_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedMember.hasReceivedKameti ? 'Kameti Received' : 'Kameti not received yet.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    if (selectedMember.hasReceivedKameti) ...[
                      const SizedBox(height: 8),
                      Text('Cycle: Month ${selectedMember.receivedCycleNumber ?? '-'}'),
                      Text(
                        'Received Date: ${selectedMember.receivedAt == null ? '-' : DateFormatter.display(selectedMember.receivedAt!)}',
                      ),
                      Text('Received Amount: ${CurrencyFormatter.pkr(selectedMember.receivedAmount)}'),
                      const Text('Draw Type: Lucky Draw'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        _HistoryStat(label: 'Total Cycles', value: '${payments.length}'),
                        _HistoryStat(label: 'Paid Cycles', value: '$paidCycles'),
                        _HistoryStat(label: 'Pending Cycles', value: '$pendingCycles'),
                        _HistoryStat(label: 'Late Cycles', value: '$lateCycles'),
                        _HistoryStat(label: 'Total Paid', value: CurrencyFormatter.pkr(totalPaid)),
                        _HistoryStat(label: 'Total Pending', value: CurrencyFormatter.pkr(totalPending)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (payments.isEmpty)
                      const Text('No payment history yet.')
                    else
                      ...payments.map((payment) {
                        final cycle = paymentController.getCycle(payment.cycleId);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Cycle ${cycle?.cycleNumber ?? '-'} - ${cycle?.monthLabel ?? ''}'),
                          subtitle: Text(
                            'Due: ${CurrencyFormatter.pkr(payment.amountDue)} | Paid: ${CurrencyFormatter.pkr(payment.amountPaid)}'
                            '${payment.paidAt == null ? '' : ' | ${DateFormatter.display(payment.paidAt!)}'}',
                          ),
                          trailing: PaymentStatusBadge(status: payment.paymentStatus),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...['Received Kameti Details', 'Penalties', 'Ledger Entries'].map(
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
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
