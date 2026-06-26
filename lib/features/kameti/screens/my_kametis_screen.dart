import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/app_state_views.dart';
import '../models/kameti_model.dart';
import '../../auth/providers/auth_controller.dart';
import '../../member/models/member_model.dart';
import '../../member/providers/member_controller.dart';
import '../../lucky_draw/providers/lucky_draw_controller.dart';
import '../../bidding/models/bidding_models.dart';
import '../../bidding/providers/bidding_controller.dart';
import '../../ledger/providers/ledger_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../../receiver/providers/receiver_controller.dart';
import '../providers/kameti_controller.dart';
import '../widgets/kameti_card.dart';

enum _KametiListFilter {
  all('All'),
  organized('Organized'),
  joined('Joined'),
  active('Active'),
  draft('Draft');

  const _KametiListFilter(this.label);
  final String label;
}

class MyKametisScreen extends ConsumerStatefulWidget {
  const MyKametisScreen({super.key});

  @override
  ConsumerState<MyKametisScreen> createState() => _MyKametisScreenState();
}

class _MyKametisScreenState extends ConsumerState<MyKametisScreen> {
  _KametiListFilter _filter = _KametiListFilter.all;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) {
      return const Scaffold(
        body: AppPermissionDeniedView(
          title: 'Login required',
          message: 'Please login with an active KametiBook account.',
        ),
      );
    }
    ref.watch(kametiControllerProvider);
    final kametis =
        ref.read(kametiControllerProvider.notifier).visibleToUser(user.id);
    ref.watch(memberControllerProvider);
    ref.watch(paymentControllerProvider);
    ref.watch(luckyDrawControllerProvider);
    ref.watch(biddingControllerProvider);
    ref.watch(receiverControllerProvider);
    ref.watch(ledgerControllerProvider);
    final memberController = ref.read(memberControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final drawController = ref.read(luckyDrawControllerProvider.notifier);
    final biddingController = ref.read(biddingControllerProvider.notifier);
    final receiverController = ref.read(receiverControllerProvider.notifier);
    final ledgerController = ref.read(ledgerControllerProvider.notifier);
    final filteredKametis = _filterKametis(kametis, user.id);
    final organizedCount =
        kametis.where((kameti) => kameti.ownerUserId == user.id).length;
    final joinedCount =
        kametis.where((kameti) => kameti.ownerUserId != user.id).length;

    return Scaffold(
      appBar: AppBar(title: const Text('My Kametis')),
      body: SafeArea(
        child: kametis.isEmpty
            ? EmptyState(
                icon: Icons.groups_2_outlined,
                title:
                    'No kametis yet. Create your own kameti or ask an organizer to add your account.',
                action: AppButton(
                  label: 'Create Kameti',
                  icon: Icons.add,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.createKameti),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount:
                    filteredKametis.isEmpty ? 3 : filteredKametis.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _KametiListSummary(
                      totalCount: kametis.length,
                      organizedCount: organizedCount,
                      joinedCount: joinedCount,
                    );
                  }
                  if (index == 1) {
                    return _KametiFilterChips(
                      selected: _filter,
                      onChanged: (value) => setState(() => _filter = value),
                    );
                  }
                  if (filteredKametis.isEmpty) {
                    return _FilteredEmptyState(filter: _filter);
                  }

                  final kameti = filteredKametis[index - 2];
                  final cycle = paymentController.getCurrentCycle(kameti.id);
                  final draw = cycle == null
                      ? null
                      : drawController.getDrawByCycleId(cycle.id);
                  final bidding = cycle == null
                      ? null
                      : biddingController.getBiddingSessionByCycleId(cycle.id);
                  final lowestBid = bidding == null
                      ? null
                      : biddingController.getLowestActiveBid(bidding.id);
                  final allocation = cycle == null
                      ? null
                      : receiverController.getCurrentCycleAllocation(
                          kameti.id, cycle.id);
                  final balance = ledgerController
                      .calculateGroupLedgerSummary(kameti.id)
                      .groupBalance;
                  final roleInfo = _roleInfoFor(
                    userId: user.id,
                    kameti: kameti,
                    members: memberController.getMembersByKametiId(kameti.id),
                  );
                  return KametiCard(
                    kameti: kameti,
                    roleLabel: roleInfo.label,
                    roleIcon: roleInfo.icon,
                    activeMembersCount:
                        memberController.getActiveMembersCount(kameti.id),
                    currentCycleLabel:
                        cycle == null ? null : 'Month ${cycle.cycleNumber}',
                    paidCount: cycle == null
                        ? null
                        : paymentController.getPaidMembersCount(cycle.id),
                    pendingCount: cycle == null
                        ? null
                        : paymentController.getPendingMembersCount(cycle.id),
                    collectedAmount: cycle?.collectedAmount,
                    expectedAmount: cycle?.expectedAmount,
                    drawStatusText:
                        kameti.type == KametiType.luckyDraw && cycle != null
                            ? draw == null
                                ? 'Draw: Pending'
                                : 'Winner: ${draw.winnerName}'
                            : null,
                    biddingStatusText: kameti.type == KametiType.bidding &&
                            cycle != null
                        ? bidding == null
                            ? 'Bidding: Not Started'
                            : bidding.status == BiddingSessionStatus.completed
                                ? 'Winner: ${biddingController.getBidsBySessionId(bidding.id).where((bid) => bid.id == bidding.winningBidId).map((bid) => bid.memberName).join()} | Discount: ${bidding.discountAmount.toStringAsFixed(0)}'
                                : lowestBid == null
                                    ? 'Bidding: ${bidding.status.label}'
                                    : 'Bidding: ${bidding.status.label} | Lowest: ${lowestBid.bidAmount.toStringAsFixed(0)}'
                        : null,
                    receiverStatusText: cycle == null
                        ? null
                        : allocation == null
                            ? 'Receiver: Pending'
                            : 'Receiver: ${allocation.memberName} | Payout: ${allocation.payoutStatus.label} | Balance: ${balance.toStringAsFixed(0)}',
                    onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.kametiDetails,
                        arguments: kameti.id),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
              ),
      ),
      floatingActionButton: kametis.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.createKameti),
              child: const Icon(Icons.add),
            ),
    );
  }

  List<KametiModel> _filterKametis(
    List<KametiModel> kametis,
    String userId,
  ) {
    return switch (_filter) {
      _KametiListFilter.all => kametis,
      _KametiListFilter.organized =>
        kametis.where((kameti) => kameti.ownerUserId == userId).toList(),
      _KametiListFilter.joined =>
        kametis.where((kameti) => kameti.ownerUserId != userId).toList(),
      _KametiListFilter.active => kametis
          .where((kameti) => kameti.status == KametiStatus.active)
          .toList(),
      _KametiListFilter.draft =>
        kametis.where((kameti) => kameti.status == KametiStatus.draft).toList(),
    };
  }

  _KametiRoleInfo _roleInfoFor({
    required String userId,
    required KametiModel kameti,
    required List<MemberModel> members,
  }) {
    if (kameti.ownerUserId == userId) {
      return const _KametiRoleInfo(
        label: 'Organizer',
        icon: Icons.admin_panel_settings_outlined,
      );
    }

    for (final member in members) {
      if (member.userId == userId || member.id == userId) {
        return _KametiRoleInfo(
          label: member.role == MemberRole.coOrganizer
              ? 'Co-Organizer'
              : 'Joined Member',
          icon: member.role == MemberRole.coOrganizer
              ? Icons.manage_accounts_outlined
              : Icons.group_outlined,
        );
      }
    }

    return const _KametiRoleInfo(
      label: 'Joined Member',
      icon: Icons.group_outlined,
    );
  }
}

