class Validators {
  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 13) return 'Enter a valid phone number';
    return null;
  }

  static String? optionalCnic(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 13) return 'CNIC must be 13 digits';
    return null;
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final email = value.trim();
    if (!email.contains('@') || !email.contains('.')) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? positiveNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final number = num.tryParse(value.replaceAll(',', '').trim());
    if (number == null || number <= 0) return '$label must be greater than 0';
    return null;
  }

  static String? members(String? value) {
    if (value == null || value.trim().isEmpty) return 'Total members is required';
    final number = int.tryParse(value.trim());
    if (number == null || number <= 1) return 'Members must be greater than 1';
    return null;
  }
}
