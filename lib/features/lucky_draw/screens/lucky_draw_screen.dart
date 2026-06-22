import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../auth/providers/auth_controller.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../member/models/member_model.dart';
import '../../member/providers/member_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../../payment/models/payment_models.dart';
import '../../receiver/models/receiver_allocation_model.dart';
import '../../receiver/providers/receiver_controller.dart';
import '../../payment/widgets/payment_summary_card.dart';
import '../models/lucky_draw_model.dart';
import '../providers/lucky_draw_controller.dart';
import '../widgets/animated_name_selector.dart';
import '../widgets/draw_settings_tile.dart';
import '../widgets/draw_result_dialog.dart';
import '../widgets/eligible_member_card.dart';
import '../widgets/excluded_member_card.dart';
import '../widgets/lucky_draw_summary_card.dart';
import '../widgets/winner_card.dart';

class LuckyDrawScreen extends ConsumerStatefulWidget {
  const LuckyDrawScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  ConsumerState<LuckyDrawScreen> createState() => _LuckyDrawScreenState();
}

class _LuckyDrawScreenState extends ConsumerState<LuckyDrawScreen> {
  MemberModel? _drawnWinner;
  bool _isAnimating = false;
  bool _canSave = false;

  @override
  Widget build(BuildContext context) {
    final kameti = _findKameti(ref.watch(kametiControllerProvider), widget.kametiId);
    ref.watch(memberControllerProvider);
    ref.watch(paymentControllerProvider);
    ref.watch(luckyDrawControllerProvider);
    ref.watch(receiverControllerProvider);
    if (kameti == null) {
      return Scaffold(appBar: AppBar(title: const Text('Lucky Draw')), body: const Center(child: Text('Kameti not found')));
    }

    final memberController = ref.read(memberControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final drawController = ref.read(luckyDrawControllerProvider.notifier);
    final cycle = paymentController.getCurrentCycle(kameti.id);
    final members = memberController.getMembersByKametiId(kameti.id);
    final payments = cycle == null ? <MemberPaymentModel>[] : paymentController.getPaymentsByCycleId(cycle.id);
    final eligibility = drawController.getEligibleMembersForDraw(
      kameti: kameti,
      cycle: cycle,
      members: members,
      payments: payments,
    );
    final completedDraw = cycle == null ? null : drawController.getDrawByCycleId(cycle.id);
    final availabilityError = drawController.validateDrawAvailability(kameti: kameti, cycle: cycle, eligibility: eligibility);
    final alreadyReceived = members.where((member) => member.hasReceivedKameti).length;
    final remainingDraws = members.where((member) => member.status == MemberStatus.active && !member.hasReceivedKameti).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Lucky Draw')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(kameti.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(cycle == null ? 'No active payment cycle found.' : 'Month ${cycle.cycleNumber} - ${cycle.monthLabel}'),
            if (cycle != null) Text('Due Date: ${DateFormatter.display(cycle.dueDate)}'),
            const SizedBox(height: 12),
            if (cycle != null)
              PaymentSummaryCard(
                title: 'Payment Progress',
                expectedAmount: cycle.expectedAmount,
                collectedAmount: cycle.collectedAmount,
                pendingAmount: cycle.pendingAmount,
                paidCount: paymentController.getPaidMembersCount(cycle.id),
                pendingCount: paymentController.getPendingMembersCount(cycle.id),
                lateCount: paymentController.getLateMembersCount(cycle.id),
                rejectedCount: paymentController.getRejectedMembersCount(cycle.id),
              ),
            LuckyDrawSummaryCard(
              eligibleCount: eligibility.eligibleMembers.length,
              excludedCount: eligibility.excludedMembers.length,
              alreadyReceivedCount: alreadyReceived,
              remainingDraws: remainingDraws,
            ),
            DrawSettingsTile(
              value: kameti.requirePaymentBeforeDraw,
              enabled: completedDraw == null,
              onChanged: (value) => ref.read(kametiControllerProvider.notifier).updateRequirePaymentBeforeDraw(kameti.id, value),
            ),
            const SizedBox(height: 8),
            const Text('Only active members who have not received kameti are included in the draw.'),
            if (kameti.requirePaymentBeforeDraw)
              const Text('Only members who paid for the current cycle are eligible.'),
            const SizedBox(height: 12),
            if (completedDraw != null) ...[
              WinnerCard(draw: completedDraw),
              AppButton(
                label: 'Report Issue',
                isOutlined: true,
                onPressed: () => SnackbarHelper.showInfo(context, 'Dispute handling will be available in future phases.'),
              ),
            ] else if (_isAnimating && _drawnWinner != null)
              AnimatedNameSelector(
                members: eligibility.eligibleMembers,
                winner: _drawnWinner!,
                onFinished: () => _showResultDialog(kameti, cycle!, eligibility, _drawnWinner!),
              )
            else if (_canSave && _drawnWinner != null)
              _PendingWinnerCard(
                winner: _drawnWinner!,
                amount: cycle?.expectedAmount ?? 0,
                cycleNumber: cycle?.cycleNumber ?? 0,
                onSave: () => _saveResult(kameti, cycle!, eligibility, _drawnWinner!),
              )
            else
              AppButton(
                label: 'Start Lucky Draw',
                icon: Icons.casino_outlined,
                onPressed: availabilityError == null ? () => _startDraw(kameti, cycle!, eligibility) : null,
              ),
            if (availabilityError != null && completedDraw == null) ...[
              const SizedBox(height: 8),
              Text(availabilityError, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 18),
            Text('Eligible Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (eligibility.eligibleMembers.isEmpty)
              const Text('No eligible members available for draw.')
            else
              ...eligibility.eligibleMembers.map((member) {
                MemberPaymentModel? payment;
                if (cycle != null) {
                  for (final item in paymentController.getPaymentsByCycleId(cycle.id)) {
                    if (item.memberId == member.id) {
                      payment = item;
                      break;
                    }
                  }
                }
                return EligibleMemberCard(member: member, paymentStatus: payment?.paymentStatus);
              }),
            const SizedBox(height: 18),
            Text('Excluded Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (eligibility.excludedMembers.isEmpty)
              const Text('No excluded members.')
            else
              ...eligibility.excludedMembers.map(
                (member) => ExcludedMemberCard(member: member, reason: eligibility.exclusionReasons[member.id] ?? '-'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDraw(KametiModel kameti, PaymentCycleModel cycle, DrawEligibilityResult eligibility) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Start Lucky Draw?',
        message: 'This will randomly select one eligible member as the receiver for this cycle. Result cannot be changed after confirmation.',
        confirmLabel: 'Start Draw',
      ),
    );
    if (confirmed != true) return;
    final winner = ref.read(luckyDrawControllerProvider.notifier).runLuckyDraw(kameti: kameti, cycle: cycle, eligibility: eligibility);
    if (winner == null) return;
    setState(() {
      _drawnWinner = winner;
      _isAnimating = true;
      _canSave = false;
    });
  }

  void _saveResult(KametiModel kameti, PaymentCycleModel cycle, DrawEligibilityResult eligibility, MemberModel winner) {
    final error = ref.read(luckyDrawControllerProvider.notifier).saveLuckyDrawResult(
          kameti: kameti,
          cycle: cycle,
          winner: winner,
          eligibility: eligibility,
          createdBy: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
        );
    if (error != null) {
      SnackbarHelper.showError(context, error);
      return;
    }
    ref.read(receiverControllerProvider.notifier).createAllocationFromLuckyDraw(
          kameti: kameti,
          cycle: cycle,
          winner: winner,
          drawId: '${cycle.id}-draw',
          amount: cycle.expectedAmount,
          selectedBy: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
        );
    ref.read(memberControllerProvider.notifier).markMemberReceived(
          memberId: winner.id,
          cycleId: cycle.id,
          cycleNumber: cycle.cycleNumber,
          receivedAt: DateTime.now(),
          receivedAmount: cycle.expectedAmount,
          receivedVia: ReceiverAllocationType.luckyDraw.name,
        );
    setState(() {
      _drawnWinner = null;
      _canSave = false;
      _isAnimating = false;
    });
    SnackbarHelper.showSuccess(context, 'Lucky draw result saved successfully.');
  }

  void _showResultDialog(
    KametiModel kameti,
    PaymentCycleModel cycle,
    DrawEligibilityResult eligibility,
    MemberModel winner,
  ) {
    setState(() {
      _isAnimating = false;
      _canSave = true;
    });
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DrawResultDialog(
        winner: winner,
        amount: cycle.expectedAmount,
        cycleNumber: cycle.cycleNumber,
        onSave: () => _saveResult(kameti, cycle, eligibility, winner),
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

class _PendingWinnerCard extends StatelessWidget {
  const _PendingWinnerCard({
    required this.winner,
    required this.amount,
    required this.cycleNumber,
    required this.onSave,
  });

  final MemberModel winner;
  final double amount;
  final int cycleNumber;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Congratulations!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('${winner.fullName} has won the kameti for Month $cycleNumber.'),
            Text('Amount: ${CurrencyFormatter.pkr(amount)}'),
            Text('Draw Date: ${DateFormatter.display(DateTime.now())}'),
            const SizedBox(height: 14),
            AppButton(label: 'Save Result', icon: Icons.save_outlined, onPressed: onSave),
          ],
        ),
      ),
    );
  }
}
