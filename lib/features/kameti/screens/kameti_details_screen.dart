import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../auth/providers/auth_controller.dart';
import '../../bidding/models/bidding_models.dart';
import '../../bidding/providers/bidding_controller.dart';
import '../../bidding/widgets/bidding_status_badge.dart';
import '../../ledger/providers/ledger_controller.dart';
import '../../ledger/widgets/payout_paid_bottom_sheet.dart';
import '../../ledger/widgets/ledger_summary_card.dart';
import '../../member/models/member_model.dart';
import '../../member/providers/member_controller.dart';
import '../../member/widgets/member_count_summary_card.dart';
import '../../member/widgets/member_role_badge.dart';
import '../../member/widgets/member_status_badge.dart';
import '../../lucky_draw/providers/lucky_draw_controller.dart';
import '../../lucky_draw/widgets/winner_card.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/providers/notification_controller.dart';
import '../../notifications/widgets/alert_banner.dart';
import '../../payment/providers/payment_controller.dart';
import '../../payment/models/payment_models.dart';
import '../../payment/widgets/payment_summary_card.dart';
import '../../receiver/models/receiver_allocation_model.dart';
import '../../receiver/providers/receiver_controller.dart';
import '../../receiver/widgets/owner_first_info_card.dart';
import '../../receiver/widgets/receiver_allocation_card.dart';
import '../../security/models/security_models.dart';
import '../../security/providers/security_controller.dart';
import '../models/kameti_model.dart';
import '../providers/kameti_controller.dart';

class KametiDetailsScreen extends ConsumerStatefulWidget {
  const KametiDetailsScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  ConsumerState<KametiDetailsScreen> createState() => _KametiDetailsScreenState();
}

