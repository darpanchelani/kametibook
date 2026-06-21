enum MemberStatus {
  pending('Pending'),
  active('Active'),
  removed('Removed');

  const MemberStatus(this.label);
  final String label;
}

enum MemberRole {
  organizer('Organizer'),
  member('Member');

  const MemberRole(this.label);
  final String label;
}

class MemberModel {
  const MemberModel({
    required this.id,
    required this.kametiId,
    required this.fullName,
    required this.phone,
    required this.city,
    required this.cnic,
    required this.whatsappNumber,
    required this.email,
    required this.notes,
    required this.role,
    required this.status,
    required this.hasReceivedKameti,
    required this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kametiId;
  final String fullName;
  final String phone;
  final String city;
  final String cnic;
  final String whatsappNumber;
  final String email;
  final String notes;
  final MemberRole role;
  final MemberStatus status;
  final bool hasReceivedKameti;
  final DateTime joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOrganizer => role == MemberRole.organizer;
  bool get isActiveForCount => status == MemberStatus.active;

  MemberModel copyWith({
    String? id,
    String? kametiId,
    String? fullName,
    String? phone,
    String? city,
    String? cnic,
    String? whatsappNumber,
    String? email,
    String? notes,
    MemberRole? role,
    MemberStatus? status,
    bool? hasReceivedKameti,
    DateTime? joinedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberModel(
      id: id ?? this.id,
      kametiId: kametiId ?? this.kametiId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      cnic: cnic ?? this.cnic,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      role: role ?? this.role,
      status: status ?? this.status,
      hasReceivedKameti: hasReceivedKameti ?? this.hasReceivedKameti,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
