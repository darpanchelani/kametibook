class Validators {
  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (value.trim().length < 10) return 'Enter a valid phone number';
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
