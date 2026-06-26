import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../bidding/models/bidding_models.dart';
import '../../kameti/models/kameti_model.dart';
import '../../ledger/models/ledger_entry_model.dart';
import '../../member/models/member_model.dart';
import '../../payment/models/payment_models.dart';
import '../../receiver/models/receiver_allocation_model.dart';
import '../models/report_model.dart';

class ReportController extends StateNotifier<List<ReportModel>> {
  ReportController() : super(const []);

  List<ReportModel> getReportsByKametiId(String kametiId) {
    final reports =
        state.where((report) => report.kametiId == kametiId).toList();
    reports.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return reports;
  }

  void saveReportHistory(ReportModel reportModel) {
    state = [reportModel, ...state.where((item) => item.id != reportModel.id)];
  }

  void updateReportFile(String reportId, String filePath, ReportStatus status) {
    state = [
      for (final report in state)
        if (report.id == reportId)
          report.copyWith(filePath: filePath, status: status)
        else
          report,
    ];
  }

  void deleteReportHistory(String reportId) {
    state = state.where((report) => report.id != reportId).toList();
  }

  ReportData buildReportData({
    required ReportType type,
    required KametiModel kameti,
    required String generatedBy,
    List<MemberModel> members = const [],
    List<PaymentCycleModel> cycles = const [],
    List<MemberPaymentModel> payments = const [],
    List<ReceiverAllocationModel> allocations = const [],
    List<LedgerEntryModel> ledgerEntries = const [],
    List<BiddingSessionModel> biddingSessions = const [],
    List<BidModel> bids = const [],
    List<DiscountAdjustmentModel> discountAdjustments = const [],
    List<dynamic> draws = const [],
    PaymentCycleModel? selectedCycle,
    MemberModel? selectedMember,
    bool includeCnic = false,
  }) {
    final now = DateTime.now();
    final title = _titleFor(type, selectedCycle, selectedMember);
    final model = ReportModel(
      id: 'report-${now.microsecondsSinceEpoch}',
      kametiId: kameti.id,
      reportType: type,
      title: title,
      generatedAt: now,
      generatedBy: generatedBy,
      dateRangeStart: null,
      dateRangeEnd: null,
      cycleId: selectedCycle?.id ?? '',
      memberId: selectedMember?.id ?? '',
      filePath: '',
      status: ReportStatus.generated,
      summary: _summaryText(kameti, selectedCycle, ledgerEntries),
      createdAt: now,
    );

    final relevantPayments = selectedCycle == null
        ? payments
        : payments.where((p) => p.cycleId == selectedCycle.id).toList();
    final relevantLedger = selectedCycle == null
        ? ledgerEntries
        : ledgerEntries.where((e) => e.cycleId == selectedCycle.id).toList();
    final summaryCards = <String, String>{
      'Members': '${members.length}',
      'Cycles': '${cycles.length}',
      'Collected': CurrencyFormatter.pkr(
          _sumLedger(ledgerEntries, LedgerEntryType.contribution)),
      'Payouts': CurrencyFormatter.pkr(
          _sumLedger(ledgerEntries, LedgerEntryType.payout)),
      'Balance': CurrencyFormatter.pkr(_balance(ledgerEntries)),
    };

    final sections = <ReportSection>[
      ReportSection(title: 'Kameti Information', rows: [
        ['Name', kameti.name],
        ['Type', kameti.type.label],
        ['Status', kameti.status.label],
        ['Organizer', kameti.organizerName],
        ['Monthly Contribution', CurrencyFormatter.pkr(kameti.monthlyAmount)],
        ['Total Pool', CurrencyFormatter.pkr(kameti.totalPoolAmount)],
      ]),
    ];

    if (type == ReportType.monthlyCycle && selectedCycle != null) {
      sections.addAll([
        ReportSection(title: 'Cycle Summary', rows: [
          [
            'Cycle',
            'Month ${selectedCycle.cycleNumber} - ${selectedCycle.monthLabel}'
          ],
          ['Due Date', DateFormatter.display(selectedCycle.dueDate)],
          ['Expected', CurrencyFormatter.pkr(selectedCycle.expectedAmount)],
          ['Collected', CurrencyFormatter.pkr(selectedCycle.collectedAmount)],
          ['Pending', CurrencyFormatter.pkr(selectedCycle.pendingAmount)],
        ]),
        _paymentsSection(relevantPayments, members),
        _allocationsSection(
            allocations.where((a) => a.cycleId == selectedCycle.id).toList()),
        _ledgerSection(relevantLedger, members),
      ]);
    } else if (type == ReportType.memberStatement && selectedMember != null) {
      final memberPayments =
          payments.where((p) => p.memberId == selectedMember.id).toList();
      sections.addAll([
        ReportSection(title: 'Member Details', rows: [
          ['Name', selectedMember.fullName],
          ['Phone', selectedMember.phone],
          ['City', selectedMember.city],
          ['Role', selectedMember.role.label],
          ['Status', selectedMember.status.label],
          ['Has Received', selectedMember.hasReceivedKameti ? 'Yes' : 'No'],
          if (includeCnic && selectedMember.cnic.isNotEmpty)
            ['CNIC', selectedMember.cnic],
        ]),
        _paymentsSection(memberPayments, members),
        _allocationsSection(
            allocations.where((a) => a.memberId == selectedMember.id).toList()),
        _ledgerSection(
            ledgerEntries
                .where((e) => e.memberId == selectedMember.id)
                .toList(),
            members),
      ]);
    } else {
      sections.addAll([
        _membersSection(members, includeCnic),
        _cyclesSection(cycles, allocations, ledgerEntries),
        if (type == ReportType.payment || type == ReportType.fullKameti)
          _paymentsSection(payments, members),
        if (type == ReportType.payout || type == ReportType.fullKameti)
          _allocationsSection(allocations),
        if (type == ReportType.ledger || type == ReportType.fullKameti)
          _ledgerSection(ledgerEntries, members),
        if (type == ReportType.bidding)
          _biddingSection(biddingSessions, bids, discountAdjustments),
        if (type == ReportType.luckyDraw) _drawSection(draws),
      ]);
    }

    final warnings = getReportWarnings(
      payments: payments,
      allocations: allocations,
      ledgerEntries: ledgerEntries,
      type: type,
    );

    return ReportData(
      model: model,
      kametiName: kameti.name,
      summaryCards: summaryCards,
      sections: sections,
      warnings: warnings,
      shareSummary:
          '${model.title}\n${kameti.name}\nCollected: ${summaryCards['Collected']}\nPayouts: ${summaryCards['Payouts']}\nBalance: ${summaryCards['Balance']}',
    );
  }

