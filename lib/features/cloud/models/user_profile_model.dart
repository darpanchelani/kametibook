enum UserProfileStatus {
  active('Active'),
  blocked('Blocked'),
  deleted('Deleted');

  const UserProfileStatus(this.label);
  final String label;
}

enum GlobalUserRole {
  user('User'),
  platformAdmin('Platform Admin');

  const GlobalUserRole(this.label);
  final String label;
}

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.profilePhotoUrl,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
    required this.fcmToken,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String city;
  final String profilePhotoUrl;
  final GlobalUserRole role;
  final UserProfileStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final String fcmToken;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'city': city,
      'profilePhotoUrl': profilePhotoUrl,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'fcmToken': fcmToken,
    };
  }

  factory UserProfileModel.fromMap(Map<String, Object?> map) {
    return UserProfileModel(
      id: '${map['id'] ?? ''}',
      fullName: '${map['fullName'] ?? ''}',
      phone: '${map['phone'] ?? ''}',
      email: '${map['email'] ?? ''}',
      city: '${map['city'] ?? ''}',
      profilePhotoUrl: '${map['profilePhotoUrl'] ?? ''}',
      role: GlobalUserRole.values.firstWhere((item) => item.name == map['role'], orElse: () => GlobalUserRole.user),
      status: UserProfileStatus.values.firstWhere((item) => item.name == map['status'], orElse: () => UserProfileStatus.active),
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      updatedAt: _date(map['updatedAt']) ?? DateTime.now(),
      lastLoginAt: _date(map['lastLoginAt']),
      fcmToken: '${map['fcmToken'] ?? ''}',
    );
  }

  static DateTime? _date(Object? value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
