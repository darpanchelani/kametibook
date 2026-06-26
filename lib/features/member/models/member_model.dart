enum MemberStatus {
  pending('Pending'),
  active('Active'),
  removed('Removed'),
  blocked('Blocked');

  const MemberStatus(this.label);
  final String label;
}

enum MemberRole {
  organizer('Organizer'),
  coOrganizer('Co-Organizer'),
  member('Member');

  const MemberRole(this.label);
  final String label;
}

enum MemberInviteStatus {
  none('None'),
  pending('Pending'),
  accepted('Accepted'),
  rejected('Rejected'),
  expired('Expired'),
  cancelled('Cancelled');

  const MemberInviteStatus(this.label);
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
    this.profilePhotoUrl = '',
    required this.role,
    required this.status,
    required this.hasReceivedKameti,
    required this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
    this.receivedCycleId = '',
    this.receivedCycleNumber,
    this.receivedAt,
    this.receivedAmount = 0,
    this.receivedVia = '',
    this.userId = '',
    this.invitedBy = '',
    this.inviteStatus = MemberInviteStatus.none,
    this.joinedByApp = false,
    this.linkedAt,
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
  final String profilePhotoUrl;
  final MemberRole role;
  final MemberStatus status;
  final bool hasReceivedKameti;
  final DateTime joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String receivedCycleId;
  final int? receivedCycleNumber;
  final DateTime? receivedAt;
  final double receivedAmount;
  final String receivedVia;
  final String userId;
  final String invitedBy;
  final MemberInviteStatus inviteStatus;
  final bool joinedByApp;
  final DateTime? linkedAt;

  bool get isOrganizer => role == MemberRole.organizer;
  bool get canManageGroup =>
      role == MemberRole.organizer || role == MemberRole.coOrganizer;
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
    String? profilePhotoUrl,
    MemberRole? role,
    MemberStatus? status,
    bool? hasReceivedKameti,
    DateTime? joinedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? receivedCycleId,
    int? receivedCycleNumber,
    DateTime? receivedAt,
    double? receivedAmount,
    String? receivedVia,
    String? userId,
    String? invitedBy,
    MemberInviteStatus? inviteStatus,
    bool? joinedByApp,
    DateTime? linkedAt,
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
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      hasReceivedKameti: hasReceivedKameti ?? this.hasReceivedKameti,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receivedCycleId: receivedCycleId ?? this.receivedCycleId,
      receivedCycleNumber: receivedCycleNumber ?? this.receivedCycleNumber,
      receivedAt: receivedAt ?? this.receivedAt,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      receivedVia: receivedVia ?? this.receivedVia,
      userId: userId ?? this.userId,
      invitedBy: invitedBy ?? this.invitedBy,
      inviteStatus: inviteStatus ?? this.inviteStatus,
      joinedByApp: joinedByApp ?? this.joinedByApp,
      linkedAt: linkedAt ?? this.linkedAt,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'id': id,
      'kametiId': kametiId,
      'fullName': fullName,
      'phone': phone,
      'city': city,
      'cnic': cnic,
      'whatsappNumber': whatsappNumber,
      'email': email,
      'notes': notes,
      'profilePhotoUrl': profilePhotoUrl,
      'role': role.name,
      'status': status.name,
      'hasReceivedKameti': hasReceivedKameti,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'receivedCycleId': receivedCycleId,
      'receivedCycleNumber': receivedCycleNumber,
      'receivedAt': receivedAt?.millisecondsSinceEpoch,
      'receivedAmount': receivedAmount,
      'receivedVia': receivedVia,
      'userId': userId,
      'invitedBy': invitedBy,
      'inviteStatus': inviteStatus.name,
      'joinedByApp': joinedByApp,
      'linkedAt': linkedAt?.millisecondsSinceEpoch,
    };
  }

  factory MemberModel.fromFirestore(Map<String, Object?> data) {
    return MemberModel(
      id: _stringValue(data['id']),
      kametiId: _stringValue(data['kametiId']),
      fullName: _stringValue(data['fullName']),
      phone: _stringValue(data['phone']),
      city: _stringValue(data['city']),
      cnic: _stringValue(data['cnic']),
      whatsappNumber: _stringValue(data['whatsappNumber']),
      email: _stringValue(data['email']),
      notes: _stringValue(data['notes']),
      profilePhotoUrl: _stringValue(data['profilePhotoUrl']),
      role: _enumValue(MemberRole.values, data['role'], MemberRole.member),
      status:
          _enumValue(MemberStatus.values, data['status'], MemberStatus.active),
      hasReceivedKameti: _boolValue(data['hasReceivedKameti']),
      joinedAt: _dateValue(data['joinedAt']),
      createdAt: _dateValue(data['createdAt']),
      updatedAt: _dateValue(data['updatedAt']),
      receivedCycleId: _stringValue(data['receivedCycleId']),
      receivedCycleNumber: data['receivedCycleNumber'] == null
          ? null
          : _intValue(data['receivedCycleNumber']),
      receivedAt:
          data['receivedAt'] == null ? null : _dateValue(data['receivedAt']),
      receivedAmount: _doubleValue(data['receivedAmount']),
      receivedVia: _stringValue(data['receivedVia']),
      userId: _stringValue(data['userId']),
      invitedBy: _stringValue(data['invitedBy']),
      inviteStatus: _enumValue(
        MemberInviteStatus.values,
        data['inviteStatus'],
        MemberInviteStatus.none,
      ),
      joinedByApp: _boolValue(data['joinedByApp']),
      linkedAt: data['linkedAt'] == null ? null : _dateValue(data['linkedAt']),
    );
  }
}

String _stringValue(Object? value) => value == null ? '' : '$value';

bool _boolValue(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  return fallback;
}

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime _dateValue(Object? value) {
  if (value is DateTime) return value;
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

T _enumValue<T extends Enum>(List<T> values, Object? value, T fallback) {
  final name = value?.toString();
  if (name == null || name.isEmpty) return fallback;
  for (final item in values) {
    if (item.name == name) return item;
  }
  return fallback;
}