  List<String> getReportWarnings({
    required List<MemberPaymentModel> payments,
    required List<ReceiverAllocationModel> allocations,
    required List<LedgerEntryModel> ledgerEntries,
    required ReportType type,
  }) {
    final warnings = <String>[];
    final pendingPayments = payments
        .where((payment) =>
            payment.paymentStatus != PaymentStatus.paid &&
            payment.paymentStatus != PaymentStatus.waived)
        .length;
    final missingProofs = allocations
        .where((allocation) => allocation.payoutProofPath.isEmpty)
        .length;
    final corrections = ledgerEntries
        .where((entry) => entry.entryType == LedgerEntryType.correction)
        .length;
    if (pendingPayments > 0) {
      warnings.add('$pendingPayments payments are still pending.');
    }
    if (missingProofs > 0) {
      warnings.add(
          'Payout proof is missing for $missingProofs receiver allocation(s).');
    }
    if (corrections > 0) warnings.add('Ledger has manual correction entries.');
    return warnings;
  }

  String _titleFor(
      ReportType type, PaymentCycleModel? cycle, MemberModel? member) {
    return switch (type) {
      ReportType.monthlyCycle =>
        'Monthly Cycle Report${cycle == null ? '' : ' - Month ${cycle.cycleNumber}'}',
      ReportType.fullKameti => 'Full Kameti Report',
      ReportType.memberStatement =>
        'Member Statement${member == null ? '' : ' - ${member.fullName}'}',
      ReportType.payment => 'Payment Report',
      ReportType.payout => 'Payout / Receiver Report',
      ReportType.ledger => 'Ledger Report',
      ReportType.bidding => 'Bidding Report',
      ReportType.luckyDraw => 'Lucky Draw Report',
    };
  }

  String _summaryText(KametiModel kameti, PaymentCycleModel? cycle,
      List<LedgerEntryModel> ledgerEntries) {
    return '${kameti.name}${cycle == null ? '' : ' - Month ${cycle.cycleNumber}'} | Balance: ${CurrencyFormatter.pkr(_balance(ledgerEntries))}';
  }

  ReportSection _membersSection(List<MemberModel> members, bool includeCnic) {
    return ReportSection(title: 'Members', rows: [
      [
        'Name',
        'Phone',
        'City',
        'Role',
        'Status',
        'Received',
        if (includeCnic) 'CNIC'
      ],
      for (final member in members)
        [
          member.fullName,
          member.phone,
          member.city,
          member.role.label,
          member.status.label,
          member.hasReceivedKameti ? 'Yes' : 'No',
          if (includeCnic) member.cnic,
        ],
    ]);
  }

  ReportSection _cyclesSection(
      List<PaymentCycleModel> cycles,
      List<ReceiverAllocationModel> allocations,
      List<LedgerEntryModel> ledgerEntries) {
    return ReportSection(title: 'Cycle-wise Summary', rows: [
      [
        'Cycle',
        'Month',
        'Expected',
        'Collected',
        'Pending',
        'Receiver',
        'Balance'
      ],
      for (final cycle in cycles)
        [
          '${cycle.cycleNumber}',
          cycle.monthLabel,
          CurrencyFormatter.pkr(cycle.expectedAmount),
          CurrencyFormatter.pkr(cycle.collectedAmount),
          CurrencyFormatter.pkr(cycle.pendingAmount),
          _allocationForCycle(allocations, cycle.id)?.memberName ?? '-',
          CurrencyFormatter.pkr(_balance(
              ledgerEntries.where((e) => e.cycleId == cycle.id).toList())),
        ],
    ]);
  }

