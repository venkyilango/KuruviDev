class Validators {
  Validators._(); // Prevent instantiation

  /// 🔹 Email Validation
  static bool isValidEmail(String value) {
    final emailRegex =
    RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(value.trim());
  }

  /// 🔹 Username Validation
  /// - Max 13 characters
  /// - Only letters and numbers
  static bool validUsername(String value) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9]{1,13}$');
    return usernameRegex.hasMatch(value.trim());
  }

  /// 🔹 Password Validation
  /// Rules:
  /// - Min 8, Max 12 characters
  /// - At least 1 uppercase letter
  /// - At least 1 number
  /// - At least 1 special symbol
  static bool validPassword(String value) {
    final passwordRegex =
    RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,12}$');
    return passwordRegex.hasMatch(value);
  }

  /// 🔹 Contact Number Validation
  /// - Exactly 10 digits
  static bool validContact(String value) {
    final contactRegex = RegExp(r'^[0-9]{10}$');
    return contactRegex.hasMatch(value.trim());
  }

  /// 🔹 Required Field Validation (Form Validator)
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// 🔹 Email Field Validator (Form)
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// 🔹 Username Field Validator (Form)
  static String? usernameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (!validUsername(value)) {
      return 'Only letters & numbers (max 13 characters)';
    }
    return null;
  }

  /// 🔹 Password Field Validator (Form)
  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!validPassword(value)) {
      return '8–12 chars, 1 uppercase, 1 number & 1 symbol';
    }
    return null;
  }

  /// 🔹 Contact Field Validator (Form)
  static String? contactValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contact number is required';
    }
    if (!validContact(value)) {
      return 'Enter a valid 10-digit contact number';
    }
    return null;
  }
}
