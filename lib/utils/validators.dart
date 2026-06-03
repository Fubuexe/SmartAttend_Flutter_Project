class Validators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'At least 6 characters';
    return null;
  }

  static String? notEmpty(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }
}
