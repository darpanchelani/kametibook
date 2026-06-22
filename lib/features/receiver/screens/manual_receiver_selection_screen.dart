import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/providers/auth_controller.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../member/models/member_model.dart';
import '../../member/providers/member_controller.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/providers/notification_controller.dart';
import '../../payment/models/payment_models.dart';
import '../../payment/providers/payment_controller.dart';
import '../models/receiver_allocation_model.dart';
import '../providers/receiver_controller.dart';
import '../widgets/eligible_receiver_card.dart';
import '../widgets/excluded_receiver_card.dart';
import '../widgets/manual_receiver_selection_card.dart';
import '../widgets/receiver_confirmation_dialog.dart';

class ManualReceiverSelectionScreen extends ConsumerStatefulWidget {
  const ManualReceiverSelectionScreen({
    required this.kametiId,
    required this.allocationType,
    super.key,
  });

  final String kametiId;
  final ReceiverAllocationType allocationType;

  @override
  ConsumerState<ManualReceiverSelectionScreen> createState() => _ManualReceiverSelectionScreenState();
}

class _ManualReceiverSelectionScreenState extends ConsumerState<ManualReceiverSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  MemberModel? _selectedMember;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kameti = _findKameti(ref.watch(kametiControllerProvider), widget.kametiId);
    ref.watch(memberControllerProvider);
    ref.watch(paymentControllerProvider);
    ref.watch(receiverControllerProvider);
    if (kameti == null) {
      return Scaffold(appBar: AppBar(title: const Text('Select Receiver')), body: const Center(child: Text('Kameti not found')));
    }
    final memberController = ref.read(memberControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final receiverController = ref.read(receiverControllerProvider.notifier);
    final cycle = paymentController.getCurrentCycle(kameti.id);
    final members = memberController.getMembersByKametiId(kameti.id);
    final payments = cycle == null ? <MemberPaymentModel>[] : paymentController.getPaymentsByCycleId(cycle.id);
    final eligibility = receiverController.getEligibleReceivers(
      kameti: kameti,
      cycle: cycle,
      allocationType: widget.allocationType,
      members: members,
      payments: payments,
    );
    final allocation = cycle == null ? null : receiverController.getCurrentCycleAllocation(kameti.id, cycle.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.allocationType.label)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(kameti.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(cycle == null ? 'No active payment cycle found.' : 'Month ${cycle.cycleNumber} - ${cycle.monthLabel}'),
              if (cycle != null) Text('Amount: ${CurrencyFormatter.pkr(cycle.expectedAmount)}'),
              const SizedBox(height: 12),
              if (allocation != null)
                Card(
                  child: ListTile(
                    title: const Text('Receiver already confirmed'),
                    subtitle: Text('${allocation.memberName} - ${CurrencyFormatter.pkr(allocation.amount)}'),
                  ),
                )
              else ...[
                ManualReceiverSelectionCard(
                  members: eligibility.eligibleMembers,
                  selected: _selectedMember,
                  onChanged: (value) => setState(() => _selectedMember = value),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _notesController,
                  label: 'Notes / reason',
                  hint: 'Optional',
                  maxLines: 3,
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Confirm Receiver',
                  icon: Icons.lock_outline,
                  onPressed: cycle == null ? null : () => _confirm(kameti, cycle),
                ),
              ],
              const SizedBox(height: 18),
              Text('Eligible Receivers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              if (eligibility.eligibleMembers.isEmpty)
                const Text('No eligible receivers.')
              else
                ...eligibility.eligibleMembers.map((member) {
                  final payment = _paymentForMember(payments, cycle?.id ?? '', member.id);
                  return EligibleReceiverCard(member: member, paymentStatus: payment?.paymentStatus);
                }),
              const SizedBox(height: 18),
              Text('Excluded Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              if (eligibility.excludedMembers.isEmpty)
                const Text('No excluded members.')
              else
                ...eligibility.excludedMembers.map((member) {
                  return ExcludedReceiverCard(member: member, reason: eligibility.exclusionReasons[member.id] ?? '-');
                }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(KametiModel kameti, PaymentCycleModel cycle) async {
    if (!_formKey.currentState!.validate()) return;
    final member = _selectedMember;
    if (member == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ReceiverConfirmationDialog(member: member, amount: cycle.expectedAmount, cycleNumber: cycle.cycleNumber),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final error = ref.read(receiverControllerProvider.notifier).confirmReceiverAllocation(
          kameti: kameti,
          cycle: cycle,
          member: member,
          allocationType: widget.allocationType,
          amount: cycle.expectedAmount,
          selectedBy: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
          notes: _notesController.text.trim(),
        );
    if (error != null) {
      SnackbarHelper.showError(context, error);
      return;
    }
    ref.read(memberControllerProvider.notifier).markMemberReceived(
          memberId: member.id,
          cycleId: cycle.id,
          cycleNumber: cycle.cycleNumber,
          receivedAt: DateTime.now(),
          receivedAmount: cycle.expectedAmount,
          receivedVia: widget.allocationType.name,
        );
    ref.read(notificationControllerProvider.notifier).createNotification(
          ref.read(notificationControllerProvider.notifier).buildNotification(
                userId: ref.read(authControllerProvider).user?.id ?? 'mock-user',
                kametiId: kameti.id,
                cycleId: cycle.id,
                memberId: member.id,
                type: AppNotificationType.receiverConfirmed,
                title: 'Receiver Confirmed',
                message: '${member.fullName} will receive ${CurrencyFormatter.pkr(cycle.expectedAmount)} for Cycle ${cycle.cycleNumber}.',
                priority: NotificationPriority.high,
                actionType: NotificationActionType.openKameti,
                actionRoute: AppRoutes.kametiDetails,
              ),
        );
    if (mounted) {
      SnackbarHelper.showSuccess(context, 'Receiver confirmed successfully.');
      Navigator.of(context).pop();
    }
  }

  KametiModel? _findKameti(List<KametiModel> kametis, String id) {
    for (final kameti in kametis) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }

  MemberPaymentModel? _paymentForMember(List<MemberPaymentModel> payments, String cycleId, String memberId) {
    for (final payment in payments) {
      if (payment.cycleId == cycleId && payment.memberId == memberId) return payment;
    }
    return null;
  }
}