class _KametiRoleInfo {
  const _KametiRoleInfo({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _KametiListSummary extends StatelessWidget {
  const _KametiListSummary({
    required this.totalCount,
    required this.organizedCount,
    required this.joinedCount,
  });

  final int totalCount;
  final int organizedCount;
  final int joinedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC9E5DA)),
      ),
      child: Row(
        children: [
          Expanded(child: _SummaryItem(label: 'All', value: totalCount)),
          Expanded(
              child: _SummaryItem(label: 'Organized', value: organizedCount)),
          Expanded(child: _SummaryItem(label: 'Joined', value: joinedCount)),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF26352F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _KametiFilterChips extends StatelessWidget {
  const _KametiFilterChips({
    required this.selected,
    required this.onChanged,
  });

  final _KametiListFilter selected;
  final ValueChanged<_KametiListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const textColor = Color(0xFF17211D);
    const mutedColor = Color(0xFF4C5A54);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _KametiListFilter.values) ...[
            ChoiceChip(
              label: Text(
                filter.label,
                style: TextStyle(
                  color: selected == filter
                      ? Colors.white
                      : filter == _KametiListFilter.all
                          ? textColor
                          : mutedColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              selected: selected == filter,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: selected == filter
                    ? theme.colorScheme.primary
                    : const Color(0xFFD7E3DD),
              ),
              onSelected: (_) => onChanged(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.filter});

  final _KametiListFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _KametiListFilter.joined =>
        'No joined kametis yet. Ask an organizer to add your KametiBook username.',
      _KametiListFilter.organized => 'No kametis organized by you yet.',
      _KametiListFilter.active => 'No active kametis yet.',
      _KametiListFilter.draft => 'No draft kametis yet.',
      _KametiListFilter.all => 'No kametis yet.',
    };
    return EmptyState(icon: Icons.groups_2_outlined, title: message);
  }
}