  ReportSection _paymentsSection(
      List<MemberPaymentModel> payments, List<MemberModel> members) {
    return ReportSection(title: 'Payments', rows: [
      ['Cycle', 'Member', 'Phone', 'Due', 'Paid', 'Status', 'Method', 'Proof'],
      for (final payment in payments)
        [
          payment.cycleId.split('-cycle-').last.split('-').first,
          _memberById(members, payment.memberId)?.fullName ?? '-',
          _memberById(members, payment.memberId)?.phone ?? '-',
          CurrencyFormatter.pkr(payment.amountDue),
          CurrencyFormatter.pkr(payment.amountPaid),
          payment.paymentStatus.label,
          payment.paymentMethod?.label ?? '-',
          payment.proofImagePath.isEmpty ? 'No proof' : 'Proof attached',
        ],
    ]);
  }

  ReportSection _allocationsSection(List<ReceiverAllocationModel> allocations) {
    return ReportSection(title: 'Receiver / Payouts', rows: [
      ['Cycle', 'Receiver', 'Type', 'Amount', 'Payout', 'Proof'],
      for (final allocation in allocations)
        [
          '${allocation.cycleNumber}',
          allocation.memberName,
          allocation.allocationType.label,
          CurrencyFormatter.pkr(allocation.amount),
          allocation.payoutStatus.label,
          allocation.payoutProofPath.isEmpty ? 'No proof' : 'Proof attached',
        ],
    ]);
  }

  ReportSection _ledgerSection(
      List<LedgerEntryModel> entries, List<MemberModel> members) {
    return ReportSection(title: 'Ledger Entries', rows: [
      ['Date', 'Type', 'Member', 'Direction', 'Amount', 'Status'],
      for (final entry in entries)
        [
          DateFormatter.display(entry.entryDate),
          entry.entryType.label,
          _memberById(members, entry.memberId)?.fullName ?? '-',
          entry.direction.label,
          CurrencyFormatter.pkr(entry.amount),
          entry.status.label,
        ],
    ]);
  }

  ReportSection _biddingSection(List<BiddingSessionModel> sessions,
      List<BidModel> bids, List<DiscountAdjustmentModel> adjustments) {
    return ReportSection(title: 'Bidding Summary', rows: [
      ['Cycle', 'Status', 'Winner', 'Winning', 'Pool', 'Discount'],
      for (final session in sessions)
        [
          '${session.cycleNumber}',
          session.status.label,
          session.winnerMemberId.isEmpty ? '-' : session.winnerMemberId,
          CurrencyFormatter.pkr(session.winningAmount),
          CurrencyFormatter.pkr(session.totalPoolAmount),
          CurrencyFormatter.pkr(session.discountAmount),
        ],
      [
        'Total bids',
        '${bids.length}',
        'Adjustments',
        '${adjustments.length}',
        '',
        ''
      ],
    ]);
  }

  ReportSection _drawSection(List<dynamic> draws) {
    return ReportSection(title: 'Lucky Draw Summary', rows: [
      ['Cycle', 'Winner', 'Amount', 'Date', 'Eligible', 'Excluded'],
      for (final draw in draws)
        [
          '${draw.cycleNumber}',
          '${draw.winnerName}',
          CurrencyFormatter.pkr(draw.payoutAmount),
          DateFormatter.display(draw.drawDate),
          '${draw.totalEligibleMembers}',
          '${draw.totalExcludedMembers}',
        ],
    ]);
  }

  ReceiverAllocationModel? _allocationForCycle(
      List<ReceiverAllocationModel> allocations, String cycleId) {
    for (final allocation in allocations) {
      if (allocation.cycleId == cycleId) return allocation;
    }
    return null;
  }

  MemberModel? _memberById(List<MemberModel> members, String memberId) {
    for (final member in members) {
      if (member.id == memberId) return member;
    }
    return null;
  }

  double _sumLedger(List<LedgerEntryModel> entries, LedgerEntryType type) {
    return entries
        .where((entry) =>
            entry.entryType == type && entry.status == LedgerStatus.confirmed)
        .fold<double>(0, (total, entry) => total + entry.amount);
  }

  double _balance(List<LedgerEntryModel> entries) {
    final confirmed =
        entries.where((entry) => entry.status == LedgerStatus.confirmed);
    final moneyIn = confirmed
        .where((entry) => entry.direction == LedgerDirection.moneyIn)
        .fold<double>(0, (total, entry) => total + entry.amount);
    final moneyOut = confirmed
        .where((entry) => entry.direction == LedgerDirection.moneyOut)
        .fold<double>(0, (total, entry) => total + entry.amount);
    return moneyIn - moneyOut;
  }
}

final reportControllerProvider =
    StateNotifierProvider<ReportController, List<ReportModel>>(
        (ref) => ReportController());
