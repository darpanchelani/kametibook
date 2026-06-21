import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../auth/providers/auth_controller.dart';
import '../../member/models/member_model.dart';
import '../../member/providers/member_controller.dart';
import '../../member/widgets/member_count_summary_card.dart';
import '../../member/widgets/member_role_badge.dart';
import '../../member/widgets/member_status_badge.dart';
import '../../payment/providers/payment_controller.dart';
import '../../payment/widgets/payment_summary_card.dart';
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
    final memberController = ref.read(memberControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final kameti = _findKameti(kametis, widget.kametiId);
    final selectedKameti = kameti;
    if (selectedKameti == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kameti Details')),
        body: const Center(child: Text('Kameti not found')),
      );
    }
    final members = memberController.getMembersByKametiId(selectedKameti.id);
    final activeMembersCount = memberController.getActiveMembersCount(selectedKameti.id);
    final remainingSlots = (selectedKameti.totalMembers - activeMembersCount).clamp(0, selectedKameti.totalMembers);
    final previewMembers = members.take(3).toList();
    final slotsFilled = activeMembersCount >= selectedKameti.totalMembers;
    final currentCycle = paymentController.getCurrentCycle(selectedKameti.id);

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
            ...['Ledger', 'Bidding', 'Lucky Draw', 'Reports'].map(
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
