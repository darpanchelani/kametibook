class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.city,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String city;
  final DateTime createdAt;
}
