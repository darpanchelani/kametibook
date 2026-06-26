enum ReportType {
  monthlyCycle('Monthly Cycle'),
  fullKameti('Full Kameti'),
  memberStatement('Member Statement'),
  payment('Payment'),
  payout('Payout / Receiver'),
  ledger('Ledger'),
  bidding('Bidding'),
  luckyDraw('Lucky Draw');

  const ReportType(this.label);
  final String label;
}

enum ReportStatus {
  generated('Generated'),
  exported('Exported'),
  shared('Shared'),
  failed('Failed');

  const ReportStatus(this.label);
  final String label;
}

enum ReportVisibility {
  privateOrganizerOnly('Private'),
  sharedWithMembers('Shared with members');

  const ReportVisibility(this.label);
  final String label;
}

class ReportModel {
  const ReportModel({
    required this.id,
    required this.kametiId,
    required this.reportType,
    required this.title,
    required this.generatedAt,
    required this.generatedBy,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.cycleId,
    required this.memberId,
    required this.filePath,
    required this.status,
    required this.summary,
    required this.createdAt,
    this.visibility = ReportVisibility.privateOrganizerOnly,
    this.sharedWithMemberIds = const [],
  });

  final String id;
  final String kametiId;
  final ReportType reportType;
  final String title;
  final DateTime generatedAt;
  final String generatedBy;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final String cycleId;
  final String memberId;
  final String filePath;
  final ReportStatus status;
  final String summary;
  final DateTime createdAt;
  final ReportVisibility visibility;
  final List<String> sharedWithMemberIds;

  ReportModel copyWith(
      {String? filePath,
      ReportStatus? status,
      ReportVisibility? visibility,
      List<String>? sharedWithMemberIds}) {
    return ReportModel(
      id: id,
      kametiId: kametiId,
      reportType: reportType,
      title: title,
      generatedAt: generatedAt,
      generatedBy: generatedBy,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
      cycleId: cycleId,
      memberId: memberId,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      summary: summary,
      createdAt: createdAt,
      visibility: visibility ?? this.visibility,
      sharedWithMemberIds: sharedWithMemberIds ?? this.sharedWithMemberIds,
    );
  }
}

class ReportSection {
  const ReportSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<List<String>> rows;
}

class ReportData {
  const ReportData({
    required this.model,
    required this.kametiName,
    required this.summaryCards,
    required this.sections,
    required this.warnings,
    required this.shareSummary,
  });

  final ReportModel model;
  final String kametiName;
  final Map<String, String> summaryCards;
  final List<ReportSection> sections;
  final List<String> warnings;
  final String shareSummary;

  ReportData copyWith({ReportModel? model}) {
    return ReportData(
      model: model ?? this.model,
      kametiName: kametiName,
      summaryCards: summaryCards,
      sections: sections,
      warnings: warnings,
      shareSummary: shareSummary,
    );
  }
}
