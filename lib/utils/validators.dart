class Validators {
  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.isEmpty) return "Please enter email or phone";
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Please enter password";
    if (value.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return "Please enter your name";
    // Check if first letter of first word is capitalized
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      final firstChar = trimmed[0];
      // Check if first character is a letter
      if (firstChar.contains(RegExp(r'[a-zA-Z]'))) {
        // If it's a letter, it must be uppercase
        if (firstChar != firstChar.toUpperCase()) {
          return "Name must start with a capital letter";
        }
      }
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Please enter your email";

    // Basic email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return "Please enter a valid email";
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Please enter your phone number";

    // Remove spaces, dashes, and parentheses for validation
    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if phone contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleanedPhone)) {
      return "Phone number must contain only digits";
    }

    // Check minimum length (at least 10 digits)
    if (cleanedPhone.length < 10) {
      return "Phone number must be at least 10 digits";
    }

    return null;
  }
}
