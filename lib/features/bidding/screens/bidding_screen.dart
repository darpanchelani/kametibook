import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
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
import '../../notifications/models/notification_model.dart';
import '../../notifications/providers/notification_controller.dart';
import '../../payment/models/payment_models.dart';
import '../../payment/providers/payment_controller.dart';
import '../../receiver/providers/receiver_controller.dart';
import '../../payment/widgets/payment_summary_card.dart';
import '../../security/models/security_models.dart';
import '../../security/providers/security_controller.dart';
import '../models/bidding_models.dart';
import '../providers/bidding_controller.dart';
import '../widgets/bid_card.dart';
import '../widgets/bidding_result_preview_card.dart';
import '../widgets/bidding_settings_tile.dart';
import '../widgets/bidding_status_badge.dart';
import '../widgets/bidding_summary_card.dart';
import '../widgets/eligible_bidder_card.dart';
import '../widgets/excluded_bidder_card.dart';
import '../widgets/lowest_bid_card.dart';
import '../widgets/submit_bid_bottom_sheet.dart';

class BiddingScreen extends ConsumerWidget {
  const BiddingScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kameti = _findKameti(ref.watch(kametiControllerProvider), kametiId);
    ref.watch(memberControllerProvider);
    ref.watch(paymentControllerProvider);
    ref.watch(biddingControllerProvider);
    ref.watch(receiverControllerProvider);
    if (kameti == null) {
      return Scaffold(appBar: AppBar(title: const Text('Bidding')), body: const Center(child: Text('Kameti not found')));
    }

