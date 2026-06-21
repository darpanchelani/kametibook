import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/empty_state.dart';
import '../../member/models/member_model.dart';
import '../../member/providers/member_controller.dart';
import '../models/payment_models.dart';
import '../providers/payment_controller.dart';
import '../widgets/mark_payment_bottom_sheet.dart';
import '../widgets/member_payment_card.dart';
import '../widgets/payment_filter_chips.dart';
import '../widgets/payment_summary_card.dart';

class CyclePaymentsScreen extends ConsumerStatefulWidget {
  const CyclePaymentsScreen({required this.cycleId, super.key});

  final String cycleId;

  @override
  ConsumerState<CyclePaymentsScreen> createState() => _CyclePaymentsScreenState();
}

class _CyclePaymentsScreenState extends ConsumerState<CyclePaymentsScreen> {
  final _searchController = TextEditingController();
  PaymentStatus? _filter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(paymentControllerProvider);
    ref.watch(memberControllerProvider);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final memberController = ref.read(memberControllerProvider.notifier);
    final cycle = paymentController.getCycle(widget.cycleId);
    if (cycle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cycle Payments')),
        body: const Center(child: Text('Cycle not found')),
      );
    }

    final payments = paymentController.getPaymentsByCycleId(cycle.id);
    final query = _searchController.text.trim().toLowerCase();
    final filtered = payments.where((payment) {
      final member = memberController.getMember(payment.memberId);
      final matchesFilter = _filter == null || payment.paymentStatus == _filter;
      final matchesSearch = query.isEmpty ||
          (member?.fullName.toLowerCase().contains(query) ?? false) ||
          (member?.phone.toLowerCase().contains(query) ?? false);
      return matchesFilter && matchesSearch && member?.status != MemberStatus.removed;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Cycle Payments')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PaymentSummaryCard(
              title: 'Month ${cycle.cycleNumber} - ${cycle.monthLabel}',
              expectedAmount: cycle.expectedAmount,
              collectedAmount: cycle.collectedAmount,
              pendingAmount: cycle.pendingAmount,
              paidCount: paymentController.getPaidMembersCount(cycle.id),
              pendingCount: paymentController.getPendingMembersCount(cycle.id),
              lateCount: paymentController.getLateMembersCount(cycle.id),
              rejectedCount: paymentController.getRejectedMembersCount(cycle.id),
            ),
            const SizedBox(height: 8),
            Text('Due Date: ${DateFormatter.display(cycle.dueDate)}'),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Search by member name or phone', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 12),
            PaymentFilterChips(selected: _filter, onChanged: (value) => setState(() => _filter = value)),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              const EmptyState(icon: Icons.receipt_long_outlined, title: 'No payments found.')
            else
              ...filtered.map((payment) {
                final member = memberController.getMember(payment.memberId);
                return MemberPaymentCard(
                  payment: payment,
                  member: member,
                  onMarkPaid: () => _openMarkPaid(payment),
                  onMarkPending: () {
                    paymentController.markPaymentPending(payment.id);
                    SnackbarHelper.showSuccess(context, 'Payment marked as pending.');
                  },
                  onMarkLate: () => _markLate(payment),
                  onReject: () => _rejectPayment(payment),
                  onEdit: () => _openMarkPaid(payment),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _openMarkPaid(MemberPaymentModel payment) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => MarkPaymentBottomSheet(
        payment: payment,
        onSubmit: (data) {
          ref.read(paymentControllerProvider.notifier).markPaymentPaid(payment.id, data);
          Navigator.of(context).pop();
          SnackbarHelper.showSuccess(this.context, 'Payment marked as paid.');
        },
      ),
    );
  }

  Future<void> _markLate(MemberPaymentModel payment) async {
    final note = await _noteDialog(title: 'Mark Payment Late', hint: 'Optional note');
    if (!mounted) return;
    ref.read(paymentControllerProvider.notifier).markPaymentLate(payment.id, note ?? '');
    SnackbarHelper.showSuccess(context, 'Payment marked as late.');
  }

  Future<void> _rejectPayment(MemberPaymentModel payment) async {
    final reason = await _noteDialog(title: 'Reject Payment', hint: 'Rejection reason');
    if (!mounted) return;
    ref.read(paymentControllerProvider.notifier).rejectPayment(payment.id, reason ?? '');
    SnackbarHelper.showSuccess(context, 'Payment rejected.');
  }

  Future<String?> _noteDialog({required String title, required String hint}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
  }
}
