import '../../member/models/member_model.dart';

enum KametiInviteStatus {
  pending('Pending'),
  accepted('Accepted'),
  rejected('Rejected'),
  expired('Expired'),
  cancelled('Cancelled');

  const KametiInviteStatus(this.label);
  final String label;
}

class KametiInviteModel {
  const KametiInviteModel({
    required this.id,
    required this.kametiId,
    required this.invitedPhone,
    required this.invitedUserId,
    required this.inviteCode,
    required this.role,
    required this.status,
    required this.invitedBy,
    required this.expiresAt,
    required this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kametiId;
  final String invitedPhone;
  final String invitedUserId;
  final String inviteCode;
  final MemberRole role;
  final KametiInviteStatus status;
  final String invitedBy;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  KametiInviteModel copyWith({
    String? invitedUserId,
    KametiInviteStatus? status,
    DateTime? acceptedAt,
    DateTime? updatedAt,
  }) {
    return KametiInviteModel(
      id: id,
      kametiId: kametiId,
      invitedPhone: invitedPhone,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      inviteCode: inviteCode,
      role: role,
      status: status ?? this.status,
      invitedBy: invitedBy,
      expiresAt: expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'kametiId': kametiId,
      'invitedPhone': invitedPhone,
      'invitedUserId': invitedUserId,
      'inviteCode': inviteCode,
      'role': role.name,
      'status': status.name,
      'invitedBy': invitedBy,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'acceptedAt': acceptedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}