    final memberController = ref.read(memberControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final biddingController = ref.read(biddingControllerProvider.notifier);
    final cycle = paymentController.getCurrentCycle(kameti.id);
    final members = memberController.getMembersByKametiId(kameti.id);
    final activeMembers = members.where((member) => member.status == MemberStatus.active).toList();
    final payments = cycle == null ? <MemberPaymentModel>[] : paymentController.getPaymentsByCycleId(cycle.id);
    final eligibility = biddingController.getEligibleMembersForBidding(
      kameti: kameti,
      cycle: cycle,
      members: members,
      payments: payments,
    );
    final session = cycle == null ? null : biddingController.getBiddingSessionByCycleId(cycle.id);
    final bids = session == null ? <BidModel>[] : biddingController.getBidsBySessionId(session.id);
    final lowestBid = session == null ? null : biddingController.getLowestActiveBid(session.id);
    final availabilityError = biddingController.validateAvailability(kameti: kameti, cycle: cycle, eligibility: eligibility);
    final receivedCount = members.where((member) => member.hasReceivedKameti).length;
    final settingsEnabled = session == null || session.status != BiddingSessionStatus.completed;
    final completedPreview = session == null || session.status != BiddingSessionStatus.closed
        ? null
        : biddingController.buildCompletionPreview(session: session, activeMembers: activeMembers);

    return Scaffold(
      appBar: AppBar(title: const Text('Bidding')),
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
            BiddingSummaryCard(
              eligibleCount: eligibility.eligibleMembers.length,
              excludedCount: eligibility.excludedMembers.length,
              receivedCount: receivedCount,
              bidsCount: bids.where((bid) => bid.status == BidStatus.active).length,
              totalPoolAmount: kameti.monthlyAmount * activeMembers.length,
            ),
            BiddingSettingsTile(
              requirePayment: kameti.requirePaymentBeforeBidding,
              distributionType: kameti.discountDistributionType,
              enabled: settingsEnabled,
              onRequirePaymentChanged: (value) => ref.read(kametiControllerProvider.notifier).updateRequirePaymentBeforeBidding(kameti.id, value),
              onDistributionChanged: (value) => ref.read(kametiControllerProvider.notifier).updateDiscountDistributionType(kameti.id, value),
            ),
            const SizedBox(height: 8),
            const Text('Only active members who have not received kameti are eligible for bidding.'),
            if (kameti.requirePaymentBeforeBidding) const Text('Only members who paid for the current cycle can submit bids.'),
            const SizedBox(height: 12),
            if (session == null)
              AppButton(
                label: 'Start Bidding',
                icon: Icons.play_arrow,
                onPressed: availabilityError == null && cycle != null
                    ? () => _startBidding(context, ref, kameti, cycle, activeMembers.length)
                    : null,
              )
            else ...[
              Row(
                children: [
                  BiddingStatusBadge(status: session.status),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Total Pool: ${CurrencyFormatter.pkr(session.totalPoolAmount)}')),
                ],
              ),
              const SizedBox(height: 12),
              if (session.status == BiddingSessionStatus.completed)
                _CompletedBiddingCard(session: session, winner: memberController.getMember(session.winnerMemberId))
              else ...[
                LowestBidCard(bid: lowestBid),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: session.status == BiddingSessionStatus.open
                          ? () => _openSubmitBid(context, ref, session, eligibility, null)
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Submit Bid'),
                    ),
                    OutlinedButton(
                      onPressed: session.status == BiddingSessionStatus.open
                          ? () => _closeBidding(context, ref, session)
                          : null,
                      child: const Text('Close Bidding'),
                    ),
                  ],
                ),
                if (completedPreview != null) ...[
                  const SizedBox(height: 12),
                  BiddingResultPreviewCard(
                    preview: completedPreview,
                    totalPool: session.totalPoolAmount,
                    onComplete: () => _completeBidding(context, ref, session, activeMembers, completedPreview),
                  ),
                ],
              ],
            ],
            if (availabilityError != null && session == null) ...[
              const SizedBox(height: 8),
              Text(availabilityError, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 18),
            Text('Active Bids', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            if (bids.isEmpty)
              const Text('No bids submitted yet.')
            else
              ...bids.map((bid) => BidCard(
                    bid: bid,
                    member: memberController.getMember(bid.memberId),
                    canEdit: session?.status == BiddingSessionStatus.open && bid.status == BidStatus.active,
                    onEdit: () => _openSubmitBid(context, ref, session!, eligibility, bid),
                    onWithdraw: () => _withdrawBid(context, ref, bid),
                  )),
            const SizedBox(height: 18),
            Text('Eligible Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            if (eligibility.eligibleMembers.isEmpty)
              const Text('No eligible members available for bidding.')
            else
              ...eligibility.eligibleMembers.map((member) {
                final payment = _paymentForMember(payments, cycle?.id ?? '', member.id);
                return EligibleBidderCard(member: member, paymentStatus: payment?.paymentStatus);
              }),
            const SizedBox(height: 18),
            Text('Excluded Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            if (eligibility.excludedMembers.isEmpty)
              const Text('No excluded members.')
            else
              ...eligibility.excludedMembers.map((member) {
                return ExcludedBidderCard(member: member, reason: eligibility.exclusionReasons[member.id] ?? '-');
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _startBidding(BuildContext context, WidgetRef ref, KametiModel kameti, PaymentCycleModel cycle, int activeMembersCount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Start Bidding?',
        message: 'Eligible members will be able to submit bid amounts for this cycle.',
        confirmLabel: 'Start',
      ),
    );
    if (confirmed != true) return;
    final error = ref.read(biddingControllerProvider.notifier).createBiddingSession(
          kameti: kameti,
          cycle: cycle,
          activeMembersCount: activeMembersCount,
          createdBy: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
        );
    if (context.mounted) {
      error == null ? SnackbarHelper.showSuccess(context, 'Bidding started successfully.') : SnackbarHelper.showError(context, error);
    }
    if (error == null) {
      ref.read(notificationControllerProvider.notifier).createNotification(
            ref.read(notificationControllerProvider.notifier).buildNotification(
                  userId: ref.read(authControllerProvider).user?.id ?? 'mock-user',
                  kametiId: kameti.id,
                  cycleId: cycle.id,
                  type: AppNotificationType.biddingStarted,
                  title: 'Bidding Started',
                  message: 'Bidding has started for ${kameti.name} Cycle ${cycle.cycleNumber}.',
                  priority: NotificationPriority.high,
                  actionType: NotificationActionType.openBidding,
                  actionRoute: AppRoutes.bidding,
                ),
          );
      ref.read(securityControllerProvider.notifier).createAuditLog(
            kametiId: kameti.id,
            userId: ref.read(authControllerProvider).user?.id ?? 'mock-user',
            userName: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
            userRole: 'organizer',
            actionType: AuditActionType.biddingStarted,
            entityType: AuditEntityType.biddingSession,
            entityId: cycle.id,
            description: 'Bidding started for Cycle ${cycle.cycleNumber}.',
            severity: AuditSeverity.medium,
          );
    }
  }

  Future<void> _openSubmitBid(
    BuildContext context,
    WidgetRef ref,
    BiddingSessionModel session,
    BiddingEligibilityResult eligibility,
    BidModel? existingBid,
  ) async {
    final memberController = ref.read(memberControllerProvider.notifier);
    final initialMember = existingBid == null ? null : memberController.getMember(existingBid.memberId);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SubmitBidBottomSheet(
        members: eligibility.eligibleMembers,
        totalPoolAmount: session.totalPoolAmount,
        initialMember: initialMember,
        initialAmount: existingBid?.bidAmount,
        initialNote: existingBid?.note ?? '',
        onSubmit: (member, amount, note) {
          final error = existingBid == null
              ? ref.read(biddingControllerProvider.notifier).submitBid(
                    session: session,
                    member: member,
                    bidAmount: amount,
                    note: note,
                    eligibility: eligibility,
                  )
              : ref.read(biddingControllerProvider.notifier).updateBid(existingBid.id, amount, note);
          if (error == null) {
            Navigator.of(sheetContext).pop();
            SnackbarHelper.showSuccess(context, existingBid == null ? 'Bid submitted successfully.' : 'Bid updated successfully.');
          }
          return error;
        },
      ),
    );
  }

  Future<void> _closeBidding(BuildContext context, WidgetRef ref, BiddingSessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Close Bidding?',
        message: 'After closing, members cannot submit or update bids.',
        confirmLabel: 'Close',
      ),
    );
    if (confirmed != true) return;
    final error = ref.read(biddingControllerProvider.notifier).closeBiddingSession(session.id);
    if (context.mounted) {
      error == null ? SnackbarHelper.showSuccess(context, 'Bidding closed.') : SnackbarHelper.showError(context, error);
    }
    if (error == null) {
      ref.read(notificationControllerProvider.notifier).createNotification(
            ref.read(notificationControllerProvider.notifier).buildNotification(
                  userId: ref.read(authControllerProvider).user?.id ?? 'mock-user',
                  kametiId: session.kametiId,
                  cycleId: session.cycleId,
                  relatedBiddingSessionId: session.id,
                  type: AppNotificationType.biddingClosed,
                  title: 'Bidding Closed',
                  message: 'Bidding is closed. Please complete the result.',
                  priority: NotificationPriority.high,
                  actionType: NotificationActionType.openBidding,
                  actionRoute: AppRoutes.bidding,
                ),
          );
      ref.read(securityControllerProvider.notifier).createAuditLog(
            kametiId: session.kametiId,
            userId: ref.read(authControllerProvider).user?.id ?? 'mock-user',
            userName: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
            userRole: 'organizer',
            actionType: AuditActionType.biddingClosed,
            entityType: AuditEntityType.biddingSession,
            entityId: session.id,
            description: 'Bidding closed.',
            severity: AuditSeverity.medium,
          );
    }
  }

  Future<void> _completeBidding(
    BuildContext context,
    WidgetRef ref,
    BiddingSessionModel session,
    List<MemberModel> activeMembers,
    BiddingCompletionPreview preview,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Complete Bidding?',
        message: '${preview.winningBid.memberName} will receive ${CurrencyFormatter.pkr(preview.winningBid.bidAmount)}. This result will be locked and cannot be changed.',
        confirmLabel: 'Complete',
      ),
    );
    if (confirmed != true) return;
    final error = ref.read(biddingControllerProvider.notifier).completeBiddingSession(
          sessionId: session.id,
          activeMembers: activeMembers,
        );
    if (error != null) {
      if (context.mounted) SnackbarHelper.showError(context, error);
      return;
    }
    final winner = ref.read(memberControllerProvider.notifier).getMember(preview.winningBid.memberId);
    if (winner != null) {
      ref.read(receiverControllerProvider.notifier).createAllocationFromBiddingSession(
            kameti: _findKameti(ref.read(kametiControllerProvider), session.kametiId)!,
            cycle: ref.read(paymentControllerProvider.notifier).getCycle(session.cycleId)!,
            winner: winner,
            sessionId: session.id,
            amount: preview.winningBid.bidAmount,
            selectedBy: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
          );
    }
    ref.read(memberControllerProvider.notifier).markMemberReceived(
          memberId: preview.winningBid.memberId,
          cycleId: session.cycleId,
          cycleNumber: session.cycleNumber,
          receivedAt: DateTime.now(),
          receivedAmount: preview.winningBid.bidAmount,
          receivedVia: 'bidding',
        );
    ref.read(notificationControllerProvider.notifier).createNotification(
          ref.read(notificationControllerProvider.notifier).buildNotification(
                userId: ref.read(authControllerProvider).user?.id ?? 'mock-user',
                kametiId: session.kametiId,
                cycleId: session.cycleId,
                memberId: preview.winningBid.memberId,
                relatedBiddingSessionId: session.id,
                type: AppNotificationType.biddingCompleted,
                title: 'Bidding Completed',
                message: '${preview.winningBid.memberName} won bidding with ${CurrencyFormatter.pkr(preview.winningBid.bidAmount)}. Discount: ${CurrencyFormatter.pkr(preview.discountAmount)}.',
                priority: NotificationPriority.high,
                actionType: NotificationActionType.openBidding,
                actionRoute: AppRoutes.bidding,
              ),
        );
    ref.read(securityControllerProvider.notifier).createAuditLog(
          kametiId: session.kametiId,
          userId: ref.read(authControllerProvider).user?.id ?? 'mock-user',
          userName: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
          userRole: 'organizer',
          actionType: AuditActionType.biddingCompleted,
          entityType: AuditEntityType.biddingSession,
          entityId: session.id,
          newValue: preview.winningBid.memberId,
          description: '${preview.winningBid.memberName} won bidding with ${CurrencyFormatter.pkr(preview.winningBid.bidAmount)}.',
          severity: AuditSeverity.high,
        );
    if (context.mounted) SnackbarHelper.showSuccess(context, 'Bidding completed successfully.');
  }

  void _withdrawBid(BuildContext context, WidgetRef ref, BidModel bid) {
    final error = ref.read(biddingControllerProvider.notifier).withdrawBid(bid.id);
    error == null ? SnackbarHelper.showSuccess(context, 'Bid withdrawn.') : SnackbarHelper.showError(context, error);
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

class _CompletedBiddingCard extends StatelessWidget {
  const _CompletedBiddingCard({required this.session, required this.winner});

  final BiddingSessionModel session;
  final MemberModel? winner;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Winner: ${winner?.fullName ?? '-'}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            Text('Winning Bid: ${CurrencyFormatter.pkr(session.winningAmount)}'),
            Text('Discount: ${CurrencyFormatter.pkr(session.discountAmount)}'),
          ],
        ),
      ),
    );
  }
}
