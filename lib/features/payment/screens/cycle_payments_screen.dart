import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_controller.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../ledger/providers/ledger_controller.dart';
import '../../ledger/widgets/penalty_form_bottom_sheet.dart';
import '../../member/models/member_model.dart';
import '../../member/providers/member_controller.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/providers/notification_controller.dart';
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
            AppButton(
              label: 'Add Penalty',
              icon: Icons.warning_amber_outlined,
              isOutlined: true,
              onPressed: () => _addPenalty(cycle.id, cycle.kametiId),
            ),
            const SizedBox(height: 12),
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
                    _syncPaymentLedger(payment.kametiId);
                    _createPaymentNotification(payment, AppNotificationType.paymentDueReminder, 'Payment Pending', 'Payment marked as pending.');
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
          _syncPaymentLedger(payment.kametiId);
          _createPaymentNotification(payment, AppNotificationType.paymentMarkedPaid, 'Payment Received', 'Payment marked as paid.');
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
    _syncPaymentLedger(payment.kametiId);
    _createPaymentNotification(payment, AppNotificationType.paymentOverdue, 'Payment Overdue', 'Payment marked as late.');
    SnackbarHelper.showSuccess(context, 'Payment marked as late.');
  }

  Future<void> _rejectPayment(MemberPaymentModel payment) async {
    final reason = await _noteDialog(title: 'Reject Payment', hint: 'Rejection reason');
    if (!mounted) return;
    ref.read(paymentControllerProvider.notifier).rejectPayment(payment.id, reason ?? '');
    _syncPaymentLedger(payment.kametiId);
    _createPaymentNotification(payment, AppNotificationType.paymentRejected, 'Payment Rejected', 'Payment was rejected. Please review.');
    SnackbarHelper.showSuccess(context, 'Payment rejected.');
  }

  void _syncPaymentLedger(String kametiId) {
    ref.read(ledgerControllerProvider.notifier).syncLedgerForKameti(
          kametiId: kametiId,
          payments: ref.read(paymentControllerProvider).payments,
          allocations: const [],
          biddingSessions: const [],
          discountAdjustments: const [],
        );
  }

  void _createPaymentNotification(MemberPaymentModel payment, AppNotificationType type, String title, String fallbackMessage) {
    final member = ref.read(memberControllerProvider.notifier).getMember(payment.memberId);
    final kameti = ref.read(kametiControllerProvider.notifier).byId(payment.kametiId);
    final cycle = ref.read(paymentControllerProvider.notifier).getCycle(payment.cycleId);
    final message = switch (type) {
      AppNotificationType.paymentMarkedPaid => '${member?.fullName ?? 'Member'} paid ${payment.amountDue.toStringAsFixed(0)} for ${kameti?.name ?? 'kameti'} Cycle ${cycle?.cycleNumber ?? 0}.',
      AppNotificationType.paymentRejected => 'Payment for ${member?.fullName ?? 'member'} was rejected. Please review.',
      AppNotificationType.paymentOverdue => '${member?.fullName ?? 'Member'} payment is overdue for Cycle ${cycle?.cycleNumber ?? 0}.',
      _ => fallbackMessage,
    };
    ref.read(notificationControllerProvider.notifier).createNotification(
          ref.read(notificationControllerProvider.notifier).buildNotification(
                userId: ref.read(authControllerProvider).user?.id ?? 'mock-user',
                kametiId: payment.kametiId,
                cycleId: payment.cycleId,
                memberId: payment.memberId,
                relatedPaymentId: payment.id,
                type: type,
                title: title,
                message: message,
                priority: type == AppNotificationType.paymentMarkedPaid ? NotificationPriority.normal : NotificationPriority.high,
                actionType: NotificationActionType.openPayment,
                actionRoute: AppRoutes.cyclePayments,
              ),
        );
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

  Future<void> _addPenalty(String cycleId, String kametiId) async {
    final members = ref.read(memberControllerProvider.notifier).getMembersByKametiId(kametiId);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => PenaltyFormBottomSheet(
        members: members,
        onSubmit: (member, amount, note) {
          ref.read(ledgerControllerProvider.notifier).addPenalty(
                kametiId: kametiId,
                cycleId: cycleId,
                memberId: member.id,
                amount: amount,
                note: note,
                createdBy: 'Organizer',
              );
          Navigator.of(sheetContext).pop();
          SnackbarHelper.showSuccess(context, 'Penalty added successfully.');
        },
      ),
    );
  }
}