class _KametiDetailsScreenState extends ConsumerState<KametiDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureOrganizer());
  }

  void _ensureOrganizer() {
    final kameti = _findKameti(ref.read(kametiControllerProvider), widget.kametiId);
    if (kameti == null) return;
    ref.read(memberControllerProvider.notifier).ensureOrganizerMember(
          kameti: kameti,
          currentUser: ref.read(authControllerProvider).user,
        );
  }

  @override
  Widget build(BuildContext context) {
    final kametis = ref.watch(kametiControllerProvider);
    ref.watch(memberControllerProvider);
    ref.watch(paymentControllerProvider);
    ref.watch(luckyDrawControllerProvider);
    ref.watch(biddingControllerProvider);
    ref.watch(receiverControllerProvider);
    ref.watch(ledgerControllerProvider);
    ref.watch(notificationControllerProvider);
    ref.watch(securityControllerProvider);
    final memberController = ref.read(memberControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final drawController = ref.read(luckyDrawControllerProvider.notifier);
    final biddingController = ref.read(biddingControllerProvider.notifier);
    final receiverController = ref.read(receiverControllerProvider.notifier);
    final ledgerController = ref.read(ledgerControllerProvider.notifier);
    final kameti = _findKameti(kametis, widget.kametiId);
    final selectedKameti = kameti;
    if (selectedKameti == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kameti Details')),
        body: const Center(child: Text('Kameti not found')),
      );
    }
    final signedInUser = ref.watch(authControllerProvider).user;
    if (signedInUser == null ||
        !ref.read(kametiControllerProvider.notifier).canViewKameti(selectedKameti.id, signedInUser.id)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kameti Details')),
        body: const AppPermissionDeniedView(
          title: 'No access to this kameti',
          message: 'You can only view kametis where you are an approved organizer or member.',
        ),
      );
    }
    final members = memberController.getMembersByKametiId(selectedKameti.id);
    final activeMembersCount = memberController.getActiveMembersCount(selectedKameti.id);
    final remainingSlots = (selectedKameti.totalMembers - activeMembersCount).clamp(0, selectedKameti.totalMembers);
    final previewMembers = members.take(3).toList();
    final slotsFilled = activeMembersCount >= selectedKameti.totalMembers;
    final currentCycle = paymentController.getCurrentCycle(selectedKameti.id);
    final currentDraw = currentCycle == null ? null : drawController.getDrawByCycleId(currentCycle.id);
    final currentBidding = currentCycle == null ? null : biddingController.getBiddingSessionByCycleId(currentCycle.id);
    final lowestBid = currentBidding == null ? null : biddingController.getLowestActiveBid(currentBidding.id);
    final currentAllocation = currentCycle == null ? null : receiverController.getCurrentCycleAllocation(selectedKameti.id, currentCycle.id);
    final receivedCount = members.where((member) => member.hasReceivedKameti).length;
    final ledgerSummary = ledgerController.calculateGroupLedgerSummary(selectedKameti.id);
    final userId = signedInUser.id;
    final kametiAlerts = ref
        .read(notificationControllerProvider.notifier)
        .getNotificationsByKametiId(userId, selectedKameti.id)
        .where((item) => item.isUnread || item.priority == NotificationPriority.urgent)
        .length;
    final trustScores = members
        .map((member) => ref.read(securityControllerProvider.notifier).calculateMemberTrustScore(
              member: member,
              payments: ref.read(paymentControllerProvider).payments,
              ledgerEntries: ref.read(ledgerControllerProvider),
            ))
        .toList();
    final averageTrust = trustScores.isEmpty ? 0 : trustScores.fold<double>(0, (total, score) => total + score.overallScore) / trustScores.length;
    final riskyMembers = trustScores.where((score) => score.riskLevel == RiskLevel.risky || score.riskLevel == RiskLevel.highRisk).length;
    final excellentMembers = trustScores.where((score) => score.riskLevel == RiskLevel.excellent).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Kameti Details')),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedKameti.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Chip(label: Text(selectedKameti.status.label)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailLine(label: 'Kameti Type', value: selectedKameti.type.label),
                    _DetailLine(
                      label: 'Monthly Contribution',
                      value: CurrencyFormatter.pkr(selectedKameti.monthlyAmount),
                    ),
                    _DetailLine(label: 'Total Members', value: '${selectedKameti.totalMembers}'),
                    _DetailLine(label: 'Duration', value: '${selectedKameti.durationMonths} months'),
                    _DetailLine(label: 'Start Date', value: DateFormatter.display(selectedKameti.startDate)),
                    _DetailLine(label: 'Due Day', value: 'Day ${selectedKameti.dueDay}'),
                    _DetailLine(
                      label: 'Total Pool Amount',
                      value: CurrencyFormatter.pkr(selectedKameti.totalPoolAmount),
                    ),
                    _DetailLine(label: 'Organizer Name', value: selectedKameti.organizerName),
                    if (selectedKameti.description.isNotEmpty)
                      _DetailLine(label: 'Description / Rules', value: selectedKameti.description),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (kametiAlerts > 0)
              AlertBanner(
                title: '$kametiAlerts active alert(s)',
                message: 'Review payments, payout proof, receiver, bidding, draw, or ledger warnings.',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.kametiAlerts, arguments: selectedKameti.id),
              ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Alerts & Reminders', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('View kameti alerts or configure reminder settings.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.kametiAlerts, arguments: selectedKameti.id),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Security & Trust', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('Average Trust: ${averageTrust.round()}'),
                  Text('Risky Members: $riskyMembers'),
                  Text('Excellent Members: $excellentMembers'),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Open Security Center',
                    icon: Icons.security_outlined,
                    isOutlined: true,
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.securityCenter, arguments: selectedKameti.id),
                  ),
                ]),
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.reminderSettings, arguments: selectedKameti.id),
              icon: const Icon(Icons.alarm_outlined),
              label: const Text('Reminder Settings'),
            ),
            const SizedBox(height: 12),
            MemberCountSummaryCard(addedCount: activeMembersCount, totalCount: selectedKameti.totalMembers),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Members',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text('Remaining Slots: $remainingSlots'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (members.where((member) => member.role != MemberRole.organizer && member.status != MemberStatus.removed).isEmpty)
                      const Text('No members added yet.')
                    else
                      ...previewMembers.map((member) => _MemberPreview(member: member)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'View Members',
                            icon: Icons.groups_2_outlined,
                            isOutlined: true,
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.members, arguments: selectedKameti.id),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            label: slotsFilled ? 'Slots Filled' : 'Add Member',
                            icon: Icons.group_add_outlined,
                            onPressed: slotsFilled
                                ? null
                                : () => Navigator.of(context).pushNamed(AppRoutes.addMember, arguments: selectedKameti.id),
                          ),
                        ),
                      ],
                    ),
                    if (slotsFilled) ...[
                      const SizedBox(height: 10),
                      const Text('All member slots are filled.', style: TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (selectedKameti.status == KametiStatus.active && currentCycle != null) ...[
              PaymentSummaryCard(
                title: 'Current Cycle: Month ${currentCycle.cycleNumber} - ${currentCycle.monthLabel}',
                expectedAmount: currentCycle.expectedAmount,
                collectedAmount: currentCycle.collectedAmount,
                pendingAmount: currentCycle.pendingAmount,
                paidCount: paymentController.getPaidMembersCount(currentCycle.id),
                pendingCount: paymentController.getPendingMembersCount(currentCycle.id),
                lateCount: paymentController.getLateMembersCount(currentCycle.id),
                rejectedCount: paymentController.getRejectedMembersCount(currentCycle.id),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'View Payments',
                      icon: Icons.receipt_long_outlined,
                      isOutlined: true,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cyclePayments, arguments: currentCycle.id),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'View Cycles',
                      icon: Icons.calendar_month_outlined,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.paymentCycles, arguments: selectedKameti.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else if (selectedKameti.status == KametiStatus.active) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Payments'),
                  subtitle: const Text('No payment cycles generated yet.'),
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.paymentCycles, arguments: selectedKameti.id),
                    child: const Text('View'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Financial Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  LedgerSummaryCard(summary: ledgerSummary),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: AppButton(
                        label: 'View Ledger',
                        icon: Icons.menu_book_outlined,
                        isOutlined: true,
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.groupLedger, arguments: selectedKameti.id),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Financial Summary',
                        icon: Icons.summarize_outlined,
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.financialSummary, arguments: selectedKameti.id),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reports', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text('Generate monthly, full kameti, member, payment, payout, ledger, bidding, and lucky draw reports.'),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Open Reports',
                      icon: Icons.description_outlined,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.reportsDashboard, arguments: selectedKameti.id),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (selectedKameti.type == KametiType.luckyDraw) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lucky Draw', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      if (selectedKameti.status == KametiStatus.draft)
                        const Text('Start this kameti before running lucky draw.')
                      else if (currentCycle == null)
                        const Text('No active payment cycle found.')
                      else ...[
                        Text('Current Cycle: Month ${currentCycle.cycleNumber} - ${currentCycle.monthLabel}'),
                        Text('Draw Status: ${currentDraw == null ? 'Pending' : 'Completed'}'),
                        const Text('Eligible check uses active members and current cycle payment records.'),
                        Text('Already Received: $receivedCount'),
                        Text('Remaining Members: ${activeMembersCount - receivedCount}'),
                        if (currentDraw == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('Lucky draw pending for current cycle.'),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: WinnerCard(draw: currentDraw),
                          ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Open Lucky Draw',
                              icon: Icons.casino_outlined,
                              isOutlined: true,
                              onPressed: selectedKameti.status == KametiStatus.active
                                  ? () => Navigator.of(context).pushNamed(AppRoutes.luckyDraw, arguments: selectedKameti.id)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              label: 'Draw History',
                              icon: Icons.history_outlined,
                              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.drawHistory, arguments: selectedKameti.id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Card(
                child: ListTile(
                  leading: Icon(Icons.casino_outlined),
                  title: Text('Lucky Draw'),
                  subtitle: Text('Lucky draw is only available for Khulli Chhutti kametis.'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (selectedKameti.type == KametiType.bidding) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bidding', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      if (selectedKameti.status == KametiStatus.draft)
                        const Text('Start this kameti before running bidding.')
                      else if (currentCycle == null)
                        const Text('No active payment cycle found.')
                      else ...[
                        Text('Current Cycle: Month ${currentCycle.cycleNumber} - ${currentCycle.monthLabel}'),
                        if (currentBidding == null)
                          const Text('Bidding has not started for current cycle.')
                        else ...[
                          Row(children: [
                            BiddingStatusBadge(status: currentBidding.status),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Total Pool: ${CurrencyFormatter.pkr(currentBidding.totalPoolAmount)}')),
                          ]),
                          Text('Total Bids Submitted: ${biddingController.getBidsBySessionId(currentBidding.id).where((bid) => bid.status == BidStatus.active).length}'),
                          if (lowestBid != null) Text('Lowest Bid: ${CurrencyFormatter.pkr(lowestBid.bidAmount)} by ${lowestBid.memberName}'),
                          if (currentBidding.status == BiddingSessionStatus.completed) ...[
                            Text('Winner: ${memberController.getMember(currentBidding.winnerMemberId)?.fullName ?? '-'}'),
                            Text('Winning Bid: ${CurrencyFormatter.pkr(currentBidding.winningAmount)}'),
                            Text('Discount: ${CurrencyFormatter.pkr(currentBidding.discountAmount)}'),
                          ],
                        ],
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Open Bidding',
                              icon: Icons.gavel_outlined,
                              isOutlined: true,
                              onPressed: selectedKameti.status == KametiStatus.active
                                  ? () => Navigator.of(context).pushNamed(AppRoutes.bidding, arguments: selectedKameti.id)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              label: 'Bidding History',
                              icon: Icons.history_outlined,
                              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.biddingHistory, arguments: selectedKameti.id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Card(
                child: ListTile(
                  leading: Icon(Icons.gavel_outlined),
                  title: Text('Bidding'),
                  subtitle: Text('Bidding is only available for auction kametis.'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receiver / Kameti lene wala', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    if (currentCycle == null)
                      const Text('No active payment cycle found.')
                    else if (currentAllocation != null)
                      ReceiverAllocationCard(
                        allocation: currentAllocation,
                        onMarkPayoutPaid: () => _markPayoutPaid(context, ref, currentAllocation),
                      )
                    else ...[
                      Text('Current Cycle: Month ${currentCycle.cycleNumber}'),
                      const Text('Receiver not selected for current cycle.'),
                      const SizedBox(height: 12),
                      _ReceiverActions(
                        kameti: selectedKameti,
                        cycleId: currentCycle.id,
                        cycleNumber: currentCycle.cycleNumber,
                        onOwnerFirst: () => _confirmOwnerFirst(context, ref, selectedKameti, currentCycle),
                        onFixedOrder: () => _confirmFixedOrder(context, ref, selectedKameti, currentCycle),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Start Kameti',
                    icon: Icons.play_arrow,
                    onPressed: selectedKameti.status == KametiStatus.draft
                        ? () => _confirmStart(context, ref, selectedKameti)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Future Modules',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...['Notifications'].map(
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

  Future<void> _confirmStart(BuildContext context, WidgetRef ref, KametiModel kameti) async {
    final startCheck = ref.read(memberControllerProvider.notifier).canStartKameti(kameti);
    if (!startCheck.canStart) {
      SnackbarHelper.showError(
        context,
        startCheck.message ?? 'Please add all required members before starting this kameti.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Start Kameti?',
        message: 'Once started, members cannot be removed and monthly payment cycles will be created.',
        confirmLabel: 'Start',
      ),
    );
    if (confirmed != true) return;
    ref.read(kametiControllerProvider.notifier).updateStatus(kameti.id, KametiStatus.active);
    final activeKameti = kameti.copyWith(status: KametiStatus.active);
    final members = ref.read(memberControllerProvider.notifier).getMembersByKametiId(kameti.id);
    ref.read(paymentControllerProvider.notifier).generatePaymentCycles(
          kameti: activeKameti,
          members: members,
        );
    ref.read(notificationControllerProvider.notifier).createKametiStartedNotification(
          userId: ref.read(authControllerProvider).user?.id ?? '',
          kameti: kameti,
        );
    ref.read(securityControllerProvider.notifier).createAuditLog(
          kametiId: kameti.id,
          userId: ref.read(authControllerProvider).user?.id ?? '',
          userName: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
          userRole: 'organizer',
          actionType: AuditActionType.kametiStarted,
          entityType: AuditEntityType.kameti,
          entityId: kameti.id,
          oldValue: KametiStatus.draft.name,
          newValue: KametiStatus.active.name,
          description: 'Kameti started and payment cycles generated.',
          severity: AuditSeverity.high,
        );
    ref.read(notificationControllerProvider.notifier).generateScheduledRemindersForKameti(
          userId: ref.read(authControllerProvider).user?.id ?? '',
          kameti: activeKameti,
          cycles: ref.read(paymentControllerProvider).cycles,
          payments: ref.read(paymentControllerProvider).payments,
          members: members,
        );
    if (context.mounted) {
      SnackbarHelper.showSuccess(context, 'Kameti started successfully.');
    }
  }

  KametiModel? _findKameti(List<KametiModel> kametis, String id) {
    for (final kameti in kametis) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }

  Future<void> _confirmOwnerFirst(BuildContext context, WidgetRef ref, KametiModel kameti, dynamic cycle) async {
    MemberModel? organizer;
    for (final member in ref.read(memberControllerProvider.notifier).getMembersByKametiId(kameti.id)) {
      if (member.role == MemberRole.organizer) {
        organizer = member;
        break;
      }
    }
    if (organizer == null) {
      SnackbarHelper.showError(context, 'Organizer member not found.');
      return;
    }
    final error = ref.read(receiverControllerProvider.notifier).confirmReceiverAllocation(
          kameti: kameti,
          cycle: cycle,
          member: organizer,
          allocationType: ReceiverAllocationType.ownerFirst,
          amount: cycle.expectedAmount,
          selectedBy: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
        );
    if (error != null) {
      SnackbarHelper.showError(context, error);
      return;
    }
    ref.read(memberControllerProvider.notifier).markMemberReceived(
          memberId: organizer.id,
          cycleId: cycle.id,
          cycleNumber: cycle.cycleNumber,
          receivedAt: DateTime.now(),
          receivedAmount: cycle.expectedAmount,
          receivedVia: ReceiverAllocationType.ownerFirst.name,
        );
    ref.read(notificationControllerProvider.notifier).createNotification(
          ref.read(notificationControllerProvider.notifier).buildNotification(
                userId: ref.read(authControllerProvider).user?.id ?? '',
                kametiId: kameti.id,
                cycleId: cycle.id,
                memberId: organizer.id,
                type: AppNotificationType.receiverConfirmed,
                title: 'Receiver Confirmed',
                message: '${organizer.fullName} will receive ${CurrencyFormatter.pkr(cycle.expectedAmount)} for Cycle ${cycle.cycleNumber}.',
                priority: NotificationPriority.high,
                actionType: NotificationActionType.openKameti,
                actionRoute: AppRoutes.kametiDetails,
              ),
        );
    ref.read(securityControllerProvider.notifier).createAuditLog(
          kametiId: kameti.id,
          userId: ref.read(authControllerProvider).user?.id ?? '',
          userName: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
          userRole: 'organizer',
          actionType: AuditActionType.receiverConfirmed,
          entityType: AuditEntityType.receiverAllocation,
          entityId: cycle.id,
          newValue: organizer.id,
          description: 'Organizer confirmed as receiver.',
          severity: AuditSeverity.high,
        );
    SnackbarHelper.showSuccess(context, 'Organizer confirmed as receiver.');
  }

  Future<void> _confirmFixedOrder(BuildContext context, WidgetRef ref, KametiModel kameti, dynamic cycle) async {
    final slot = ref.read(receiverControllerProvider.notifier).getFixedOrderSlot(kameti.id, cycle.cycleNumber);
    if (slot == null) {
      SnackbarHelper.showError(context, 'Fixed order is not set yet.');
      return;
    }
    final member = ref.read(memberControllerProvider.notifier).getMember(slot.memberId);
    if (member == null) {
      SnackbarHelper.showError(context, 'Scheduled receiver not found.');
      return;
    }
    final error = ref.read(receiverControllerProvider.notifier).confirmReceiverAllocation(
          kameti: kameti,
          cycle: cycle,
          member: member,
          allocationType: ReceiverAllocationType.fixedOrder,
          amount: cycle.expectedAmount,
          selectedBy: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
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
          receivedVia: ReceiverAllocationType.fixedOrder.name,
        );
    ref.read(notificationControllerProvider.notifier).createNotification(
          ref.read(notificationControllerProvider.notifier).buildNotification(
                userId: ref.read(authControllerProvider).user?.id ?? '',
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
    ref.read(securityControllerProvider.notifier).createAuditLog(
          kametiId: kameti.id,
          userId: ref.read(authControllerProvider).user?.id ?? '',
          userName: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
          userRole: 'organizer',
          actionType: AuditActionType.receiverConfirmed,
          entityType: AuditEntityType.receiverAllocation,
          entityId: cycle.id,
          newValue: member.id,
          description: 'Fixed order receiver confirmed.',
          severity: AuditSeverity.high,
        );
    SnackbarHelper.showSuccess(context, 'Receiver confirmed successfully.');
  }

  Future<void> _markPayoutPaid(BuildContext context, WidgetRef ref, ReceiverAllocationModel allocation) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => PayoutPaidBottomSheet(
        allocation: allocation,
        onSubmit: (data) {
          ref.read(receiverControllerProvider.notifier).markPayoutPaid(
                allocationId: allocation.id,
                method: data.method,
                proofPath: data.proofPath,
                note: data.note,
                paidAt: data.paidAt,
                confirmedBy: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
              );
          ref.read(ledgerControllerProvider.notifier).markPayoutLedgerPaid(
                allocation: allocation,
                method: _payoutMethodToPaymentMethod(data.method),
                proofPath: data.proofPath,
                note: data.note,
                paidAt: data.paidAt,
              );
          ref.read(notificationControllerProvider.notifier).createNotification(
                ref.read(notificationControllerProvider.notifier).buildNotification(
                      userId: ref.read(authControllerProvider).user?.id ?? '',
                      kametiId: allocation.kametiId,
                      cycleId: allocation.cycleId,
                      memberId: allocation.memberId,
                      relatedAllocationId: allocation.id,
                      type: AppNotificationType.payoutPaid,
                      title: 'Payout Paid',
                      message: 'Payout of ${CurrencyFormatter.pkr(allocation.amount)} has been marked paid to ${allocation.memberName}.',
                      priority: NotificationPriority.high,
                      actionType: NotificationActionType.openKameti,
                      actionRoute: AppRoutes.kametiDetails,
                    ),
              );
          ref.read(securityControllerProvider.notifier).createAuditLog(
                kametiId: allocation.kametiId,
                userId: ref.read(authControllerProvider).user?.id ?? '',
                userName: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
                userRole: 'organizer',
                actionType: AuditActionType.payoutMarkedPaid,
                entityType: AuditEntityType.payout,
                entityId: allocation.id,
                description: 'Payout marked paid.',
                severity: AuditSeverity.high,
              );
          Navigator.of(sheetContext).pop();
          SnackbarHelper.showSuccess(context, 'Payout marked as paid.');
        },
      ),
    );
  }

  PaymentMethod _payoutMethodToPaymentMethod(PayoutMethod method) {
    return switch (method) {
      PayoutMethod.cash => PaymentMethod.cash,
      PayoutMethod.bankTransfer => PaymentMethod.bankTransfer,
      PayoutMethod.easypaisa => PaymentMethod.easypaisa,
      PayoutMethod.jazzcash => PaymentMethod.jazzcash,
      PayoutMethod.sadapay => PaymentMethod.sadapay,
      PayoutMethod.nayapay => PaymentMethod.nayapay,
      PayoutMethod.other => PaymentMethod.other,
    };
  }
}

class _ReceiverActions extends StatelessWidget {
  const _ReceiverActions({
    required this.kameti,
    required this.cycleId,
    required this.cycleNumber,
    required this.onOwnerFirst,
    required this.onFixedOrder,
  });

  final KametiModel kameti;
  final String cycleId;
  final int cycleNumber;
  final VoidCallback onOwnerFirst;
  final VoidCallback onFixedOrder;

  @override
  Widget build(BuildContext context) {
    if (kameti.type == KametiType.ownerFirst && cycleNumber == 1 && kameti.ownerReceivesFirstCycle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OwnerFirstInfoCard(message: 'Organizer is scheduled to receive first kameti.'),
          AppButton(label: 'Confirm Organizer as Receiver', icon: Icons.lock_outline, onPressed: onOwnerFirst),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ownerFirstSettings, arguments: kameti.id),
            child: const Text('Owner First Settings'),
          ),
        ],
      );
    }
    if (kameti.type == KametiType.fixedOrder ||
        (kameti.type == KametiType.ownerFirst && kameti.afterOwnerAllocationMode == AfterOwnerAllocationMode.fixedOrder)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: 'Set Fixed Order',
            icon: Icons.format_list_numbered_outlined,
            isOutlined: true,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.fixedOrderSetup, arguments: kameti.id),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Confirm Fixed Order Receiver',
            icon: Icons.lock_outline,
            onPressed: onFixedOrder,
          ),
        ],
      );
    }
    final allocationType = kameti.type == KametiType.mutualDecision ||
            (kameti.type == KametiType.ownerFirst && kameti.afterOwnerAllocationMode == AfterOwnerAllocationMode.mutualDecision)
        ? ReceiverAllocationType.mutualDecision
        : ReceiverAllocationType.manual;
    return AppButton(
      label: kameti.type == KametiType.mutualDecision ? 'Select Receiver' : 'Manual Receiver Selection',
      icon: Icons.person_search_outlined,
      onPressed: () => Navigator.of(context).pushNamed(
        AppRoutes.manualReceiver,
        arguments: {'kametiId': kameti.id, 'allocationType': allocationType},
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _MemberPreview extends StatelessWidget {
  const _MemberPreview({required this.member});

  final MemberModel member;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(member.phone, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          MemberRoleBadge(role: member.role),
          const SizedBox(width: 6),
          MemberStatusBadge(status: member.status),
        ],
      ),
    );
  }
}
