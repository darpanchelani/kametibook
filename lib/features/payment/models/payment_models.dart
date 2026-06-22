enum PaymentCycleStatus {
  upcoming('Upcoming'),
  current('Current'),
  completed('Completed'),
  overdue('Overdue');

  const PaymentCycleStatus(this.label);
  final String label;
}

enum PaymentStatus {
  pending('Pending'),
  proofSubmitted('Proof Submitted'),
  pendingApproval('Pending Approval'),
  paid('Paid'),
  late('Late'),
  rejected('Rejected'),
  waived('Waived');

  const PaymentStatus(this.label);
  final String label;
}

enum PaymentMethod {
  cash('Cash'),
  bankTransfer('Bank Transfer'),
  easypaisa('Easypaisa'),
  jazzcash('JazzCash'),
  sadapay('SadaPay'),
  nayapay('NayaPay'),
  other('Other');

  const PaymentMethod(this.label);
  final String label;
}

class PaymentCycleModel {
  const PaymentCycleModel({
    required this.id,
    required this.kametiId,
    required this.cycleNumber,
    required this.monthLabel,
    required this.dueDate,
    required this.expectedAmount,
    required this.collectedAmount,
    required this.pendingAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kametiId;
  final int cycleNumber;
  final String monthLabel;
  final DateTime dueDate;
  final double expectedAmount;
  final double collectedAmount;
  final double pendingAmount;
  final PaymentCycleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentCycleModel copyWith({
    String? id,
    String? kametiId,
    int? cycleNumber,
    String? monthLabel,
    DateTime? dueDate,
    double? expectedAmount,
    double? collectedAmount,
    double? pendingAmount,
    PaymentCycleStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentCycleModel(
      id: id ?? this.id,
      kametiId: kametiId ?? this.kametiId,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      monthLabel: monthLabel ?? this.monthLabel,
      dueDate: dueDate ?? this.dueDate,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MemberPaymentModel {
  const MemberPaymentModel({
    required this.id,
    required this.kametiId,
    required this.cycleId,
    required this.memberId,
    required this.amountDue,
    required this.amountPaid,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.proofImagePath,
    required this.note,
    required this.paidAt,
    required this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
    this.submittedBy = '',
    this.submittedAt,
    this.approvedAt,
    this.rejectedBy = '',
    this.rejectedAt,
    this.rejectionReason = '',
    this.proofUrl = '',
  });

  final String id;
  final String kametiId;
  final String cycleId;
  final String memberId;
  final double amountDue;
  final double amountPaid;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final String proofImagePath;
  final String note;
  final DateTime? paidAt;
  final String approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String submittedBy;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final String rejectedBy;
  final DateTime? rejectedAt;
  final String rejectionReason;
  final String proofUrl;

  bool get countsAsPaid => paymentStatus == PaymentStatus.paid || paymentStatus == PaymentStatus.waived;

  MemberPaymentModel copyWith({
    String? id,
    String? kametiId,
    String? cycleId,
    String? memberId,
    double? amountDue,
    double? amountPaid,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    bool clearPaymentMethod = false,
    String? proofImagePath,
    String? note,
    DateTime? paidAt,
    bool clearPaidAt = false,
    String? approvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? submittedBy,
    DateTime? submittedAt,
    DateTime? approvedAt,
    String? rejectedBy,
    DateTime? rejectedAt,
    String? rejectionReason,
    String? proofUrl,
  }) {
    return MemberPaymentModel(
      id: id ?? this.id,
      kametiId: kametiId ?? this.kametiId,
      cycleId: cycleId ?? this.cycleId,
      memberId: memberId ?? this.memberId,
      amountDue: amountDue ?? this.amountDue,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: clearPaymentMethod ? null : paymentMethod ?? this.paymentMethod,
      proofImagePath: proofImagePath ?? this.proofImagePath,
      note: note ?? this.note,
      paidAt: clearPaidAt ? null : paidAt ?? this.paidAt,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      proofUrl: proofUrl ?? this.proofUrl,
    );
  }
}
